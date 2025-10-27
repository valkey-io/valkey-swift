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

/// A client that connects to a Valkey server.
///
/// `ValkeyClient` supports TLS using both NIOSSL and the Network framework.
@available(valkeySwift 1.0, *)
public final class ValkeyClient: Sendable {
    let nodeClientFactory: ValkeyNodeClientFactory
    /// single node
    @usableFromInline
    let node: ValkeyNodeClient
    /// configuration
    var configuration: ValkeyClientConfiguration { self.nodeClientFactory.configuration }
    /// EventLoopGroup to use
    let eventLoopGroup: any EventLoopGroup
    /// Logger
    let logger: Logger
    /// running atomic
    let runningAtomic: Atomic<Bool>

    enum RunAction: Sendable {
        case runNodeClient(ValkeyNodeClient)
    }
    let actionStream: AsyncStream<RunAction>
    let actionStreamContinuation: AsyncStream<RunAction>.Continuation

    /// Creates a new Valkey client
    ///
    /// - Parameters:
    ///   - address: Valkey database address
    ///   - configuration: Valkey client configuration
    ///   - eventLoopGroup: EventLoopGroup to run WebSocket client on
    ///   - logger: Logger
    public convenience init(
        _ address: ValkeyServerAddress,
        configuration: ValkeyClientConfiguration = .init(),
        eventLoopGroup: any EventLoopGroup = MultiThreadedEventLoopGroup.singleton,
        logger: Logger
    ) {
        self.init(
            address,
            connectionIDGenerator: ConnectionIDGenerator(),
            connectionFactory: ValkeyConnectionFactory(configuration: configuration),
            eventLoopGroup: eventLoopGroup,
            logger: logger
        )
    }

    package init(
        _ address: ValkeyServerAddress,
        connectionIDGenerator: ConnectionIDGenerator,
        connectionFactory: ValkeyConnectionFactory,
        eventLoopGroup: any EventLoopGroup,
        logger: Logger
    ) {
        self.nodeClientFactory = ValkeyNodeClientFactory(
            logger: logger,
            configuration: connectionFactory.configuration,
            connectionFactory: ValkeyConnectionFactory(
                configuration: connectionFactory.configuration,
                customHandler: nil
            ),
            eventLoopGroup: eventLoopGroup
        )
        self.eventLoopGroup = eventLoopGroup
        self.logger = logger
        self.runningAtomic = .init(false)
        self.node = self.nodeClientFactory.makeConnectionPool(nodeDescription: .init(address: address, readOnly: false))
        (self.actionStream, self.actionStreamContinuation) = AsyncStream.makeStream(of: RunAction.self)
        self.queueAction(.runNodeClient(self.node))
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyClient {
    /// Run ValkeyClient connection pool
    public func run() async {
        let atomicOp = self.runningAtomic.compareExchange(expected: false, desired: true, ordering: .relaxed)
        precondition(!atomicOp.original, "ValkeyClient.run() should just be called once!")
        #if ServiceLifecycleSupport
        await cancelWhenGracefulShutdown {
            await self._withTaskGroup()
        }
        #else
        await self._withTaskGroup()
        #endif
    }

    private func _withTaskGroup() async {
        /// Run discarding task group running actions
        await withDiscardingTaskGroup { group in
            for await action in self.actionStream {
                group.addTask {
                    await self.runAction(action)
                }
            }
        }
    }

    /// Get connection from connection pool and run operation using connection
    ///
    /// - Parameters:
    ///   - isolation: Actor isolation
    ///   - operation: Closure handling Valkey connection
    /// - Returns: Value returned by closure
    @inlinable
    public func withConnection<Value>(
        isolation: isolated (any Actor)? = #isolation,
        operation: (ValkeyConnection) async throws -> sending Value
    ) async throws -> Value {
        try await self.node.withConnection(isolation: isolation, operation: operation)
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyClient {
    func queueAction(_ action: RunAction) {
        self.actionStreamContinuation.yield(action)
    }

    private func runAction(_ action: RunAction) async {
        switch action {
        case .runNodeClient(let nodeClient):
            await nodeClient.run()
        }
    }
}

/// Extend ValkeyClient so we can call commands directly from it
@available(valkeySwift 1.0, *)
extension ValkeyClient: ValkeyClientProtocol {
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
extension ValkeyClient {
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
    ) async -> sending (repeat Result<(each Command).Response, any Error>) {
        await node.execute(repeat each commands)
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
    ) async -> [Result<RESPToken, any Error>] where Commands.Element == any ValkeyCommand {
        await node.execute(commands)
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
    public func transaction<each Command: ValkeyCommand>(
        _ commands: repeat each Command
    ) async throws -> sending (repeat Result<(each Command).Response, Error>) {
        try await node.transaction(repeat each commands)
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
    /// This is an alternative version of the transaction function ``ValkeyClient/transaction(_:)->(_,_)``
    /// that allows for a collection of ValkeyCommands. It provides more flexibility but the command
    /// responses are returned as ``RESPToken`` instead of the response type for the command.
    ///
    /// - Parameter commands: Collection of ValkeyCommands
    /// - Returns: Array holding the RESPToken responses of all the commands
    @inlinable
    public func transaction<Commands: Collection & Sendable>(
        _ commands: Commands
    ) async throws -> [Result<RESPToken, Error>] where Commands.Element == any ValkeyCommand {
        try await node.transaction(commands)
    }
}

#if ServiceLifecycleSupport
@available(valkeySwift 1.0, *)
extension ValkeyClient: Service {}
#endif  // ServiceLifecycle
