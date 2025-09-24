//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import Logging
import NIOCore
import NIOPosix
import NIOSSL
import NIOTransportServices
import Synchronization
import _ValkeyConnectionPool

#if ServiceLifecycleSupport
import ServiceLifecycle
#endif

/// Valkey node
///
/// Connect to single Valkey server.
///
/// Supports TLS via both NIOSSL and Network framework.
@available(valkeySwift 1.0, *)
public final class ValkeyNodeClient: Sendable {
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
    public let serverAddress: ValkeyServerAddress
    /// Connection pool
    let connectionPool: Pool

    let connectionFactory: ValkeyConnectionFactory
    /// configuration
    public var configuration: ValkeyClientConfiguration { self.connectionFactory.configuration }
    /// EventLoopGroup to use
    public let eventLoopGroup: any EventLoopGroup
    /// Logger
    public let logger: Logger

    package init(
        _ address: ValkeyServerAddress,
        connectionIDGenerator: ConnectionIDGenerator,
        connectionFactory: ValkeyConnectionFactory,
        eventLoopGroup: EventLoopGroup,
        logger: Logger
    ) {
        self.serverAddress = address

        var poolConfiguration = _ValkeyConnectionPool.ConnectionPoolConfiguration()
        poolConfiguration.minimumConnectionCount = connectionFactory.configuration.connectionPool.minimumConnectionCount
        poolConfiguration.maximumConnectionSoftLimit = connectionFactory.configuration.connectionPool.maximumConnectionCount
        poolConfiguration.maximumConnectionHardLimit = connectionFactory.configuration.connectionPool.maximumConnectionCount

        self.connectionPool = .init(
            configuration: poolConfiguration,
            idGenerator: connectionIDGenerator,
            requestType: ConnectionRequest<ValkeyConnection>.self,
            keepAliveBehavior: .init(connectionFactory.configuration.keepAliveBehavior),
            observabilityDelegate: ValkeyClientMetrics(logger: logger),
            clock: .continuous
        ) { (connectionID, pool) in
            var logger = logger
            logger[metadataKey: "valkey_connection_id"] = "\(connectionID)"

            let connection = try await connectionFactory.makeConnection(
                address: address,
                connectionID: connectionID,
                eventLoop: eventLoopGroup.any(),
                logger: logger
            )

            return ConnectionAndMetadata(connection: connection, maximalStreamsOnConnection: 1)
        }
        self.connectionFactory = connectionFactory
        self.eventLoopGroup = eventLoopGroup
        self.logger = logger
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyNodeClient {
    /// Run ValkeyNode connection pool
    @usableFromInline
    package func run() async {
        await self.connectionPool.run()
    }

    func triggerForceShutdown() {
        self.connectionPool.triggerForceShutdown()
    }

    /// Get connection from connection pool and run operation using connection
    ///
    /// - Parameters:
    ///   - isolation: Actor isolation
    ///   - operation: Closure handling Valkey connection
    /// - Returns: Value returned by closure
    public func withConnection<Value>(
        isolation: isolated (any Actor)? = #isolation,
        operation: (ValkeyConnection) async throws -> sending Value
    ) async throws -> Value {
        let connection = try await self.leaseConnection()

        defer { self.connectionPool.releaseConnection(connection) }

        return try await operation(connection)
    }

    private func leaseConnection() async throws -> ValkeyConnection {
        try await self.connectionPool.leaseConnection()
    }
}

/// Extend ValkeyNode so we can call commands directly from it
@available(valkeySwift 1.0, *)
extension ValkeyNodeClient {
    /// Send command to Valkey connection from connection pool
    /// - Parameter command: Valkey command
    /// - Returns: Response from Valkey command
    @inlinable
    public func execute<Command: ValkeyCommand>(_ command: Command) async throws -> Command.Response {
        try await self.withConnection { connection in
            try await connection.execute(command)
        }
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyNodeClient {
    /// Pipeline a series of commands to Valkey connection
    ///
    /// Once all the responses for the commands have been received the function returns
    /// a parameter pack of Results, one for each command.
    ///
    /// - Parameter commands: Parameter pack of ValkeyCommands
    /// - Returns: Parameter pack holding the results of all the commands
    @inlinable
    public func execute<each Command: ValkeyCommand>(
        _ commands: repeat each Command
    ) async -> sending (repeat Result<(each Command).Response, Error>) {
        do {
            return try await self.withConnection { connection in
                await connection.execute(repeat (each commands))
            }
        } catch {
            return (repeat Result<(each Command).Response, Error>.failure(error))
        }
    }

    /// Pipeline a series of commands to Valkey connection
    ///
    /// Once all the responses for the commands have been received the function returns
    /// an array of RESPToken Results, one for each command.
    ///
    /// This is an alternative version of the pipelining function ``ValkeyClient/execute(_:)->(_,_)``
    /// that allows for a collection of ValkeyCommands. It provides more flexibility but
    /// is more expensive to run and the command responses are returned as ``RESPToken``
    /// instead of the response type for the command.
    ///
    /// - Parameter commands: Collection of ValkeyCommands
    /// - Returns: Array holding the RESPToken responses of all the commands
    @inlinable
    public func execute<Commands: Collection & Sendable>(
        _ commands: Commands
    ) async -> sending [Result<RESPToken, Error>] where Commands.Element == any ValkeyCommand {
        do {
            return try await self.withConnection { connection in
                await connection.execute(commands)
            }
        } catch {
            return .init(repeating: .failure(error), count: commands.count)
        }
    }

    /// Internal command used by cluster client, that precedes each command with a ASKING
    /// command
    func ask<Commands: Collection & Sendable>(
        _ commands: Commands
    ) async -> sending [Result<RESPToken, Error>] where Commands.Element == any ValkeyCommand {
        do {
            return try await self.withConnection { connection in
                await connection.executeWithAsk(commands)
            }
        } catch {
            return .init(repeating: .failure(error), count: commands.count)
        }
    }
}

/// Extension that makes ``ValkeyNode`` conform to ``ValkeyNodeConnectionPool``.
///
/// This enables the ``ValkeyClusterClient`` to manage individual ``ValkeyNode`` instances.
@available(valkeySwift 1.0, *)
extension ValkeyNodeClient: ValkeyNodeConnectionPool {
    /// Initiates a graceful shutdown of the client.
    ///
    /// This method attempts to cleanly shut down the client's connections.
    /// If not implemented, it falls back to force shutdown.
    @usableFromInline
    package func triggerGracefulShutdown() {
        // TODO: Implement graceful shutdown
        self.triggerForceShutdown()
    }
}
