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
import NIOPosix
import NIOSSL
import NIOTransportServices

/// Redis client
///
/// Connect to redis server.
///
/// Supports TLS via both NIOSSL and Network framework.
///
/// Initialize the RedisClient with your handler and then call ``WebSocketClient/run()``
/// to connect. The handler is provider with an `inbound` stream of RESP3Token packets coming
/// from the server and an `outbound` writer that can be used to write RESP3Token to the server.
public struct RedisClient {
    enum MultiPlatformTLSConfiguration: Sendable {
        case niossl(TLSConfiguration)
        #if canImport(Network)
        case ts(TSTLSOptions)
        #endif
    }

    /// Server address
    let serverAddress: ServerAddress
    /// configuration
    let configuration: RedisClientConfiguration
    /// EventLoopGroup to use
    let eventLoopGroup: EventLoopGroup
    /// Logger
    let logger: Logger
    /// TLS configuration
    let tlsConfiguration: MultiPlatformTLSConfiguration?

    /// Initialize redis client
    ///
    /// - Parametes:
    ///   - url: URL of websocket
    ///   - tlsConfiguration: TLS configuration
    ///   - handler: WebSocket data handler
    ///   - maxFrameSize: Max frame size for a single packet
    ///   - eventLoopGroup: EventLoopGroup to run WebSocket client on
    ///   - logger: Logger
    public init(
        _ address: ServerAddress,
        configuration: RedisClientConfiguration = .init(),
        tlsConfiguration: TLSConfiguration? = nil,
        eventLoopGroup: EventLoopGroup = MultiThreadedEventLoopGroup.singleton,
        logger: Logger
    ) {
        self.serverAddress = address
        self.configuration = configuration
        self.eventLoopGroup = eventLoopGroup
        self.logger = logger
        self.tlsConfiguration = tlsConfiguration.map { .niossl($0) }
    }

    #if canImport(Network)
    /// Initialize websocket client
    ///
    /// - Parametes:
    ///   - url: URL of websocket
    ///   - transportServicesTLSOptions: TLS options for NIOTransportServices
    ///   - maxFrameSize: Max frame size for a single packet
    ///   - eventLoopGroup: EventLoopGroup to run WebSocket client on
    ///   - logger: Logger
    public init(
        _ address: ServerAddress,
        configuration: RedisClientConfiguration = .init(),
        transportServicesTLSOptions: TSTLSOptions,
        eventLoopGroup: NIOTSEventLoopGroup = NIOTSEventLoopGroup.singleton,
        logger: Logger
    ) {
        self.serverAddress = address
        self.configuration = configuration
        self.eventLoopGroup = eventLoopGroup
        self.logger = logger
        self.tlsConfiguration = .ts(transportServicesTLSOptions)
    }
    #endif
}

extension RedisClient {
    /// Create connection and run operation using connection
    ///
    /// - Parameters:
    ///   - operation: Closure handling webSocket
    ///   - logger: Logger
    public func withConnection<Value: Sendable>(
        logger: Logger,
        operation: @escaping @Sendable (RedisClientConnection) async throws -> Value
    ) async throws -> Value {
        let redisConnection = RedisClientConnection(
            address: self.serverAddress,
            configuration: self.configuration,
            eventLoopGroup: self.eventLoopGroup,
            logger: logger
        )
        return try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await redisConnection.run()
            }
            let value: Value = try await operation(redisConnection)
            group.cancelAll()
            return value
        }
    }
}
