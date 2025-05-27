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
    case single(buffer: ByteBuffer, promise: ValkeyPromise<RESPToken>, id: Int)
    case multiple(buffer: ByteBuffer, promises: [ValkeyPromise<RESPToken>], id: Int)
}

@usableFromInline
final class ValkeyChannelHandler: ChannelInboundHandler {
    struct Configuration {
        let authentication: ValkeyClientConfiguration.Authentication?
        let clientName: String?
    }
    @usableFromInline
    struct PendingCommand {
        @usableFromInline
        internal init(promise: ValkeyPromise<RESPToken>, requestID: Int) {
            self.promise = promise
            self.requestID = requestID
        }

        var promise: ValkeyPromise<RESPToken>?
        let requestID: Int
    }
    @usableFromInline
    typealias OutboundOut = ByteBuffer
    @usableFromInline
    typealias InboundIn = ByteBuffer

    static let simpleOk = RESPToken(validated: ByteBuffer(string: "+OK\r\n"))
    @usableFromInline
    /*private*/ let eventLoop: EventLoop
    @usableFromInline
    /*private*/ var commands: Deque<PendingCommand>
    @usableFromInline
    /*private*/ var encoder = ValkeyCommandEncoder()
    @usableFromInline
    /*private*/ var stateMachine: StateMachine<ChannelHandlerContext>
    @usableFromInline
    /*private*/ var subscriptions: ValkeySubscriptions

    private var decoder: NIOSingleStepByteToMessageProcessor<RESPTokenDecoder>
    private let logger: Logger
    private var isClosed = false
    private let configuration: Configuration

    init(configuration: Configuration, eventLoop: EventLoop, logger: Logger) {
        self.configuration = configuration
        self.eventLoop = eventLoop
        self.commands = .init()
        self.subscriptions = .init(logger: logger)
        self.decoder = NIOSingleStepByteToMessageProcessor(RESPTokenDecoder())
        self.stateMachine = .init()
        self.logger = logger
    }

    /// Write valkey command/commands to channel
    /// - Parameters:
    ///   - request: Valkey command request
    ///   - promise: Promise to fulfill when command is complete
    @inlinable
    func write<Command: ValkeyCommand>(command: Command, continuation: CheckedContinuation<RESPToken, any Error>, requestID: Int) {
        self.eventLoop.assertInEventLoop()
        switch self.stateMachine.sendCommand() {
        case .sendCommand(let context):
            self.encoder.reset()
            command.encode(into: &self.encoder)
            let buffer = self.encoder.buffer

            self.commands.append(.init(promise: .swift(continuation), requestID: requestID))
            context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)

        case .throwError(let error):
            continuation.resume(throwing: error)
        }
    }

    @usableFromInline
    func write(request: ValkeyRequest) {
        self.eventLoop.assertInEventLoop()
        switch self.stateMachine.sendCommand() {
        case .sendCommand(let context):
            switch request {
            case .single(let buffer, let tokenPromise, let id):
                self.commands.append(.init(promise: tokenPromise, requestID: id))
                context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)

            case .multiple(let buffer, let tokenPromises, let id):
                for tokenPromise in tokenPromises {
                    self.commands.append(.init(promise: tokenPromise, requestID: id))
                }
                context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
            }

        case .throwError(let error):
            switch request {
            case .single(_, let tokenPromise, _):
                tokenPromise.fail(error)

            case .multiple(_, let tokenPromises, _):
                for promise in tokenPromises {
                    promise.fail(error)
                }
            }
        }
    }

    /// Add subscription, and call SUBSCRIBE command if required
    func subscribe(
        command: some ValkeyCommand,
        streamContinuation: ValkeySubscription.Continuation,
        filters: [ValkeySubscriptionFilter],
        promise: ValkeyPromise<Int>,
        requestID: Int
    ) {
        self.eventLoop.assertInEventLoop()
        switch self.subscriptions.addSubscription(continuation: streamContinuation, filters: filters) {
        case .subscribe(let subscription, _):
            // TODO: currently ignoring returned filter array, as we have already constructed the subscribe command
            //   But it would be cool to build the subscribe command based on what filters we aren't subscribed to
            self.subscriptions.pushCommand(filters: subscription.filters)
            let subscriptionID = subscription.id
            return self._send(command: command, requestID: requestID).assumeIsolated().whenComplete { result in
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
        promise: ValkeyPromise<Void>,
        requestID: Int
    ) {
        self.eventLoop.assertInEventLoop()
        switch self.subscriptions.unsubscribe(id: id) {
        case .unsubscribe(let channels):
            self.performUnsubscribe(
                command: UNSUBSCRIBE(channel: channels),
                filters: channels.map { .channel($0) },
                promise: promise,
                requestID: requestID
            )
        case .punsubscribe(let patterns):
            self.performUnsubscribe(
                command: PUNSUBSCRIBE(pattern: patterns),
                filters: patterns.map { .pattern($0) },
                promise: promise,
                requestID: requestID
            )
        case .sunsubscribe(let shardChannels):
            self.performUnsubscribe(
                command: SUNSUBSCRIBE(shardchannel: shardChannels),
                filters: shardChannels.map { .shardChannel($0) },
                promise: promise,
                requestID: requestID
            )
        case .doNothing:
            promise.succeed(())
        }
    }

    func performUnsubscribe(
        command: some ValkeyCommand,
        filters: [ValkeySubscriptionFilter],
        promise: ValkeyPromise<Void>,
        requestID: Int
    ) {
        self.subscriptions.pushCommand(filters: filters)
        self._send(command: command, requestID: requestID).assumeIsolated().whenComplete { result in
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
    func hello(context: ChannelHandlerContext) {
        // send hello with protocol, authentication and client name details
        self._send(
            command: HELLO(
                arguments: .init(
                    protover: 3,
                    auth: configuration.authentication.map { .init(username: $0.username, password: $0.password) },
                    clientname: configuration.clientName
                )
            ),
            requestID: 0
        ).assumeIsolated().whenComplete { result in
            switch result {
            case .failure(let error):
                context.fireErrorCaught(error)
                context.close(promise: nil)
            case .success:
                break
            }
        }
    }

    @usableFromInline
    func handlerAdded(context: ChannelHandlerContext) {
        self.stateMachine.setActive(context: context)
        if context.channel.isActive {
            hello(context: context)
        }
    }

    @usableFromInline
    func handlerRemoved(context: ChannelHandlerContext) {
        self.setClosed()
    }

    @usableFromInline
    func channelActive(context: ChannelHandlerContext) {
        hello(context: context)
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
        self.setClosed()

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

    @usableFromInline
    func cancel(requestID: Int) {
        self.eventLoop.assertInEventLoop()
        switch self.stateMachine.cancel() {
        case .closeAndCancelPendingCommands(_):
            for index in self.commands.indices {
                if commands[index].requestID == requestID {
                    commands[index].promise?.fail(CancellationError())
                    commands[index].promise = nil
                }
            }
        case .doNothing:
            break
        }
    }

    func handleToken(context: ChannelHandlerContext, token: RESPToken) {
        switch token.identifier {
        case .simpleError, .bulkError:
            guard let command = commands.popFirst() else {
                self.failPendingCommandsAndSubscriptionsAndCloseConnection(
                    ValkeyClientError(.unsolicitedToken, message: "Received an error token without having sent a command"),
                    context: context
                )
                return
            }
            if let promise = command.promise {
                promise.fail(ValkeyClientError(.commandError, message: token.errorString.map { String(buffer: $0) }))
            }

        case .push:
            // If subscription notify throws an error then assume something has gone wrong
            // and close the channel with the error
            do {
                if try self.subscriptions.notify(token) == true {
                    guard let command = commands.popFirst() else {
                        preconditionFailure("Unexpected response")
                    }
                    if let promise = command.promise {
                        promise.succeed(Self.simpleOk)
                    }
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
            guard let command = commands.popFirst() else {
                self.failPendingCommandsAndSubscriptionsAndCloseConnection(
                    ValkeyClientError(.unsolicitedToken, message: "Received a token without having sent a command"),
                    context: context
                )
                return
            }
            if let promise = command.promise {
                promise.succeed(token)
            }
        }
    }

    func handleError(context: ChannelHandlerContext, error: Error) {
        self.logger.debug("ValkeyCommandHandler: ERROR", metadata: ["error": "\(error)"])
        guard let command = commands.popFirst() else {
            self.failPendingCommandsAndSubscriptionsAndCloseConnection(
                ValkeyClientError(.unsolicitedToken, message: "Received an error decoding a token without having sent a command"),
                context: context
            )
            return
        }
        if let promise = command.promise {
            promise.fail(error)
        }
    }

    private func failPendingCommandsAndSubscriptions(_ error: any Error) {
        while let command = self.commands.popFirst() {
            if let promise = command.promise {
                promise.fail(error)
            }
        }
        self.subscriptions.close(error: error)
    }

    private func failPendingCommandsAndSubscriptionsAndCloseConnection(_ error: any Error, context: ChannelHandlerContext) {
        self.failPendingCommandsAndSubscriptions(error)
        context.fireErrorCaught(error)
        context.close(promise: nil)
    }

    // Function used internally by subscribe
    func _send<Command: ValkeyCommand>(command: Command, requestID: Int) -> EventLoopFuture<RESPToken> {
        self.eventLoop.assertInEventLoop()
        self.encoder.reset()
        command.encode(into: &self.encoder)
        let buffer = self.encoder.buffer

        let promise = eventLoop.makePromise(of: RESPToken.self)
        self.write(request: ValkeyRequest.single(buffer: buffer, promise: .nio(promise), id: requestID))
        return promise.futureResult
    }

    private func setClosed() {
        switch self.stateMachine.setClosed() {
        case .failPendingCommands:
            self.failPendingCommandsAndSubscriptions(ValkeyClientError.init(.connectionClosed))

        case .doNothing:
            break
        }
    }
}
