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

    @usableFromInline
    /*private*/ let eventLoop: EventLoop
    @usableFromInline
    /*private*/ var commands: Deque<ValkeyPromise<RESPToken>>
    @usableFromInline
    /*private*/ var encoder = RESPCommandEncoder()
    @usableFromInline
    /*private*/ var context: ChannelHandlerContext?

    private var decoder: NIOSingleStepByteToMessageProcessor<RESPTokenDecoder>
    private let logger: Logger

    init(eventLoop: EventLoop, logger: Logger) {
        self.eventLoop = eventLoop
        self.commands = .init()
        self.decoder = NIOSingleStepByteToMessageProcessor(RESPTokenDecoder())
        self.context = nil
        self.logger = logger
    }

    /// Write valkey command/commands to channel
    /// - Parameters:
    ///   - request: Valkey command request
    ///   - promise: Promise to fulfill when command is complete
    @inlinable
    func write(request: ValkeyRequest) {
        self._write(request: request)
    }

    /// Write valkey command/commands to channel
    /// - Parameters:
    ///   - request: Valkey command request
    ///   - promise: Promise to fulfill when command is complete
    @inlinable
    func write<Command: RESPCommand>(command: Command, continuation: CheckedContinuation<RESPToken, any Error>) {
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
    func _write(request: ValkeyRequest) {
        self.eventLoop.assertInEventLoop()
        guard let context = self.context else {
            preconditionFailure("Trying to use valkey connection before it is setup")
        }
        switch request {
        case .single(let buffer, let tokenPromise):
            self.commands.append(tokenPromise)
            context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)

        case .multiple(let buffer, let tokenPromises):
            for tokenPromise in tokenPromises {
                self.commands.append(tokenPromise)
            }
            context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
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
        default:
            guard let promise = commands.popFirst() else {
                preconditionFailure("Unexpected response")
            }
            promise.succeed(token)
        }
    }

    func handleError(context: ChannelHandlerContext, error: Error) {
        self.logger.debug("ValkeyCommandHandler: ERROR \(error)")
        guard let promise = commands.popFirst() else {
            preconditionFailure("Unexpected response")
        }
        promise.fail(error)
    }
}
