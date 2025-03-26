//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-redis open source project
//
// Copyright (c) 2023 Apple Inc. and the swift-redis project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-redis project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Logging
import NIOCore
import RESP

public final class RedisConnection {
    var inboundIterator: NIOAsyncChannelInboundStream<RESPToken>.AsyncIterator
    let outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>
    let logger: Logger

    public init(inbound: NIOAsyncChannelInboundStream<RESPToken>, outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>, logger: Logger) {
        self.inboundIterator = inbound.makeAsyncIterator()
        self.outbound = outbound
        self.logger = logger
    }

    @discardableResult public func send(_ command: RESPCommand) async throws -> RESPToken {
        if logger.logLevel <= .debug {
            var buffer = command.buffer
            let sending = try [String](from: RESPToken(consuming: &buffer)!).joined(separator: " ")
            self.logger.debug("send: \(sending)")
        }
        try await self.outbound.write(command.buffer)
        guard let response = try await self.inboundIterator.next() else { throw RedisClientError(.connectionClosed) }
        if let value = response.errorString {
            throw RedisClientError(.commandError, message: String(buffer: value))
        }
        return response
    }

    @discardableResult public func send<each Arg: RESPRenderable>(_ command: repeat each Arg) async throws -> RESPToken {
        let command = RESPCommand(repeat each command)
        return try await self.send(command)
    }

    @discardableResult public func pipeline(_ commands: [RESPCommand]) async throws -> [RESPToken] {
        try await self.outbound.write(contentsOf: commands.map { $0.buffer })
        var responses: [RESPToken] = .init()
        for _ in 0..<commands.count {
            guard let response = try await self.inboundIterator.next() else { throw RedisClientError(.connectionClosed) }
            responses.append(response)
        }
        return responses
    }

    var subscriptions: RedisSubscriptionAsyncSequence<NIOAsyncChannelInboundStream<RESPToken>> {
        RedisSubscriptionAsyncSequence(baseIterator: self.inboundIterator)
    }
}

@available(*, unavailable)
extension RedisConnection: Sendable {
}
