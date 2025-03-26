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
    /// Redis data handler
    let handler: RedisClientHandler
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
        logger: Logger,
        handler: @escaping RedisClientHandler
    ) {
        self.serverAddress = address
        self.handler = handler
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
    ///   - handler: WebSocket data handler
    ///   - maxFrameSize: Max frame size for a single packet
    ///   - eventLoopGroup: EventLoopGroup to run WebSocket client on
    ///   - logger: Logger
    public init(
        _ address: ServerAddress,
        configuration: RedisClientConfiguration = .init(),
        transportServicesTLSOptions: TSTLSOptions,
        eventLoopGroup: NIOTSEventLoopGroup = NIOTSEventLoopGroup.singleton,
        logger: Logger,
        handler: @escaping RedisClientHandler
    ) {
        self.serverAddress = address
        self.handler = handler
        self.configuration = configuration
        self.eventLoopGroup = eventLoopGroup
        self.logger = logger
        self.tlsConfiguration = .ts(transportServicesTLSOptions)
    }
    #endif

    /// Connect and run handler
    /// - Returns: WebSocket close frame details if server returned any
    public func run() async throws {
        if let tlsConfiguration {
            switch tlsConfiguration {
            case .niossl(let tlsConfiguration):
                let client = try ClientConnection(
                    TLSClientChannel(
                        RedisClientChannel(configuration: self.configuration, handler: handler),
                        tlsConfiguration: tlsConfiguration,
                        serverHostname: "sdf"
                    ),
                    address: serverAddress,
                    eventLoopGroup: self.eventLoopGroup,
                    logger: self.logger
                )
                return try await client.run()

            #if canImport(Network)
            case .ts(let tlsOptions):
                let client = try ClientConnection(
                    RedisClientChannel(configuration: self.configuration, handler: handler),
                    address: serverAddress,
                    transportServicesTLSOptions: tlsOptions,
                    eventLoopGroup: self.eventLoopGroup,
                    logger: self.logger
                )
                return try await client.run()

            #endif
            }
        } else {
            let client = try ClientConnection(
                RedisClientChannel(configuration: self.configuration, handler: handler),
                address: serverAddress,
                eventLoopGroup: self.eventLoopGroup,
                logger: self.logger
            )
            return try await client.run()
        }
    }
}

extension RedisClient {
    /// Create websocket client, connect and handle connection
    ///
    /// - Parametes:
    ///   - url: URL of websocket
    ///   - tlsConfiguration: TLS configuration
    ///   - maxFrameSize: Max frame size for a single packet
    ///   - eventLoopGroup: EventLoopGroup to run WebSocket client on
    ///   - logger: Logger
    ///   - process: Closure handling webSocket
    /// - Returns: WebSocket close frame details if server returned any
    public static func withConnection(
        _ address: ServerAddress,
        configuration: RedisClientConfiguration = .init(),
        tlsConfiguration: TLSConfiguration? = nil,
        eventLoopGroup: EventLoopGroup = MultiThreadedEventLoopGroup.singleton,
        logger: Logger,
        handler: @escaping RedisClientHandler
    ) async throws {
        let redis = self.init(
            address,
            configuration: configuration,
            tlsConfiguration: tlsConfiguration,
            eventLoopGroup: eventLoopGroup,
            logger: logger,
            handler: handler
        )
        return try await redis.run()
    }

    #if canImport(Network)
    /// Create websocket client, connect and handle connection
    ///
    /// - Parametes:
    ///   - url: URL of websocket
    ///   - transportServicesTLSOptions: TLS options for NIOTransportServices
    ///   - maxFrameSize: Max frame size for a single packet
    ///   - eventLoopGroup: EventLoopGroup to run WebSocket client on
    ///   - logger: Logger
    ///   - process: WebSocket data handler
    /// - Returns: WebSocket close frame details if server returned any
    public static func withConnection(
        _ address: ServerAddress,
        configuration: RedisClientConfiguration = .init(),
        transportServicesTLSOptions: TSTLSOptions,
        eventLoopGroup: NIOTSEventLoopGroup = NIOTSEventLoopGroup.singleton,
        logger: Logger,
        handler: @escaping RedisClientHandler
    ) async throws {
        let redis = self.init(
            address,
            configuration: configuration,
            transportServicesTLSOptions: transportServicesTLSOptions,
            eventLoopGroup: eventLoopGroup,
            logger: logger,
            handler: handler
        )
        return try await redis.run()
    }
    #endif
}
