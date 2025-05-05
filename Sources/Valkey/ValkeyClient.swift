//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey open source project
//
// Copyright (c) 2025 Apple Inc. and the swift-valkey project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-valkey project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Logging
import NIOCore
import NIOPosix
import NIOSSL
import NIOTransportServices
import ServiceLifecycle
import Synchronization
import _ConnectionPoolModule

/// Valkey client
///
/// Connect to Valkey server.
///
/// Supports TLS via both NIOSSL and Network framework.
public final class ValkeyClient: Sendable {
    typealias Pool = ConnectionPool<
        ValkeyConnection,
        ValkeyConnection.ID,
        ConnectionIDGenerator,
        ConnectionRequest<ValkeyConnection>,
        ConnectionRequest.ID,
        ValkeyKeepAliveBehavior,
        ValkeyClientMetrics,
        ContinuousClock
    >
    /// Server address
    let serverAddress: ServerAddress
    /// Connection pool
    let connectionPool: Pool
    /// configuration
    let configuration: ValkeyClientConfiguration
    /// EventLoopGroup to use
    let eventLoopGroup: EventLoopGroup
    /// Logger
    let logger: Logger
    /// running atomic
    let runningAtomic: Atomic<Bool>

    /// Initialize Valkey client
    ///
    /// - Parametes:
    ///   - address: Valkey database address
    ///   - configuration: Valkey client configuration
    ///   - tlsConfiguration: Valkey TLS connection configuration
    ///   - eventLoopGroup: EventLoopGroup to run WebSocket client on
    ///   - logger: Logger
    public init(
        _ address: ServerAddress,
        configuration: ValkeyClientConfiguration = .init(),
        eventLoopGroup: EventLoopGroup = MultiThreadedEventLoopGroup.singleton,
        logger: Logger
    ) {
        self.serverAddress = address
        self.connectionPool = .init(
            configuration: configuration.connectionPool,
            idGenerator: ConnectionIDGenerator(),
            requestType: ConnectionRequest<ValkeyConnection>.self,
            keepAliveBehavior: .init(configuration.keepAliveBehavior),
            observabilityDelegate: ValkeyClientMetrics(logger: logger),
            clock: .continuous
        ) { (connectionID, pool) in
            var logger = logger
            logger[metadataKey: "valkey_connection_id"] = "\(connectionID)"

            let connection = try await ValkeyConnection.connect(
                address: address,
                connectionID: connectionID,
                configuration: configuration,
                eventLoop: eventLoopGroup.any(),
                logger: logger
            )
            return ConnectionAndMetadata(connection: connection, maximalStreamsOnConnection: 1)
        }
        self.configuration = configuration
        self.eventLoopGroup = eventLoopGroup
        self.logger = logger
        self.runningAtomic = .init(false)
    }
}

extension ValkeyClient: Service {
    public func run() async {
        let atomicOp = self.runningAtomic.compareExchange(expected: false, desired: true, ordering: .relaxed)
        precondition(!atomicOp.original, "ValkeyClient.run() should just be called once!")
        await cancelWhenGracefulShutdown {
            await self.connectionPool.run()
        }
    }
    /// Create connection and run operation using connection
    ///
    /// - Parameters:
    ///   - logger: Logger
    ///   - operation: Closure handling Valkey connection
    public func withConnection<Value: Sendable>(
        name: String? = nil,
        isolation: isolated (any Actor)? = #isolation,
        operation: (ValkeyConnection) async throws -> Value
    ) async throws -> Value {
        let connection = try await self.leaseConnection()

        defer { self.connectionPool.releaseConnection(connection) }

        return try await operation(connection)
    }

    private func leaseConnection() async throws -> ValkeyConnection {
        if !self.runningAtomic.load(ordering: .relaxed) {
            self.logger.warning("Trying to lease connection from `ValkeyClient`, but `ValkeyClient.run()` hasn't been called yet.")
        }
        return try await self.connectionPool.leaseConnection()
    }

}
