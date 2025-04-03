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

    private var commands: Deque<EventLoopPromise<RESPToken>>
    private var decoder: NIOSingleStepByteToMessageProcessor<RESPTokenDecoder>
    private let logger: Logger

    init(logger: Logger) {
        self.commands = .init()
        self.decoder = NIOSingleStepByteToMessageProcessor(RESPTokenDecoder())
        self.logger = logger
    }

    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let message = unwrapOutboundIn(data)
        switch message {
        case .single(let buffer, let tokenPromise):
            commands.append(tokenPromise)
            context.writeAndFlush(wrapOutboundOut(buffer), promise: promise)

        case .multiple(let buffer, let tokenPromises):
            for tokenPromise in tokenPromises {
                commands.append(tokenPromise)
            }
            context.writeAndFlush(wrapOutboundOut(buffer), promise: promise)
        }
    }

    func handlerRemoved(context: ChannelHandlerContext) {
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
