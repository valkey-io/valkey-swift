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
    @usableFromInline
    typealias ConnectionStateMachine =
        SubscriptionConnectionStateMachine<
            ValkeyConnection,
            CheckedContinuation<ValkeyConnection, Error>,
            CheckedContinuation<Void, Never>
        >

    let nodeClientFactory: ValkeyNodeClientFactory
    /// single node
    @usableFromInline
    let stateMachine: Mutex<ValkeyClientStateMachine<ValkeyNodeClient, ValkeyNodeClientFactory>>
    /// configuration
    var configuration: ValkeyClientConfiguration { self.nodeClientFactory.configuration }
    /// EventLoopGroup to use
    let eventLoopGroup: any EventLoopGroup
    /// Logger
    let logger: Logger
    /// running atomic
    let runningAtomic: Atomic<Bool>
    /// subscription connection state
    @usableFromInline
    let subscriptionConnectionStateMachine: Mutex<ConnectionStateMachine>
    @usableFromInline
    let subscriptionConnectionIDGenerator: ConnectionIDGenerator

    enum RunAction: Sendable {
        case runNodeClient(ValkeyNodeClient)
        case leaseSubscriptionConnection(leaseID: Int)
        case runRole(ValkeyNodeClient)
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
        eventLoopGroup: EventLoopGroup,
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
        self.stateMachine = .init(.init(poolFactory: self.nodeClientFactory))
        self.subscriptionConnectionStateMachine = .init(.init())
        self.subscriptionConnectionIDGenerator = .init()
        (self.actionStream, self.actionStreamContinuation) = AsyncStream.makeStream(of: RunAction.self)
        switch address.value {
        case .hostname(let host, let port):
            let action = self.stateMachine.withLock { $0.setPrimary(nodeID: .init(endpoint: host, port: port)) }
            switch action {
            case .runNodeAndFindReplicas(let client):
                self.queueAction(.runNodeClient(client))
                self.queueAction(.runRole(client))
            case .findReplicas, .doNothing:
                preconditionFailure("First time you call setPrimary it should always return runNodeAndFindReplicas")
            }
        }
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
        readOnly: Bool = false,
        operation: (ValkeyConnection) async throws -> sending Value
    ) async throws -> Value {
        let node = self.stateMachine.withLock { $0.getNode(readOnly: readOnly) }
        return try await node.withConnection(isolation: isolation, operation: operation)
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

        case .runRole(let nodeClient):
            var replicas: [ValkeyNodeID] = []
            if let role = try? await nodeClient.execute(ROLE()) {
                switch role {
                case .primary(let primary):
                    replicas = primary.replicas.map { .init(endpoint: $0.ip, port: $0.port) }
                case .replica:
                    break
                case .sentinel:
                    preconditionFailure("Valkey-swift does not support sentinel at this point in time.")
                }
            }
            let action = self.stateMachine.withLock { $0.addReplicas(nodeIDs: replicas) }
            for node in action.clientsToRun {
                self.queueAction(.runNodeClient(node))
            }
            for node in action.clientsToShutdown {
                node.triggerGracefulShutdown()
            }
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
        try await self.withConnection(readOnly: false) { connection in
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
    ) async -> sending (repeat Result<(each Command).Response, Error>) {
        do {
            return try await self.withConnection { connection in
                await connection.execute(repeat (each commands))
            }
        } catch {
            return (repeat Result<(each Command).Response, Error>.failure(error))
        }
    }
}

#if ServiceLifecycleSupport
@available(valkeySwift 1.0, *)
extension ValkeyClient: Service {}
#endif  // ServiceLifecycle
