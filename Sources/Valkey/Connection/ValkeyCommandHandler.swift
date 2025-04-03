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

import Collections
import NIOCore

struct ValkeyRequest: Sendable {
    let buffer: ByteBuffer
    let continuation: CheckedContinuation<RESPToken, Error>
}

final class ValkeyCommandHandler: ChannelDuplexHandler {
    typealias OutboundIn = ValkeyRequest
    typealias OutboundOut = ByteBuffer
    typealias InboundIn = RESPToken

    var commands: Deque<CheckedContinuation<RESPToken, Error>>

    init() {
        self.commands = .init()
    }

    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let message = unwrapOutboundIn(data)
        commands.append(message.continuation)
        context.writeAndFlush(wrapOutboundOut(message.buffer), promise: promise)
    }

    func handlerRemoved(context: ChannelHandlerContext) {
        while let continuation = commands.popFirst() {
            continuation.resume(throwing: ValkeyClientError.init(.connectionClosed))
        }
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let token = self.unwrapInboundIn(data)
        guard let continuation = commands.popFirst() else {
            preconditionFailure("Unexpected response")
        }
        continuation.resume(returning: token)
    }
}
