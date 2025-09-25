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
@usableFromInline
package final class ValkeyNodeClient: Sendable {
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
    @usableFromInline
    typealias ConnectionStateMachine =
        SubscriptionConnectionStateMachine<
            ValkeyConnection,
            CheckedContinuation<ValkeyConnection, any Error>,
            CheckedContinuation<Void, Never>
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
    /// subscription connection state
    @usableFromInline
    let subscriptionConnectionStateMachine: Mutex<ConnectionStateMachine>
    @usableFromInline
    let subscriptionConnectionIDGenerator: ConnectionIDGenerator
    /// Actions that can be run on a node
    enum RunAction: Sendable {
        case leaseSubscriptionConnection(leaseID: Int)
    }
    let actionStream: AsyncStream<RunAction>
    let actionStreamContinuation: AsyncStream<RunAction>.Continuation

    package init(
        _ address: ValkeyServerAddress,
        connectionIDGenerator: ConnectionIDGenerator,
        connectionFactory: ValkeyConnectionFactory,
        eventLoopGroup: any EventLoopGroup,
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
        self.subscriptionConnectionStateMachine = .init(.init())
        self.subscriptionConnectionIDGenerator = .init()
        (self.actionStream, self.actionStreamContinuation) = AsyncStream.makeStream(of: RunAction.self)
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyNodeClient {
    /// Run ValkeyNode connection pool
    @usableFromInline
    package func run() async {
        /// Run discarding task group running actions
        await withDiscardingTaskGroup { group in
            group.addTask {
                await self.connectionPool.run()
                self.shutdownSubscriptionConnection()
            }
            for await action in self.actionStream {
                group.addTask {
                    await self.runAction(action)
                }
            }
        }
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
    func execute<each Command: ValkeyCommand>(
        _ commands: repeat each Command
    ) async -> sending (repeat Result<(each Command).Response, any Error>) {
        do {
            return try await self.withConnection { connection in
                await connection.execute(repeat (each commands))
            }
        } catch {
            return (repeat Result<(each Command).Response, any Error>.failure(error))
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
    func execute<Commands: Collection & Sendable>(
        _ commands: Commands
    ) async -> sending [Result<RESPToken, any Error>] where Commands.Element == any ValkeyCommand {
        do {
            return try await self.withConnection { connection in
                await connection.execute(commands)
            }
        } catch {
            return .init(repeating: .failure(error), count: commands.count)
        }
    }

    /// Pipeline a series of commands as a transaction to Valkey connection
    ///
    /// Another client will never be served in the middle of the execution of these
    /// commands. See https://valkey.io/topics/transactions/ for more information.
    ///
    /// EXEC and MULTI commands are added to the pipelined commands and the output
    /// of the EXEC command is transformed into a parameter pack of Results, one
    /// for each command.
    ///
    /// - Parameter commands: Parameter pack of ValkeyCommands
    /// - Returns: Parameter pack holding the responses of all the commands
    @inlinable
    func transaction<each Command: ValkeyCommand>(
        _ commands: repeat each Command
    ) async throws -> sending (repeat Result<(each Command).Response, Error>) {
        try await self.withConnection { connection in
            try await connection.transaction(repeat (each commands))
        }
    }

    /// Pipeline a series of commands as a transaction to Valkey connection
    ///
    /// Another client will never be served in the middle of the execution of these
    /// commands. See https://valkey.io/topics/transactions/ for more information.
    ///
    /// EXEC and MULTI commands are added to the pipelined commands and the output
    /// of the EXEC command is transformed into an array of RESPToken Results, one for
    /// each command.
    ///
    /// This is an alternative version of the transaction function ``ValkeyNodeClient/transaction(_:)->(_,_)``
    /// that allows for a collection of ValkeyCommands. It provides more flexibility but the command
    /// responses are returned as ``RESPToken`` instead of the response type for the command.
    ///
    /// - Parameter commands: Collection of ValkeyCommands
    /// - Returns: Array holding the RESPToken responses of all the commands
    @inlinable
    func transaction<Commands: Collection & Sendable>(
        _ commands: Commands
    ) async throws -> sending [Result<RESPToken, Error>] where Commands.Element == any ValkeyCommand {
        try await self.withConnection { connection in
            try await connection.transaction(commands)
        }
    }

    /// Internal command used by cluster client, that precedes each command with a ASKING
    /// command
    func executeWithAsk<Commands: Collection & Sendable>(
        _ commands: Commands
    ) async -> sending [Result<RESPToken, any Error>] where Commands.Element == any ValkeyCommand {
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

@available(valkeySwift 1.0, *)
extension ValkeyNodeClient {
    func queueAction(_ action: RunAction) {
        self.actionStreamContinuation.yield(action)
    }

    private func runAction(_ action: RunAction) async {
        switch action {
        case .leaseSubscriptionConnection(let leaseID):
            do {
                try await self.withConnection { connection in
                    await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                        self.acquiredSubscriptionConnection(leaseID: leaseID, connection: connection, releaseContinuation: cont)
                    }
                }
            } catch {
                self.errorAcquiringSubscriptionConnection(leaseID: leaseID, error: error)
            }
        }
    }
}
