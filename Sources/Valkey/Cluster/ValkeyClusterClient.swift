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
        ValkeyNodeClient,
        ValkeyNodeClientFactory,
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
    @usableFromInline
    /* private */ let clientConfiguration: ValkeyClientConfiguration

    private enum RunAction {
        case runClusterDiscovery(runNodeDiscovery: Bool)
        case runClient(ValkeyNodeClient)
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
    ///   - channelFactory: An overwrite to provide create your own underlying `Channel`s. Use this to wrap connections
    ///                     in other NIO protocols (like SSH).
    public init(
        clientConfiguration: ValkeyClientConfiguration,
        nodeDiscovery: some ValkeyNodeDiscovery,
        eventLoopGroup: any EventLoopGroup = MultiThreadedEventLoopGroup.singleton,
        logger: Logger,
        channelFactory: (@Sendable (ValkeyServerAddress, any EventLoop) async throws -> any Channel)? = nil
    ) {
        self.logger = logger
        self.clientConfiguration = clientConfiguration

        (self.actionStream, self.actionStreamContinuation) = AsyncStream.makeStream(of: RunAction.self)

        let factory = ValkeyNodeClientFactory(
            logger: logger,
            configuration: clientConfiguration,
            connectionFactory: ValkeyConnectionFactory(
                configuration: clientConfiguration,
                customHandler: channelFactory
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
    public func execute<Command: ValkeyCommand>(_ command: Command) async throws -> Command.Response {
        let hashSlot = try self.hashSlot(for: command.keysAffected)
        var clientSelector: () async throws -> ValkeyNodeClient = {
            try await self.nodeClient(for: hashSlot.map { [$0] } ?? [])
        }

        var asking = false
        var attempt = 0
        while !Task.isCancelled {
            do {
                let client = try await clientSelector()
                if asking {
                    asking = false
                    // if asking we need to call ASKING beforehand otherwise we will get a MOVE error
                    return try await client.execute(
                        ASKING(),
                        command
                    ).1.get()
                } else {
                    return try await client.execute(command)
                }
            } catch let error as ValkeyClusterError where error == .noNodeToTalkTo {
                // TODO: Rerun node discovery!
            } catch {
                let retryAction = self.getRetryAction(from: error)
                switch retryAction {
                case .redirect(let redirectError):
                    clientSelector = { try await self.nodeClient(for: redirectError) }
                    asking = (redirectError.redirection == .ask)
                case .tryAgain:
                    let wait = self.clientConfiguration.retryParameters.calculateWaitTime(retry: attempt)
                    try await Task.sleep(for: wait)
                    attempt += 1
                case .dontRetry:
                    throw error
                }
            }
        }
        throw ValkeyClusterError.clientRequestCancelled
    }

    /// Pipeline a series of commands to nodes in the Valkey cluster
    ///
    /// This function splits up the array of commands into smaller arrays containing
    /// the commands that should be run on each node in the cluster. It then runs a
    /// pipelined execute using these smaller arrays on each node concurrently.
    ///
    /// Once all the responses for the commands have been received the function converys
    /// them to their expected Response type.
    ///
    /// Because the commands are split across nodes it is not possible to guarantee
    /// the order that commands will run in. The only way to guarantee the order is to
    /// only pipeline commands that use keys from the same HashSlot. If a key has a
    /// substring between brackets `{}` then that substring is used to calculate the
    /// HashSlot. That substring is called the hash tag. Using this you can ensure two
    /// keys are in the same hash slot, by giving them the same hash tag eg `user:{123}`
    /// and `profile:{123}`.
    ///
    /// - Parameter commands: Parameter pack of ValkeyCommands
    /// - Returns: Parameter pack holding the responses of all the commands
    @inlinable
    public func execute<each Command: ValkeyCommand>(
        _ commands: repeat each Command
    ) async -> sending (repeat Result<(each Command).Response, any Error>) {
        func convert<Response: RESPTokenDecodable>(_ result: Result<RESPToken, any Error>, to: Response.Type) -> Result<Response, any Error> {
            result.flatMap {
                do {
                    return try .success(Response(fromRESP: $0))
                } catch {
                    return .failure(error)
                }
            }
        }
        let results = await self.execute([any ValkeyCommand](commands: repeat each commands))
        var index = AutoIncrementingInteger()
        return (repeat convert(results[index.next()], to: (each Command).Response.self))
    }

    /// Results from pipeline and index for each result
    @usableFromInline
    struct NodePipelineResult: Sendable {
        @usableFromInline
        let indices: [[any ValkeyCommand].Index]
        @usableFromInline
        let results: [Result<RESPToken, any Error>]

        @inlinable
        init(indices: [[any ValkeyCommand].Index], results: [Result<RESPToken, any Error>]) {
            self.indices = indices
            self.results = results
        }
    }

    /// Pipeline a series of commands to nodes in the Valkey cluster
    ///
    /// This function splits up the array of commands into smaller arrays containing
    /// the commands that should be run on each node in the cluster. It then runs a
    /// pipelined execute using these smaller arrays on each node concurrently.
    ///
    /// Once all the responses for the commands have been received the function returns
    /// an array of RESPToken Results, one for each command.
    ///
    /// Because the commands are split across nodes it is not possible to guarantee
    /// the order that commands will run in. The only way to guarantee the order is to
    /// only pipeline commands that use keys from the same HashSlot. If a key has a
    /// substring between brackets `{}` then that substring is used to calculate the
    /// HashSlot. That substring is called the hash tag. Using this you can ensure two
    /// keys are in the same hash slot, by giving them the same hash tag eg `user:{123}`
    /// and `profile:{123}`.
    ///
    /// - Parameter commands: Parameter pack of ValkeyCommands
    /// - Returns: Array holding the RESPToken responses of all the commands
    @inlinable
    public func execute(
        _ commands: [any ValkeyCommand]
    ) async -> sending [Result<RESPToken, any Error>] {
        guard commands.count > 0 else { return [] }
        // get a list of nodes and the commands that should be run on them
        do {
            let nodes = try await self.splitCommandsAcrossNodes(commands: commands)
            // if this list has one element, then just run the pipeline on that single node
            if nodes.count == 1 {
                do {
                    return try await self.execute(node: nodes[nodes.startIndex].node, commands: commands)
                } catch {
                    return .init(repeating: .failure(error), count: commands.count)
                }
            }
            return await withTaskGroup(of: NodePipelineResult.self) { group in
                // run generated pipelines concurrently
                for node in nodes {
                    let indices = node.commandIndices
                    group.addTask {
                        do {
                            let results = try await self.execute(node: node.node, commands: IndexedSubCollection(commands, indices: indices))
                            return .init(indices: indices, results: results)
                        } catch {
                            return NodePipelineResult(indices: indices, results: .init(repeating: .failure(error), count: indices.count))
                        }
                    }
                }
                var results = [Result<RESPToken, any Error>](repeating: .failure(ValkeyClusterError.pipelinedResultNotReturned), count: commands.count)
                // get results for each node
                while let taskResult = await group.next() {
                    precondition(taskResult.indices.count == taskResult.results.count)
                    for index in 0..<taskResult.indices.count {
                        results[taskResult.indices[index]] = taskResult.results[index]
                    }
                }
                return results
            }
        } catch {
            return .init(repeating: .failure(error), count: commands.count)
        }
    }

    struct Redirection {
        let node: ValkeyNodeClient
        let ask: Bool
    }
    /// Pipeline a series of commands to a single node in the Valkey cluster
    ///
    /// This function supports retrying commands that return cluster specific
    /// errors like MOVED, TRYAGAIN and ASK
    ///
    /// Once all the responses for the commands have been received the function returns
    /// an array of RESPToken Results, one for each command.
    ///
    /// - Parameter commands: Parameter pack of ValkeyCommands
    /// - Returns: Array holding the RESPToken responses of all the commands
    @usableFromInline
    func execute<Commands: Collection & Sendable>(
        node: ValkeyNodeClient,
        commands: Commands
    ) async throws -> sending [Result<RESPToken, any Error>] where Commands.Element == any ValkeyCommand, Commands.Index == Int {
        // execute pipeline
        var results = await node.execute(commands)
        var retryCommands: [(any ValkeyCommand, Int)] = []
        var attempt = 1
        while !Task.isCancelled {
            var node = node
            var redirection: Redirection? = nil
            // check if any results require the command to be retried
            for result in results.enumerated() {
                switch result.element {
                case .failure(let error):
                    // get retry action for command
                    let commandRetryAction = self.getRetryAction(from: error)
                    switch commandRetryAction {
                    case .dontRetry:
                        break
                    case .tryAgain:
                        retryCommands.append((commands[commands.startIndex + result.offset], result.offset))
                        let wait = self.clientConfiguration.retryParameters.calculateWaitTime(retry: attempt)
                        try await Task.sleep(for: wait)
                    case .redirect(let redirectError):
                        if redirection == nil {
                            let node = try await self.nodeClient(for: redirectError)
                            let asking = redirectError.redirection == .ask
                            redirection = .init(node: node, ask: asking)
                        }
                        retryCommands.append((commands[commands.startIndex + result.offset], result.offset))
                    }
                case .success:
                    break
                }
            }
            // There are no commands to retry we can return the results
            if retryCommands.count == 0 {
                return results
            }
            var ask = false
            if let redirection {
                node = redirection.node
                ask = redirection.ask
            } else {
                // only increment attempt if we aren't redirecting to another node
                attempt += 1
            }
            // send commands that need retrying
            let retriedResults =
                if ask {
                    await node.executeWithAsk(retryCommands.map(\.0))
                } else {
                    await node.execute(retryCommands.map(\.0))
                }
            // copy results back into main result array
            for result in retriedResults.enumerated() {
                results[retryCommands[result.offset].1] = result.element
            }
            retryCommands.removeAll(keepingCapacity: true)
        }
        throw ValkeyClusterError.clientRequestCancelled
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
        let hashSlots = keys.compactMap { HashSlot(key: $0) }
        let node = try await self.nodeClient(for: hashSlots)
        return try await node.withConnection(isolation: isolation, operation: operation)
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

        self.queueAction(.runTimer(circuitBreakerTimer))
        self.queueAction(.runClusterDiscovery(runNodeDiscovery: true))

        await withTaskCancellationHandler {
            /// Run discarding task group running actions
            await withDiscardingTaskGroup { group in
                for await action in self.actionStream {
                    group.addTask {
                        await self.runAction(action)
                    }
                }
            }
        } onCancel: {
            _ = self.stateLock.withLock {
                $0.shutdown()
            }

            // TODO: All the pools shutdown automatically because of task cancellation propagation
        }
    }

    // MARK: - Private methods -

    /// Return HashSlot for collection of keys.
    ///
    /// If collection is empty return `nil`
    /// If collection of keys use a variety of hash slot then throw an error
    @usableFromInline
    /* private */ func hashSlot(for keys: some Collection<ValkeyKey>) throws -> HashSlot? {
        guard let firstKey = keys.first else { return nil }
        let hashSlot = HashSlot(key: firstKey)
        for key in keys.dropFirst() {
            guard hashSlot == HashSlot(key: key) else { throw ValkeyClusterError.keysInCommandRequireMultipleHashSlots }
        }
        return hashSlot
    }

    /// Node and list of indices into command array
    @usableFromInline
    struct NodeAndCommands: Sendable {
        @usableFromInline
        let node: ValkeyNodeClient
        @usableFromInline
        var commandIndices: [Int]

        @usableFromInline
        internal init(node: ValkeyNodeClient, commandIndices: [Int]) {
            self.node = node
            self.commandIndices = commandIndices
        }
    }

    /// Split command array into multiple arrays of indices into the original array.
    ///
    /// These array of indices are then used to create collections of commands to
    /// run on each node
    @usableFromInline
    func splitCommandsAcrossNodes(commands: [any ValkeyCommand]) async throws -> some Collection<NodeAndCommands> {
        var nodeMap: [ValkeyServerAddress: NodeAndCommands] = [:]
        var index = commands.startIndex
        var prevAddress: ValkeyServerAddress? = nil
        // iterate through commands until you reach one that affects a key
        while index < commands.endIndex {
            let command = commands[index]
            index += 1
            let keysAffected = command.keysAffected
            if keysAffected.count > 0 {
                // Get hash slot for key and add all the commands you have iterated through so far to the
                // node associated with that key and break out of loop
                let hashSlot = try self.hashSlot(for: keysAffected)
                let node = try await self.nodeClient(for: hashSlot.map { [$0] } ?? [])
                let address = node.serverAddress
                let nodeAndCommands = NodeAndCommands(node: node, commandIndices: .init(commands.startIndex..<index))
                nodeMap[address] = nodeAndCommands
                prevAddress = address
                break
            }
        }
        // If we found a key while iterating through the commands iterate through the remaining commands
        if var prevAddress {
            while index < commands.endIndex {
                let command = commands[index]
                let keysAffected = command.keysAffected
                if keysAffected.count > 0 {
                    // If command affects a key get hash slot for key and add command to the node associated with that key
                    let hashSlot = try self.hashSlot(for: keysAffected)
                    let node = try await self.nodeClient(for: hashSlot.map { [$0] } ?? [])
                    prevAddress = node.serverAddress
                    nodeMap[prevAddress, default: .init(node: node, commandIndices: [])].commandIndices.append(index)
                } else {
                    // if command doesn't affect a key then use the node the previous command used
                    nodeMap[prevAddress]!.commandIndices.append(index)
                }
                index += 1
            }
        } else {
            // if none of the commands affect any keys then choose a random node
            let node = try await self.nodeClient(for: [])
            let address = node.serverAddress
            let nodeAndCommands = NodeAndCommands(node: node, commandIndices: .init(commands.startIndex..<index))
            nodeMap[address] = nodeAndCommands
        }
        return nodeMap.values
    }

    @usableFromInline
    enum RetryAction {
        case redirect(ValkeyClusterRedirectionError)
        case tryAgain
        case dontRetry
    }

    @usableFromInline
    /* private */ func getRetryAction(from error: some Error) -> RetryAction {
        switch error {
        case let error as ValkeyClientError where error.errorCode == .commandError:
            guard let errorMessage = error.message else {
                return .dontRetry
            }
            if let redirectError = ValkeyClusterRedirectionError(errorMessage) {
                self.logger.trace("Received redirect error", metadata: ["error": "\(redirectError)"])
                return .redirect(redirectError)
            } else {
                let prefix = errorMessage.prefix { $0 != " " }
                switch prefix {
                case "TRYAGAIN", "MASTERDOWN", "CLUSTERDOWN", "LOADING":
                    self.logger.trace("Received cluster error", metadata: ["error": "\(prefix)"])
                    return .tryAgain
                default:
                    return .dontRetry
                }
            }
        default:
            return .dontRetry
        }
    }

    private func queueAction(_ action: RunAction) {
        self.actionStreamContinuation.yield(action)
    }

    /// Manages the primary task group that handles all client operations.
    ///
    /// - Parameter taskGroup: The task group to add tasks to.
    private func runAction(_ action: RunAction) async {
        switch action {
        case .runClusterDiscovery(let runNodeDiscovery):
            await self.runClusterDiscovery(runNodeDiscoveryFirst: runNodeDiscovery)

        case .runClient(let client):
            await client.run()

        case .runTimer(let timer):
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
            self.queueAction(.runClusterDiscovery(runNodeDiscovery: runDiscovery.runNodeDiscoveryFirst))
        }
    }

    /// Handles actions related to Valkey node updates.
    ///
    /// - Parameter action: The update action containing clients to run and shut down.
    private func runUpdateValkeyNodesAction(_ action: StateMachine.UpdateValkeyNodesAction) {
        for client in action.clientsToRun {
            self.queueAction(.runClient(client))
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
            self.queueAction(.runTimer(newTimer))
        }

        for client in action.clientsToRun {
            self.queueAction(.runClient(client))
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
            self.queueAction(.runTimer(retryTimer))
        }

        if let circuitBreakerTimer = action.circuitBreakerTimer {
            self.queueAction(.runTimer(circuitBreakerTimer))
        }
    }

    // MARK: Obtaining a client

    /// Retrieves a client for the node that handles the specified MOVED error.
    ///
    /// This internal method is used when handling cluster topology changes indicated by
    /// MOVED responses from Valkey nodes.
    ///
    /// - Parameter redirectError: The MOVED/ASK error response from a Valkey node.
    /// - Returns: A ``ValkeyNode`` connected to the node that can handle the request.
    /// - Throws:
    ///   - `ValkeyClusterError.waitedForDiscoveryAfterMovedErrorThreeTimes` if unable to resolve
    ///     the MOVED error after multiple attempts
    ///   - `ValkeyClusterError.clientRequestCancelled` if the request is cancelled
    @usableFromInline
    /* private */ func nodeClient(for redirectError: ValkeyClusterRedirectionError) async throws -> ValkeyNodeClient {
        var counter = 0
        while counter < 3 {
            defer { counter += 1 }
            let action = try self.stateLock.withLock { stateMachine throws(ValkeyClusterError) -> StateMachine.PoolForRedirectErrorAction in
                try stateMachine.poolFastPath(for: redirectError)
            }

            switch action {
            case .connectionPool(let node):
                return node

            case .runAndUseConnectionPool(let node):
                self.queueAction(.runClient(node))
                return node

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

    /// Retrieves a ``ValkeyNode`` for communicating with nodes that manage the given hash slots.
    ///
    /// This is a lower-level method that can be used when you need direct access to a
    /// specific `ValkeyNode` instance for nodes managing particular hash slots. Most users
    /// should prefer the higher-level `send(command:)` method.
    ///
    /// - Parameter slots: The collection of hash slots to determine which node to connect to.
    /// - Returns: A `ValkeyNode` instance connected to the appropriate node.
    /// - Throws:
    ///   - `ValkeyClusterError.clusterIsUnavailable` if no healthy nodes are available
    ///   - `ValkeyClusterError.clusterIsMissingSlotAssignment` if the slot assignment cannot be determined
    @inlinable
    package func nodeClient(for slots: some (Collection<HashSlot> & Sendable)) async throws -> ValkeyNodeClient {
        var retries = 0
        while retries < 3 {
            defer { retries += 1 }

            do {
                return try self.stateLock.withLock { state -> ValkeyNodeClient in
                    try state.poolFastPath(for: slots)
                }
            } catch let error as ValkeyClusterError where error == .clusterIsUnavailable {
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
    private func runMovedToDegraded(_ action: StateMachine.PoolForRedirectErrorAction.MoveToDegraded) {
        if let cancelToken = action.runDiscoveryAndCancelTimer {
            cancelToken.yield()
            self.queueAction(.runClusterDiscovery(runNodeDiscovery: false))
        }

        self.queueAction(.runTimer(action.circuitBreakerTimer))
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
    private func runNodeDiscovery() async throws -> [ValkeyClusterVoter<ValkeyNodeClient>] {
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
    private func runClusterDiscoveryFindingConsensus(voters: [ValkeyClusterVoter<ValkeyNodeClient>]) async throws -> ValkeyClusterDescription {
        try await withThrowingTaskGroup(of: (ValkeyClusterDescription, ValkeyNodeID).self) { taskGroup in
            for voter in voters {
                taskGroup.addTask {
                    (try await voter.client.execute(CLUSTER.SHARDS()), voter.nodeID)
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
                            (try await voter.client.execute(CLUSTER.SHARDS()), voter.nodeID)
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

/// Extension that makes `ValkeyClusterClient` conform to `ValkeyClientProtocol`.
///
/// This allows the cluster client to be used anywhere a `ValkeyClientProtocol` is expected.
@available(valkeySwift 1.0, *)
extension ValkeyClusterClient: ValkeyClientProtocol {}

extension Array where Element == any ValkeyCommand {
    /// Initializer used internally in cluster client and tests for constructing an array
    /// of commands from a parameter pack of commands
    @inlinable
    init<each Command: ValkeyCommand>(
        commands: repeat each Command
    ) {
        var commandArray: [any ValkeyCommand] = []
        for command in repeat each commands {
            commandArray.append(command)
        }
        self = commandArray
    }
}
