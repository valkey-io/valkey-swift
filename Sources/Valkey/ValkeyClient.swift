//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 Apple Inc. and the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of valkey-swift project authors
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
    let serverAddress: ValkeyServerAddress
    /// Connection pool
    let connectionPool: Pool
    /// configuration
    let configuration: ValkeyClientConfiguration
    /// EventLoopGroup to use
    let eventLoopGroup: any EventLoopGroup
    /// Logger
    let logger: Logger
    /// running atomic
    let runningAtomic: Atomic<Bool>

    /// Initialize Valkey client
    ///
    /// - Parameters:
    ///   - address: Valkey database address
    ///   - configuration: Valkey client configuration
    ///   - tlsConfiguration: Valkey TLS connection configuration
    ///   - eventLoopGroup: EventLoopGroup to run WebSocket client on
    ///   - logger: Logger
    public convenience init(
        _ address: ValkeyServerAddress,
        configuration: ValkeyClientConfiguration = .init(),
        eventLoopGroup: EventLoopGroup = MultiThreadedEventLoopGroup.singleton,
        logger: Logger
    ) {
        self.init(
            address,
            configuration: configuration,
            connectionIDGenerator: ConnectionIDGenerator(),
            eventLoopGroup: eventLoopGroup,
            logger: logger
        )
    }

    init(
        _ address: ValkeyServerAddress,
        configuration: ValkeyClientConfiguration,
        connectionIDGenerator: ConnectionIDGenerator,
        eventLoopGroup: EventLoopGroup,
        logger: Logger
    ) {
        self.serverAddress = address
        self.connectionPool = .init(
            configuration: configuration.connectionPool,
            idGenerator: connectionIDGenerator,
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

    func triggerForceShutdown() {
        self.connectionPool.triggerForceShutdown()
    }

    /// Get connection from connection pool and run operation using connection
    ///
    /// - Parameters:
    ///   - operation: Closure handling Valkey connection
    public func withConnection<Value>(
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
    @inlinable
    public func send<Command: ValkeyCommand>(command: Command) async throws -> Command.Response {
        let token = try await self._send(command)
        return try Command.Response(fromRESP: token)
    }

    @inlinable
    func _send<Command: ValkeyCommand>(_ command: Command) async throws -> RESPToken {
        try await self.withConnection { connection in
            try await connection._send(command: command)
        }
    }
}

extension ValkeyClient {
    /// Pipeline a series of commands to Valkey connection
    ///
    /// This function will only return once it has the results of all the commands sent
    /// - Parameter commands: Parameter pack of ValkeyCommands
    /// - Returns: Parameter pack holding the results of all the commands
    @inlinable
    public func pipeline<each Command: ValkeyCommand>(
        _ commands: repeat each Command
    ) async -> sending (repeat Result<(each Command).Response, Error>) {
        do {
            return try await self.withConnection { connection in
                await connection.pipeline(repeat (each commands))
            }
        } catch {
            return (repeat Result<(each Command).Response, Error>.failure(error))
        }
    }
}

#if ServiceLifecycleSupport
extension ValkeyClient: Service {}
#endif  // ServiceLifecycle
