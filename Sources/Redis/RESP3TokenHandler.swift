//===----------------------------------------------------------------------===//
//
// This source file is part of the Hummingbird server framework project
//
// Copyright (c) 2025 the Hummingbird authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See hummingbird/CONTRIBUTORS.txt for the list of Hummingbird authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Logging
import NIO
import NIOCore
import RESP3

class RESP3TokenHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = RESP3Token
    typealias OutboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer

    var decoder: NIOSingleStepByteToMessageProcessor<RESP3TokenDecoder>

    init() {
        self.decoder = .init(.init())
    }

    func handlerAdded(context: ChannelHandlerContext) {
    }

    func channelActive(context: ChannelHandlerContext) {
    }

    func channelInactive(context: ChannelHandlerContext) {
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let buffer = self.unwrapInboundIn(data)
        do {
            try self.decoder.process(buffer: buffer) { token in
                context.fireChannelRead(wrapInboundOut(token))
            }
        } catch {
            context.fireErrorCaught(error)
            context.close(promise: nil)
        }
    }
}
