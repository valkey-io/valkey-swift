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

enum ValkeyRequest: Sendable {
    case single(buffer: ByteBuffer, promise: EventLoopPromise<RESPToken>)
    case multiple(buffer: ByteBuffer, promises: [EventLoopPromise<RESPToken>])
}

final class ValkeyChannelHandler: ChannelDuplexHandler {
    typealias OutboundIn = ValkeyRequest
    typealias OutboundOut = ByteBuffer
    typealias InboundIn = ByteBuffer

    private let eventLoop: EventLoop
    private var commands: Deque<EventLoopPromise<RESPToken>>
    private var decoder: NIOSingleStepByteToMessageProcessor<RESPTokenDecoder>
    private var context: ChannelHandlerContext?
    private let logger: Logger

    init(channel: Channel, logger: Logger) {
        self.eventLoop = channel.eventLoop
        self.commands = .init()
        self.decoder = NIOSingleStepByteToMessageProcessor(RESPTokenDecoder())
        self.context = nil
        self.logger = logger
    }

    /// Write valkey command/commands to channel
    /// - Parameters:
    ///   - request: Valkey command request
    ///   - promise: Promise to fulfill when command is complete
    func write(request: ValkeyRequest, promise: EventLoopPromise<Void>?) {
        eventLoop.execute {
            guard let context = self.context else {
                preconditionFailure("Trying to use valkey connection before it is setup")
            }
            switch request {
            case .single(let buffer, let tokenPromise):
                self.commands.append(tokenPromise)
                context.writeAndFlush(self.wrapOutboundOut(buffer), promise: promise)

            case .multiple(let buffer, let tokenPromises):
                for tokenPromise in tokenPromises {
                    self.commands.append(tokenPromise)
                }
                context.writeAndFlush(self.wrapOutboundOut(buffer), promise: promise)
            }
        }
    }

    func handlerAdded(context: ChannelHandlerContext) {
        self.context = context
    }

    func handlerRemoved(context: ChannelHandlerContext) {
        self.context = nil
        while let promise = commands.popFirst() {
            promise.fail(ValkeyClientError.init(.connectionClosed))
        }
    }

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
        guard let promise = commands.popFirst() else {
            preconditionFailure("Unexpected response")
        }
        promise.succeed(token)
    }

    func handleError(context: ChannelHandlerContext, error: Error) {
        self.logger.debug("ValkeyCommandHandler: ERROR \(error)")
        guard let promise = commands.popFirst() else {
            preconditionFailure("Unexpected response")
        }
        promise.fail(error)
    }
}

// The ValkeyChannelHandler needs to be Sendable so the ValkeyConnection can pass it
// around at initialisation
extension ValkeyChannelHandler: @unchecked Sendable {}
