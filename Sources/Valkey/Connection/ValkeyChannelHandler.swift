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
enum ValkeyRequest: Sendable {
    case single(buffer: ByteBuffer, promise: EventLoopPromise<RESPToken>)
    case multiple(buffer: ByteBuffer, promises: [EventLoopPromise<RESPToken>])
}

@usableFromInline
final class ValkeyChannelHandler: ChannelDuplexHandler {
    @usableFromInline
    typealias OutboundIn = ValkeyRequest
    @usableFromInline
    typealias OutboundOut = ByteBuffer
    @usableFromInline
    typealias InboundIn = ByteBuffer

    @usableFromInline
    let eventLoop: EventLoop
    private var pendingCommands: Deque<EventLoopPromise<RESPToken>>
    private var decoder: NIOSingleStepByteToMessageProcessor<RESPTokenDecoder>
    private let logger: Logger
    private var stateMachine: StateMachine<ChannelHandlerContext>

    init(channel: Channel, logger: Logger) {
        self.eventLoop = channel.eventLoop
        self.pendingCommands = .init()
        self.decoder = NIOSingleStepByteToMessageProcessor(RESPTokenDecoder())
        self.stateMachine = StateMachine()
        self.logger = logger
    }

    /// Write valkey command/commands to channel
    /// - Parameters:
    ///   - request: Valkey command request
    @inlinable
    func write(request: ValkeyRequest) -> EventLoopFuture<Void> {
        if self.eventLoop.inEventLoop {
            self.eventLoop.makeCompletedFuture {
                try self._write(request: request)
            }
        } else {
            eventLoop.submit {
                try self._write(request: request)
            }
        }
    }

    @usableFromInline
    func _write(request: ValkeyRequest) throws {
        switch self.stateMachine.sendCommand() {
        case .sendCommand(let context):
            switch request {
            case .single(let buffer, let tokenPromise):
                self.pendingCommands.append(tokenPromise)
                context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)

            case .multiple(let buffer, let tokenPromises):
                for tokenPromise in tokenPromises {
                    self.pendingCommands.append(tokenPromise)
                }
                context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
            }

        case .throwError(let error):
            throw error
        }
    }

    /// Trigger graceful shutdown of channel, by ensuring any pending commands are processed
    func triggerGracefulShutdown() {
        if self.eventLoop.inEventLoop {
            self._triggerGracefulShutdown()
        } else {
            eventLoop.execute {
                self._triggerGracefulShutdown()
            }
        }
    }

    func _triggerGracefulShutdown() {
        switch self.stateMachine.gracefulShutdown() {
        case .waitForPendingCommands:
            if let lastCommand = self.pendingCommands.last {
                lastCommand.futureResult.whenComplete { _ in
                    switch self.stateMachine.close() {
                    case .close(let context):
                        self.close(context: context, mode: .all, promise: nil)
                    case .doNothing:
                        break
                    }
                }
            } else {
                switch self.stateMachine.close() {
                case .close(let context):
                    self.close(context: context, mode: .all, promise: nil)
                case .doNothing:
                    break
                }
            }
        case .doNothing:
            break
        }
    }
}

extension ValkeyChannelHandler {
    @usableFromInline
    func handlerAdded(context: ChannelHandlerContext) {
        self.stateMachine.setActive(context: context)
    }

    @usableFromInline
    func handlerRemoved(context: ChannelHandlerContext) {
        self.setClosed()
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

    private func handleToken(context: ChannelHandlerContext, token: RESPToken) {
        guard let promise = pendingCommands.popFirst() else {
            preconditionFailure("Unexpected response")
        }
        promise.succeed(token)
    }

    private func handleError(context: ChannelHandlerContext, error: Error) {
        self.logger.debug("ValkeyCommandHandler: ERROR \(error)")
        guard let promise = pendingCommands.popFirst() else {
            preconditionFailure("Unexpected response")
        }
        promise.fail(error)
    }

    private func setClosed() {
        switch self.stateMachine.setClosed() {
        case .failPendingCommands:
            while let promise = pendingCommands.popFirst() {
                promise.fail(ValkeyClientError.init(.connectionClosed))
            }
        case .doNothing:
            break
        }
    }
}

// The ValkeyChannelHandler needs to be Sendable so the ValkeyConnection can pass it
// around at initialisation
extension ValkeyChannelHandler: @unchecked Sendable {}
