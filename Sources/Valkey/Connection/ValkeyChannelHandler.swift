//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey project
//
// Copyright (c) 2025 the swift-valkey authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See swift-valkey/CONTRIBUTORS.txt for the list of swift-valkey authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import DequeModule
import Logging
import NIOCore

@usableFromInline
enum ValkeyPromise<T: Sendable>: Sendable {
    case nio(EventLoopPromise<T>)
    case swift(CheckedContinuation<T, any Error>)

    func succeed(_ t: T) {
        switch self {
        case .nio(let eventLoopPromise):
            eventLoopPromise.succeed(t)
        case .swift(let checkedContinuation):
            checkedContinuation.resume(returning: t)
        }
    }

    func fail(_ e: Error) {
        switch self {
        case .nio(let eventLoopPromise):
            eventLoopPromise.fail(e)
        case .swift(let checkedContinuation):
            checkedContinuation.resume(throwing: e)
        }
    }
}

@usableFromInline
enum ValkeyRequest: Sendable {
    case single(buffer: ByteBuffer, promise: ValkeyPromise<RESPToken>)
    case multiple(buffer: ByteBuffer, promises: [ValkeyPromise<RESPToken>])
}

@usableFromInline
final class ValkeyChannelHandler: ChannelInboundHandler {
    @usableFromInline
    typealias OutboundOut = ByteBuffer
    @usableFromInline
    typealias InboundIn = ByteBuffer

    static let simpleOk = RESPToken(validated: ByteBuffer(string: "+OK\r\n"))
    @usableFromInline
    /*private*/ let eventLoop: EventLoop
    @usableFromInline
    /*private*/ var commands: Deque<ValkeyPromise<RESPToken>>
    @usableFromInline
    /*private*/ var encoder = RESPCommandEncoder()
    @usableFromInline
    /*private*/ var context: ChannelHandlerContext?
    @usableFromInline
    /*private*/ var subscriptions: ValkeySubscriptions

    private var decoder: NIOSingleStepByteToMessageProcessor<RESPTokenDecoder>
    private let logger: Logger
    private var isClosed = false

    init(eventLoop: EventLoop, logger: Logger) {
        self.eventLoop = eventLoop
        self.commands = .init()
        self.subscriptions = .init(logger: logger)
        self.decoder = NIOSingleStepByteToMessageProcessor(RESPTokenDecoder())
        self.context = nil
        self.logger = logger
    }

    /// Write valkey command/commands to channel
    /// - Parameters:
    ///   - request: Valkey command request
    ///   - promise: Promise to fulfill when command is complete
    @inlinable
    func write<Command: RESPCommand>(command: Command, continuation: CheckedContinuation<RESPToken, any Error>) {
        self.eventLoop.assertInEventLoop()
        guard let context = self.context else {
            preconditionFailure("Trying to use valkey connection before it is setup")
        }

        self.encoder.reset()
        command.encode(into: &self.encoder)
        let buffer = self.encoder.buffer

        self.commands.append(.swift(continuation))
        context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
    }

    @usableFromInline
    func write(request: ValkeyRequest) {
        self.eventLoop.assertInEventLoop()
        if self.isClosed {
            switch request {
            case .single(_, let promise):
                promise.fail(ValkeyClientError.init(.connectionClosed))
            case .multiple(_, let promises):
                for promise in promises {
                    promise.fail(ValkeyClientError.init(.connectionClosed))
                }
            }
            return
        }
        guard let context = self.context else {
            preconditionFailure("Trying to use valkey connection before it is setup")
        }
        switch request {
        case .single(let buffer, let tokenPromise):
            self.logger.trace(
                "Send command",
                metadata: ["command": "\((try? [String](from: RESPToken(validated: buffer))).map { $0.joined(separator: " ") } ?? "")"]
            )
            self.commands.append(tokenPromise)
            context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)

        case .multiple(let buffer, let tokenPromises):
            for tokenPromise in tokenPromises {
                self.commands.append(tokenPromise)
            }
            context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
        }
    }

    /// Add subscription, and call SUBSCRIBE command if required
    func subscribe(
        command: some RESPCommand,
        streamContinuation: ValkeySubscriptionSequence.Continuation,
        filters: [ValkeySubscriptionFilter],
        promise: ValkeyPromise<Int>
    ) {
        self.eventLoop.assertInEventLoop()
        switch self.subscriptions.addSubscription(continuation: streamContinuation, filters: filters) {
        case .subscribe(let subscription, _):
            // TODO: currently ignoring returned filter array, as we have already constructed the subscribe command
            //   But it would be cool to build the subscribe command based on what filters we aren't subscribed to
            self.subscriptions.pushCommand(filters: subscription.filters)
            let subscriptionID = subscription.id
            return self._send(command: command).assumeIsolated().whenComplete { result in
                switch result {
                case .success:
                    promise.succeed(subscriptionID)
                case .failure(let error):
                    self.subscriptions.removeSubscription(id: subscriptionID)
                    self.subscriptions.removeUnhandledCommand()
                    promise.fail(error)
                }
            }

        case .doNothing(let subscriptionID):
            promise.succeed(subscriptionID)
        }
    }

    /// Remove subscription and if required call UNSUBSCRIBE command
    func unsubscribe(
        id: Int,
        promise: ValkeyPromise<Void>
    ) {
        self.eventLoop.assertInEventLoop()
        switch self.subscriptions.unsubscribe(id: id) {
        case .unsubscribe(let channels):
            self.performUnsubscribe(
                command: UNSUBSCRIBE(channel: channels),
                filters: channels.map { .channel($0) },
                promise: promise
            )
        case .punsubscribe(let patterns):
            self.performUnsubscribe(
                command: PUNSUBSCRIBE(pattern: patterns),
                filters: patterns.map { .pattern($0) },
                promise: promise
            )
        case .sunsubscribe(let shardChannels):
            self.performUnsubscribe(
                command: SUNSUBSCRIBE(shardchannel: shardChannels),
                filters: shardChannels.map { .shardChannel($0) },
                promise: promise
            )
        case .doNothing:
            promise.succeed(())
        }
    }

    func performUnsubscribe(
        command: some RESPCommand,
        filters: [ValkeySubscriptionFilter],
        promise: ValkeyPromise<Void>
    ) {
        self.subscriptions.pushCommand(filters: filters)
        self._send(command: command).assumeIsolated().whenComplete { result in
            switch result {
            case .success:
                promise.succeed(())
            case .failure(let error):
                self.subscriptions.removeUnhandledCommand()
                promise.fail(error)
            }
        }
    }

    @usableFromInline
    func handlerAdded(context: ChannelHandlerContext) {
        self.context = context
    }

    @usableFromInline
    func handlerRemoved(context: ChannelHandlerContext) {
        self.context = nil
        while let promise = commands.popFirst() {
            promise.fail(ValkeyClientError.init(.connectionClosed))
        }
        self.subscriptions.close()
        self.isClosed = true
    }

    @usableFromInline
    func channelInactive(context: ChannelHandlerContext) {
        do {
            try self.decoder.finishProcessing(seenEOF: true) { token in
                self.handleToken(context: context, token: token)
            }
        } catch let error as RESPParsingError {
            self.handleError(context: context, error: error)
        } catch {
            preconditionFailure("Expected to only get RESPParsingError from the RESPTokenDecoder.")
        }
        while let promise = commands.popFirst() {
            promise.fail(ValkeyClientError.init(.connectionClosed))
        }
        self.subscriptions.close()
        self.isClosed = true
        self.logger.trace("Channel inactive.")
    }

    @usableFromInline
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let buffer = self.unwrapInboundIn(data)

        do {
            try self.decoder.process(buffer: buffer) { token in
                self.handleToken(context: context, token: token)
            }
        } catch let error as RESPParsingError {
            self.handleError(context: context, error: error)
        } catch {
            preconditionFailure("Expected to only get RESPParsingError from the RESPTokenDecoder.")
        }
    }

    func handleToken(context: ChannelHandlerContext, token: RESPToken) {
        switch token.identifier {
        case .simpleError, .bulkError:
            guard let promise = commands.popFirst() else {
                preconditionFailure("Unexpected response")
            }
            promise.fail(ValkeyClientError(.commandError, message: token.errorString.map { String(buffer: $0) }))

        case .push:
            // If subscription notify throws an error then assume something has gone wrong
            // and close the channel with the error
            do {
                if try self.subscriptions.notify(token) == true {
                    guard let promise = commands.popFirst() else {
                        preconditionFailure("Unexpected response")
                    }
                    promise.succeed(Self.simpleOk)
                }
            } catch {
                context.close(mode: .all, promise: nil)
            }

        case .simpleString,
            .bulkString,
            .verbatimString,
            .integer,
            .double,
            .boolean,
            .null,
            .bigNumber,
            .array,
            .map,
            .set,
            .attribute:
            guard let promise = commands.popFirst() else {
                context.fireErrorCaught(ValkeyClientError(.unsolicitedToken, message: "Received a token without having sent a command"))
                context.close(promise: nil)
            }
            promise.succeed(token)
        }
    }

    func handleError(context: ChannelHandlerContext, error: Error) {
        self.logger.debug("ValkeyCommandHandler: ERROR", metadata: ["error": "\(error)"])
        guard let promise = commands.popFirst() else {
            context.fireErrorCaught(ValkeyClientError(.unsolicitedToken, message: "Received an error token without having sent a command"))
            context.close(promise: nil)
        }
        promise.fail(error)
    }

    // Function used internally by subscribe
    func _send<Command: RESPCommand>(command: Command) -> EventLoopFuture<RESPToken> {
        self.eventLoop.assertInEventLoop()
        self.encoder.reset()
        command.encode(into: &self.encoder)
        let buffer = self.encoder.buffer

        let promise = eventLoop.makePromise(of: RESPToken.self)
        self.write(request: ValkeyRequest.single(buffer: buffer, promise: .nio(promise)))
        return promise.futureResult
    }
}
