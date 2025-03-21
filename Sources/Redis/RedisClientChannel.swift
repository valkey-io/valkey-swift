//===----------------------------------------------------------------------===//
//
// This source file is part of the Hummingbird server framework project
//
// Copyright (c) 2024 the Hummingbird authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See hummingbird/CONTRIBUTORS.txt for the list of Hummingbird authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Logging
import NIOCore
import RESP3

public typealias RedisAsyncChannel = NIOAsyncChannel<RESP3Token, RESP3Command>
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
                let connection = RedisConnection(inbound: inbound, outbound: outbound)
                try await handler(connection, logger)
            }
        } onCancel: {
            asyncChannel.channel.close(mode: .input, promise: nil)
        }
    }
}
