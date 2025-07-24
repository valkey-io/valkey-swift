//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey project
//
// Copyright (c) 2025 the swift-valkey authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See swift-valkey/CONTRIBUTORS.txt for the list of swift-valkey authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Logging
import NIOCore
import NIOPosix
import NIOSSL
import Synchronization

/// A client for interacting with a Valkey cluster.
///
/// `ValkeyClusterClient` provides a high-level interface for communicating with a Valkey cluster.
/// It handles cluster topology discovery, command routing, and automatic connection management
/// across multiple Valkey server nodes.
///
/// The client supports:
/// - Automatic cluster topology discovery and maintenance.
/// - Command routing to the appropriate node based on key hash slots.
/// - Handling of MOVED responses for proper cluster resharding.
/// - Connection pooling and failover.
/// - Circuit breaking during cluster disruptions.
///
/// Example usage:
/// ```swift
/// let discovery = StaticValkeyNodeDiscovery(nodes: [
///     ValkeyNodeEndpoint(host: "valkey1.example.com", port: 6379),
///     ValkeyNodeEndpoint(host: "valkey2.example.com", port: 6379)
/// ])
///
/// let config = ValkeyClientConfiguration(
///     connectionTimeout: .seconds(5),
///     readTimeout: .seconds(2)
/// )
///
/// let client = ValkeyClusterClient(
///     clientConfiguration: config,
///     nodeDiscovery: discovery,
///     logger: logger
/// )
///
/// try await withThrowingTaskGroup(of: Void.self) { group in
///     group.addTask {
///         await client.run()
///     }
///
///     // use the client here
///     let foo = try await client.get(key: "foo")
/// }
/// ```
@available(valkeySwift 1.0, *)
public final class ValkeyClusterClient: Sendable {
    private let nodeDiscovery: any ValkeyNodeDiscovery

    @usableFromInline
    typealias StateMachine = ValkeyClusterClientStateMachine<
        ValkeyClient,
        ValkeyClientFactory,
        ContinuousClock,
        CheckedContinuation<Void, any Error>,
        AsyncStream<Void>.Continuation
    >

    @usableFromInline
    /* private */ let logger: Logger
    @usableFromInline
    /* private */ let clock = ContinuousClock()
    @usableFromInline
    /* private */ let stateLock: Mutex<StateMachine>
    @usableFromInline
    /* private */ let nextRequestIDGenerator = Atomic(0)

    private enum RunAction {
        case runClusterDiscovery(runNodeDiscovery: Bool)
        case runClient(ValkeyClient)
        case runTimer(ValkeyClusterTimer)
    }

    private let actionStream: AsyncStream<RunAction>
    private let actionStreamContinuation: AsyncStream<RunAction>.Continuation

    /// Creates a new ``ValkeyClusterClient`` instance.
    ///
    /// This client only becomes usable once ``run()`` has been invoked.
    ///
    /// - Parameters:
    ///   - clientConfiguration: Configuration for the underlying Valkey client connections.
    ///   - nodeDiscovery: A ``ValkeyNodeDiscovery`` service that discovers Valkey nodes for the client in the cluster.
    ///   - eventLoopGroup: The event loop group used for handling connections. Defaults to the global singleton.
    ///   - logger: A logger for recording internal events and diagnostic information.
    ///   - connectionFactory: An overwrite to provide create your own underlying `Channel`s. Use this to wrap connections
    ///                        in other NIO protocols (like SSH).
    public init(
        clientConfiguration: ValkeyClientConfiguration,
        nodeDiscovery: some ValkeyNodeDiscovery,
        eventLoopGroup: EventLoopGroup = MultiThreadedEventLoopGroup.singleton,
        logger: Logger,
        connectionFactory: (@Sendable (ValkeyServerAddress, any EventLoop) async throws -> any Channel)? = nil
    ) {
        self.logger = logger

        let (stream, continuation) = AsyncStream.makeStream(of: RunAction.self)
        self.actionStream = stream
        self.actionStreamContinuation = continuation

        let factory = ValkeyClientFactory(
            logger: logger,
            configuration: clientConfiguration,
            connectionFactory: ValkeyConnectionFactory(
                configuration: clientConfiguration,
                customHandler: connectionFactory
            ),
            eventLoopGroup: eventLoopGroup
        )

        let stateMachine = StateMachine(
            configuration: .init(
                circuitBreakerDuration: .seconds(30),
                defaultClusterRefreshInterval: .seconds(30)
            ),
            poolFactory: factory,
            clock: self.clock
        )
        self.stateLock = Mutex(stateMachine)
        self.nodeDiscovery = nodeDiscovery
    }

    // MARK: - Public methods -

    /// Sends a command to the appropriate node in the Valkey cluster and returns the response.
    ///
    /// This method automatically:
    /// - Determines the correct node based on the keys affected by the command
    /// - Handles MOVED redirections if the cluster topology has changed
    /// - Retries commands when appropriate
    ///
    /// - Parameter command: The command to send to the cluster.
    /// - Returns: The response from the command, properly parsed into the expected response type.
    /// - Throws:
    ///   - `ValkeyClusterError.clusterIsUnavailable` if no healthy nodes are available
    ///   - `ValkeyClusterError.clientRequestCancelled` if the request is cancelled
    ///   - Other errors if the command execution or parsing fails
    @inlinable
    public func send<Command: ValkeyCommand>(command: Command) async throws -> Command.Response {
        let hashSlots = command.keysAffected.map { HashSlot(key: $0) }
        var clientSelector: () async throws -> ValkeyClient = {
            try await self.client(for: hashSlots)
        }

        while !Task.isCancelled {
            do {
                let client = try await clientSelector()
                return try await client.send(command: command)
            } catch ValkeyClusterError.noNodeToTalkTo {
                // TODO: Rerun node discovery!
            } catch let error as ValkeyClientError where error.errorCode == .commandError {
                guard let errorMessage = error.message, let movedError = ValkeyMovedError(errorMessage) else {
                    throw error
                }
                self.logger.trace("Received move error", metadata: ["error": "\(movedError)"])
                clientSelector = { try await self.client(for: movedError) }
            }
        }
        throw CancellationError()
    }

    /// Get connection from cluster and run operation using connection
    ///
    /// - Parameters:
    ///   - keys: Keys affected by operation. This is used to choose the cluster node
    ///   - isolation: Actor isolation
    ///   - operation: Closure handling Valkey connection
    /// - Returns: Value returned by closure
    @inlinable
    public func withConnection<Value>(
        forKeys keys: some Collection<ValkeyKey>,
        isolation: isolated (any Actor)? = #isolation,
        operation: (ValkeyConnection) async throws -> sending Value
    ) async throws -> Value {
        let hashSlots = keys.map { HashSlot(key: $0) }
        let client = try await self.client(for: hashSlots)
        return try await client.withConnection(isolation: isolation, operation: operation)
    }

    /// Starts running the cluster client.
    ///
    /// This method initiates:
    /// - Cluster topology discovery
    /// - Connection management to all relevant nodes
    /// - Health check scheduling
    /// - Automatic circuit breaker functions
    ///
    /// The client runs continuously until the task is cancelled. It is recommended to run this method
    /// in a separate task that lives for the duration of your application's lifecycle.
    ///
    /// Example:
    /// ```swift
    /// let client = ValkeyClusterClient(...)
    /// try await withThrowingTaskGroup(of: Void.self) { group in
    ///     group.addTask {
    ///         await client.run()
    ///     }
    ///
    ///     // use the client here
    ///     let foo = try await client.get(key: "foo")
    /// }
    /// ```
    ///
    /// - Important: This method must be called before sending any commands using this client.
    public func run() async {
        let circuitBreakerTimer = self.stateLock.withLock { $0.start() }

        self.actionStreamContinuation.yield(.runTimer(circuitBreakerTimer))
        self.actionStreamContinuation.yield(.runClusterDiscovery(runNodeDiscovery: true))

        await withTaskCancellationHandler {
            await withDiscardingTaskGroup { taskGroup in
                await self.runUsingTaskGroup(&taskGroup)
            }
        } onCancel: {
            _ = self.stateLock.withLock {
                $0.shutdown()
            }

            // TODO: All the pools shutdown automatically because of task cancellation propagation
        }
    }

    // MARK: - Private methods -

    /// Manages the primary task group that handles all client operations.
    ///
    /// - Parameter taskGroup: The task group to add tasks to.
    private func runUsingTaskGroup(_ taskGroup: inout DiscardingTaskGroup) async {
        for await action in self.actionStream {
            switch action {
            case .runClusterDiscovery(let runNodeDiscovery):
                taskGroup.addTask {
                    await self.runClusterDiscovery(runNodeDiscoveryFirst: runNodeDiscovery)
                }

            case .runClient(let client):
                taskGroup.addTask {
                    await client.run()
                }

            case .runTimer(let timer):
                taskGroup.addTask {
                    await withTaskGroup(of: Void.self) { taskGroup in
                        taskGroup.addTask {
                            do {
                                try await self.clock.sleep(for: timer.duration)
                                // timer has hit
                                let timerFiredAction = self.stateLock.withLock {
                                    $0.timerFired(timer)
                                }
                                self.runTimerFiredAction(timerFiredAction)
                            } catch {
                                // do nothing
                            }
                        }

                        let (stream, continuation) = AsyncStream.makeStream(of: Void.self)
                        taskGroup.addTask {
                            var iterator = stream.makeAsyncIterator()
                            await iterator.next()
                        }

                        let token = self.stateLock.withLock {
                            $0.registerTimerCancellationToken(continuation, for: timer)
                        }

                        token?.finish()
                    }
                }
            }
        }
    }

    // MARK: Run StateMachine actions

    /// Handles timer fired actions from the state machine.
    ///
    /// - Parameter action: The action to execute after a timer fires.
    private func runTimerFiredAction(_ action: StateMachine.TimerFiredAction) {
        if let failWaiters = action.failWaiters {
            for waiter in failWaiters.waitersToFail {
                waiter.resume(throwing: failWaiters.error)
            }
        }

        if let runDiscovery = action.runDiscovery {
            self.actionStreamContinuation.yield(.runClusterDiscovery(runNodeDiscovery: runDiscovery.runNodeDiscoveryFirst))
        }
    }

    /// Handles actions related to Valkey node updates.
    ///
    /// - Parameter action: The update action containing clients to run and shut down.
    private func runUpdateValkeyNodesAction(_ action: StateMachine.UpdateValkeyNodesAction) {
        for client in action.clientsToRun {
            self.actionStreamContinuation.yield(.runClient(client))
        }

        for client in action.clientsToShutdown {
            client.triggerGracefulShutdown()
        }
    }

    /// Processes actions after successful cluster discovery.
    ///
    /// - Parameter action: The action containing operations to perform after successful discovery.
    private func runClusterDiscoverySucceededAction(_ action: StateMachine.ClusterDiscoverySucceededAction) {
        for waiter in action.waitersToSucceed {
            waiter.resume()
        }

        action.cancelTimer?.yield()

        if let newTimer = action.createTimer {
            self.actionStreamContinuation.yield(.runTimer(newTimer))
        }

        for client in action.clientsToRun {
            self.actionStreamContinuation.yield(.runClient(client))
        }

        for client in action.clientsToShutdown {
            client.triggerGracefulShutdown()
        }
    }

    /// Processes actions after failed cluster discovery.
    ///
    /// - Parameter action: The action containing operations to perform after failed discovery.
    private func runClusterDiscoveryFailedAction(_ action: StateMachine.ClusterDiscoveryFailedAction) {
        if let retryTimer = action.retryTimer {
            self.actionStreamContinuation.yield(.runTimer(retryTimer))
        }

        if let circuitBreakerTimer = action.circuitBreakerTimer {
            self.actionStreamContinuation.yield(.runTimer(circuitBreakerTimer))
        }
    }

    // MARK: Obtaining a client

    /// Retrieves a client for the node that handles the specified MOVED error.
    ///
    /// This internal method is used when handling cluster topology changes indicated by
    /// MOVED responses from Valkey nodes.
    ///
    /// - Parameter moveError: The MOVED error response from a Valkey node.
    /// - Returns: A client connected to the node that can handle the request.
    /// - Throws:
    ///   - `ValkeyClusterError.waitedForDiscoveryAfterMovedErrorThreeTimes` if unable to resolve
    ///     the MOVED error after multiple attempts
    ///   - `ValkeyClusterError.clientRequestCancelled` if the request is cancelled
    @usableFromInline
    /* private */ func client(for moveError: ValkeyMovedError) async throws -> ValkeyClient {
        var counter = 0
        while counter < 3 {
            defer { counter += 1 }
            let action = try self.stateLock.withLock { stateMachine throws(ValkeyClusterError) -> StateMachine.PoolForMovedErrorAction in
                try stateMachine.poolFastPath(for: moveError)
            }

            switch action {
            case .connectionPool(let client):
                return client

            case .waitForDiscovery:
                break

            case .moveToDegraded(let action):
                self.runMovedToDegraded(action)
            }

            let waiterID = self.nextRequestID()
            try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                    let action = self.stateLock.withLock { stateMachine in
                        stateMachine.waitForHealthy(waiterID: waiterID, successNotifier: continuation)
                    }

                    switch action {
                    case .fail(let error, let continuation):
                        continuation.resume(throwing: error)
                    case .succeed(let continuation):
                        continuation.resume()
                    case .none:
                        break
                    }
                }
            } onCancel: {
                let continuation = self.stateLock.withLock { stateMachine in
                    stateMachine.cancelWaitingForHealthy(id: waiterID)
                }

                continuation?.resume(throwing: ValkeyClusterError.clientRequestCancelled)
            }
        }

        throw ValkeyClusterError.waitedForDiscoveryAfterMovedErrorThreeTimes
    }

    /// Retrieves a client for communicating with nodes that manage the given hash slots.
    ///
    /// This is a lower-level method that can be used when you need direct access to a
    /// specific `ValkeyClient` instance for nodes managing particular hash slots. Most users
    /// should prefer the higher-level `send(command:)` method.
    ///
    /// - Parameter slots: The collection of hash slots to determine which node to connect to.
    /// - Returns: A `ValkeyClient` instance connected to the appropriate node.
    /// - Throws:
    ///   - `ValkeyClusterError.clusterIsUnavailable` if no healthy nodes are available
    ///   - `ValkeyClusterError.clusterIsMissingSlotAssignment` if the slot assignment cannot be determined
    @inlinable
    func client(for slots: some (Collection<HashSlot> & Sendable)) async throws -> ValkeyClient {
        var retries = 0
        while retries < 3 {
            defer { retries += 1 }

            do {
                return try self.stateLock.withLock { state -> ValkeyClient in
                    try state.poolFastPath(for: slots)
                }
            } catch ValkeyClusterError.clusterIsUnavailable {
                let waiterID = self.nextRequestID()

                try await withTaskCancellationHandler {
                    try await withCheckedThrowingContinuation {
                        (continuation: CheckedContinuation<Void, any Error>) in

                        let action = self.stateLock.withLock {
                            $0.waitForHealthy(waiterID: waiterID, successNotifier: continuation)
                        }

                        switch action {
                        case .succeed(let continuation):
                            continuation.resume()

                        case .fail(let error, let continuation):
                            continuation.resume(throwing: error)

                        case .none:
                            break
                        }
                    }
                } onCancel: {
                    let continuation = self.stateLock.withLock {
                        $0.cancelWaitingForHealthy(id: waiterID)
                    }

                    continuation?.resume(throwing: CancellationError())
                }

                // Consensus was reached. Let's loop again!
                continue
            }
        }

        throw ValkeyClusterError.clusterIsMissingSlotAssignment
    }

    /// Generates a new unique request ID for tracking internal operations.
    ///
    /// - Returns: A unique integer ID for tracking requests and waiters.
    @inlinable
    /* private */ func nextRequestID() -> Int {
        self.nextRequestIDGenerator.wrappingAdd(1, ordering: .relaxed).oldValue
    }

    // MARK: Cluster discovery

    /// Handles the transition to a degraded state when a moved error is received.
    ///
    /// - Parameter action: The action containing operations for degraded mode.
    private func runMovedToDegraded(_ action: StateMachine.PoolForMovedErrorAction.MoveToDegraded) {
        if let cancelToken = action.runDiscoveryAndCancelTimer {
            cancelToken.yield()
            self.actionStreamContinuation.yield(.runClusterDiscovery(runNodeDiscovery: false))
        }

        self.actionStreamContinuation.yield(.runTimer(action.circuitBreakerTimer))
    }

    /// Runs the cluster discovery process to determine the current cluster topology.
    ///
    /// This method handles:
    /// 1. Optionally running node discovery first to find available nodes
    /// 2. Querying discovered nodes for cluster topology information
    /// 3. Establishing consensus on the cluster topology
    /// 4. Updating the client's internal state with the discovered topology
    ///
    /// - Parameter runNodeDiscoveryFirst: Whether to run node discovery before querying for cluster topology.
    private func runClusterDiscovery(runNodeDiscoveryFirst: Bool) async {
        do {
            let voters =
                if runNodeDiscoveryFirst {
                    try await self.runNodeDiscovery()
                } else {
                    self.stateLock.withLock {
                        $0.getInitialVoters()
                    }
                }

            let clusterDescription = try await self.runClusterDiscoveryFindingConsensus(voters: voters)
            let action = self.stateLock.withLock {
                $0.valkeyClusterDiscoverySucceeded(clusterDescription)
            }

            self.runClusterDiscoverySucceededAction(action)
        } catch {
            self.logger.debug(
                "Valkey cluster discovery failed",
                metadata: [
                    "error": "\(error)"
                ]
            )
            let action = self.stateLock.withLock {
                $0.valkeyClusterDiscoveryFailed(error)
            }
            self.runClusterDiscoveryFailedAction(action)
        }
    }

    /// Discovers available Valkey nodes using the configured ``ValkeyNodeDiscovery`` service.
    ///
    /// - Returns: A list of voters that can participate in cluster topology election.
    /// - Throws: Any error encountered during node discovery.
    private func runNodeDiscovery() async throws -> [ValkeyClusterVoter<ValkeyClient>] {
        do {
            self.logger.trace("Running node discovery")
            let nodes = try await self.nodeDiscovery.lookupNodes()
            let mapped = nodes.map {
                ValkeyNodeDescription(description: $0 as! any ValkeyNodeDescriptionProtocol)
            }
            let actions = self.stateLock.withLock {
                $0.updateValkeyServiceNodes(mapped)
            }
            self.logger.debug(
                "Discovered nodes",
                metadata: [
                    "node_count": "\(nodes.count)"
                ]
            )
            self.runUpdateValkeyNodesAction(actions)
            return actions.voters
        } catch {
            self.logger.debug(
                "Failed to discover nodes",
                metadata: [
                    "error": "\(error)"
                ]
            )
            throw error
        }
    }

    /// Establishes consensus on the cluster topology by querying multiple nodes.
    ///
    /// This method uses a voting mechanism to establish consensus among multiple nodes
    /// about the current cluster topology. It requires a quorum of nodes to agree
    /// on the topology before accepting it.
    ///
    /// - Parameter voters: The list of nodes that can vote on cluster topology.
    /// - Returns: The agreed-upon cluster description.
    /// - Throws: `ValkeyClusterError.clusterIsUnavailable` if consensus cannot be reached.
    private func runClusterDiscoveryFindingConsensus(voters: [ValkeyClusterVoter<ValkeyClient>]) async throws -> ValkeyClusterDescription {
        try await withThrowingTaskGroup(of: (ValkeyClusterDescription, ValkeyNodeID).self) { taskGroup in
            for voter in voters {
                taskGroup.addTask {
                    (try await voter.client.clusterShards(), voter.nodeID)
                }
            }

            var election = ValkeyTopologyElection()

            while let result = await taskGroup.nextResult() {
                switch result {
                case .success((let description, let nodeID)):

                    do {
                        let metrics = try election.voteReceived(for: description, from: nodeID)

                        self.logger.debug(
                            "Vote received",
                            metadata: [
                                "candidate_count": "\(metrics.candidateCount)",
                                "candidate": "\(metrics.candidate)",
                                "votes_received": "\(metrics.votesReceived)",
                                "votes_needed": "\(metrics.votesNeeded)",
                            ]
                        )
                    } catch let error as ValkeyClusterError {
                        self.logger.debug(
                            "Vote invalid",
                            metadata: [
                                "nodeID": "\(nodeID)",
                                "error": "\(error)",
                            ]
                        )
                        continue
                    }

                    if let electionWinner = election.winner {
                        taskGroup.cancelAll()
                        return electionWinner
                    }

                    // ensure that we have pools for all returned nodes so that we can reach consensus
                    let actions = self.stateLock.withLock { $0.updateValkeyServiceNodes(description) }
                    self.runUpdateValkeyNodesAction(actions)

                    for voter in actions.voters {
                        taskGroup.addTask {
                            (try await voter.client.clusterShards(), voter.nodeID)
                        }
                    }

                case .failure(let error):
                    self.logger.debug(
                        "Received an error while asking for cluster topology",
                        metadata: [
                            "error": "\(error)"
                        ]
                    )
                }
            }

            // no consensus reached
            throw ValkeyClusterError.clusterIsUnavailable
        }
    }
}

/// Extension that makes `ValkeyClusterClient` conform to `ValkeyConnectionProtocol`.
///
/// This allows the cluster client to be used anywhere a `ValkeyConnectionProtocol` is expected.
@available(valkeySwift 1.0, *)
extension ValkeyClusterClient: ValkeyConnectionProtocol {}

/// Extension that makes ``ValkeyClient`` conform to ``ValkeyNodeConnectionPool``.
///
/// This enables the ``ValkeyClusterClient`` to manage individual ``ValkeyClient`` instances.
@available(valkeySwift 1.0, *)
extension ValkeyClient: ValkeyNodeConnectionPool {
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

/// A factory for creating ``ValkeyClient`` instances to connect to specific nodes.
///
/// This factory is used by the ``ValkeyClusterClient`` to create client instances
/// for each node in the cluster as needed.
@available(valkeySwift 1.0, *)
@usableFromInline
package struct ValkeyClientFactory: ValkeyNodeConnectionPoolFactory {
    @usableFromInline
    package typealias ConnectionPool = ValkeyClient

    var logger: Logger
    var configuration: ValkeyClientConfiguration
    var eventLoopGroup: any EventLoopGroup
    let connectionIDGenerator = ConnectionIDGenerator()
    let connectionFactory: ValkeyConnectionFactory

    /// Creates a new `ValkeyClientFactory` instance.
    ///
    /// - Parameters:
    ///   - logger: The logger used for diagnostic information.
    ///   - configuration: Configuration for the Valkey clients created by this factory.
    ///   - eventLoopGroup: The event loop group to use for client connections.
    package init(
        logger: Logger,
        configuration: ValkeyClientConfiguration,
        connectionFactory: ValkeyConnectionFactory,
        eventLoopGroup: any EventLoopGroup
    ) {
        self.logger = logger
        self.configuration = configuration
        self.connectionFactory = connectionFactory
        self.eventLoopGroup = eventLoopGroup
    }

    /// Creates a connection pool (client) for a specific node in the cluster.
    ///
    /// - Parameter nodeDescription: Description of the node to connect to.
    /// - Returns: A configured `ValkeyClient` instance ready to connect to the specified node.
    @usableFromInline
    package func makeConnectionPool(nodeDescription: ValkeyNodeDescription) -> ValkeyClient {
        let serverAddress = ValkeyServerAddress.hostname(
            nodeDescription.endpoint,
            port: nodeDescription.port
        )

        var clientConfiguration = self.configuration
        if !nodeDescription.useTLS {
            // TODO: Should this throw? What about the other way around?
            clientConfiguration.tls = .disable
        }

        return ValkeyClient(
            serverAddress,
            connectionIDGenerator: self.connectionIDGenerator,
            connectionFactory: self.connectionFactory,
            eventLoopGroup: self.eventLoopGroup,
            logger: self.logger
        )
    }
}
