//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-redis open source project
//
// Copyright (c) 2023 the swift-redis project authors
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

public typealias RedisAsyncChannel = NIOAsyncChannel<RESPToken, ByteBuffer>
public typealias RedisClientHandler = @Sendable (RedisConnection, Logger) async throws -> Void

struct RedisClientChannel: ClientConnectionChannel {
    typealias Value = RedisAsyncChannel

    let handler: RedisClientHandler
    let configuration: RedisClientConfiguration

    init(configuration: RedisClientConfiguration, handler: @escaping RedisClientHandler) throws {
        self.handler = handler
        self.configuration = configuration
    }

    func setup(channel: any Channel, logger: Logger) -> NIOCore.EventLoopFuture<Value> {
        channel.eventLoop.makeCompletedFuture {
            try channel.pipeline.syncOperations.addHandler(RESP3TokenHandler())
            return try RedisAsyncChannel(
                wrappingChannelSynchronously: channel,
                configuration: .init()
            )
        }
    }

    func handle(value asyncChannel: Value, logger: Logger) async throws {
        try await withTaskCancellationHandler {
            try await asyncChannel.executeThenClose { inbound, outbound in
                let connection = RedisConnection(inbound: inbound, outbound: outbound, logger: logger)
                // Switch to RESP3 protocol
                _ = try await connection.send("HELLO", 3)
                try await handler(connection, logger)
            }
        } onCancel: {
            asyncChannel.channel.close(mode: .input, promise: nil)
        }
    }
}
