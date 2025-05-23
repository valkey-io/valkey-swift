//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey open source project
//
// Copyright (c) 2025 the swift-valkey project authors
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
import Synchronization
import _ConnectionPoolModule

#if ServiceLifecycleSupport
import ServiceLifecycle
#endif

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

extension ValkeyClient {
    /// Run ValkeyClient connection pool
    public func run() async {
        let atomicOp = self.runningAtomic.compareExchange(expected: false, desired: true, ordering: .relaxed)
        precondition(!atomicOp.original, "ValkeyClient.run() should just be called once!")
        #if ServiceLifecycleSupport
        await cancelWhenGracefulShutdown {
            await self.connectionPool.run()
        }
        #else
        await self.connectionPool.run()
        #endif
    }

    /// Get connection from connection pool and run operation using connection
    ///
    /// - Parameters:
    ///   - operation: Closure handling Valkey connection
    public func withConnection<Value>(
        name: String? = nil,
        isolation: isolated (any Actor)? = #isolation,
        operation: (ValkeyConnection) async throws -> sending Value
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

/// Extend ValkeyClient so we can call commands directly from it
extension ValkeyClient: ValkeyConnectionProtocol {
    public func send<Command: ValkeyCommand>(command: Command) async throws -> Command.Response {
        try await self.withConnection {
            try await $0.send(command: command)
        }
    }
}

#if ServiceLifecycleSupport
extension ValkeyClient: Service {}
#endif  // ServiceLifecycle
