//
// This source file is part of the valkey-swift project
// Copyright (c) 2025-2026 the valkey-swift project authors
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
    typealias StateMachine = ValkeyClientStateMachine<
        ValkeyNodeClient, ValkeyNodeClientFactory, AsyncStream<Void>.Continuation, CheckedContinuation<ValkeyNodeClient, any Error>
    >
    enum Topology {
        case standalone
        case sentinel(ValkeySentinelClient)
    }

    let nodeClientFactory: ValkeyNodeClientFactory
    /// Client state machine
    @usableFromInline
    let stateMachine: Mutex<StateMachine>
    /// configuration
    @usableFromInline
    var configuration: ValkeyClientConfiguration { self.nodeClientFactory.configuration }
    @usableFromInline
    let clock = ContinuousClock()
    /// topology of servers
    let topology: Topology
    /// EventLoopGroup to use
    var eventLoopGroup: any EventLoopGroup { self.nodeClientFactory.eventLoopGroup }
    /// Logger
    let logger: Logger
    /// running atomic
    let runningAtomic: Atomic<Bool>

    enum RunAction: Sendable {
        case runNodeClient(ValkeyNodeClient)
        case runTimer(ValkeyTimer)
        case runRole
        case verifyReplicas
        case runSentinelClient(ValkeySentinelClient)
        case askSentinelForPrimary(ValkeySentinelClient)
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

    package convenience init(
        _ address: ValkeyServerAddress,
        customHandler: @escaping @Sendable (ValkeyServerAddress, any EventLoop) async throws -> any Channel,
        configuration: ValkeyClientConfiguration = .init(),
        eventLoopGroup: any EventLoopGroup = MultiThreadedEventLoopGroup.singleton,
        logger: Logger
    ) {
        self.init(
            address,
            customHandler: customHandler,
            connectionIDGenerator: ConnectionIDGenerator(),
            connectionFactory: ValkeyConnectionFactory(configuration: configuration),
            eventLoopGroup: eventLoopGroup,
            logger: logger
        )
    }

    package init(
        _ address: ValkeyServerAddress,
        customHandler: (@Sendable (ValkeyServerAddress, any EventLoop) async throws -> any Channel)? = nil,
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
                customHandler: customHandler
            ),
            eventLoopGroup: eventLoopGroup
        )
        self.logger = logger
        self.runningAtomic = .init(false)
        self.stateMachine = .init(.init(poolFactory: self.nodeClientFactory, configuration: connectionFactory.configuration))
        self.topology = .standalone
        (self.actionStream, self.actionStreamContinuation) = AsyncStream.makeStream(of: RunAction.self)
        self.setPrimary(address)
    }

    /// Creates a new Valkey client
    ///
    /// - Parameters:
    ///   - address: Valkey database address
    ///   - configuration: Valkey client configuration
    ///   - eventLoopGroup: EventLoopGroup to run WebSocket client on
    ///   - logger: Logger
    public convenience init(
        primaryName: String,
        sentinelNodeDiscovery: any ValkeyNodeDiscovery,
        configuration: ValkeyClientConfiguration = .init(),
        eventLoopGroup: any EventLoopGroup = MultiThreadedEventLoopGroup.singleton,
        logger: Logger
    ) {
        self.init(
            primaryName: primaryName,
            sentinelNodeDiscovery: sentinelNodeDiscovery,
            connectionIDGenerator: ConnectionIDGenerator(),
            connectionFactory: ValkeyConnectionFactory(configuration: configuration),
            eventLoopGroup: eventLoopGroup,
            logger: logger
        )
    }

    package convenience init(
        primaryName: String,
        sentinelNodeDiscovery: any ValkeyNodeDiscovery,
        customHandler: @escaping @Sendable (ValkeyServerAddress, any EventLoop) async throws -> any Channel,
        configuration: ValkeyClientConfiguration = .init(),
        eventLoopGroup: any EventLoopGroup = MultiThreadedEventLoopGroup.singleton,
        logger: Logger
    ) {
        self.init(
            primaryName: primaryName,
            sentinelNodeDiscovery: sentinelNodeDiscovery,
            customHandler: customHandler,
            connectionIDGenerator: ConnectionIDGenerator(),
            connectionFactory: ValkeyConnectionFactory(configuration: configuration),
            eventLoopGroup: eventLoopGroup,
            logger: logger
        )
    }

    package init(
        primaryName: String,
        sentinelNodeDiscovery: any ValkeyNodeDiscovery,
        customHandler: (@Sendable (ValkeyServerAddress, any EventLoop) async throws -> any Channel)? = nil,
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
                customHandler: customHandler
            ),
            eventLoopGroup: eventLoopGroup
        )
        self.logger = logger
        self.runningAtomic = .init(false)
        self.stateMachine = .init(.init(poolFactory: self.nodeClientFactory, configuration: connectionFactory.configuration))
        let sentinelClient = ValkeySentinelClient(
            primaryName: primaryName,
            nodeDiscovery: sentinelNodeDiscovery,
            customHandler: customHandler,
            configuration: .init(clientConfiguration: connectionFactory.configuration),
            eventLoopGroup: eventLoopGroup,
            logger: logger
        )
        self.topology = .sentinel(sentinelClient)
        (self.actionStream, self.actionStreamContinuation) = AsyncStream.makeStream(of: RunAction.self)
        self.queueAction(.runSentinelClient(sentinelClient))
        self.queueAction(.askSentinelForPrimary(sentinelClient))
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
    ///   - readOnly: Are operations in closure are read only
    ///   - operation: Closure handling Valkey connection
    /// - Returns: Value returned by closure
    @inlinable
    public func withConnection<Value>(
        readOnly: Bool = false,
        operation: (ValkeyConnection) async throws -> sending Value
    ) async throws -> Value {
        let node = try await self.getNode(readOnly: readOnly)
        return try await node.withConnection(operation: operation)
    }

    @inlinable
    func getNode(readOnly: Bool) async throws(ValkeyClientError) -> ValkeyNodeClient {
        let selection =
            if readOnly {
                self.configuration.readOnlyCommandNodeSelection.nodeSelection
            } else {
                ValkeyNodeSelection.primary
            }
        if let node = self.stateMachine.withLock({ $0.getNode(selection) }) {
            return node
        } else {
            // We didn't get a node from the state machine we should wait for the primary to be set
            // TODO: Deal with cancellation, and returning errors
            do {
                return try await withCheckedThrowingContinuation { cont in
                    let value = self.stateMachine.withLock { $0.sentinelWaitForPrimary(waiterID: 0, successNotifier: cont) }
                    switch value {
                    case .none:
                        break
                    case .success(let node):
                        cont.resume(returning: node)
                    case .failure(let error):
                        cont.resume(throwing: error)
                    }
                }
            } catch let error as ValkeyClientError {
                throw error
            } catch let error as ValkeySentinelError {
                throw ValkeyClientError(.sentinelError, error: error)
            } catch {
                throw ValkeyClientError(.unrecognisedError, error: error)
            }
        }
    }
}

// MARK: Actions

@available(valkeySwift 1.0, *)
extension ValkeyClient {
    func queueAction(_ action: RunAction) {
        self.actionStreamContinuation.yield(action)
    }

    private func runAction(_ action: RunAction) async {
        switch action {
        case .runNodeClient(let nodeClient):
            await nodeClient.run()

        case .runRole:
            await self.runRoleAction()

        case .runTimer(let timer):
            await self.runTimerAction(timer)

        case .runSentinelClient(let sentinelClient):
            await sentinelClient.run()

        case .askSentinelForPrimary(let sentinelClient):
            await self.runAskSentinelForPrimary(sentinelClient)

        case .verifyReplicas:
            break
        }
    }

    /// Run ROLE command and update topology based on results
    private func runRoleAction() async {
        struct NotReplicaError: Error {}
        var topology: StateMachine.TopologyRefreshInput
        guard let nodeClient = try? await self.getNode(readOnly: false) else { return }
        do {
            let role = try await nodeClient.execute(ROLE())
            switch role {
            case .primary(let primaryState):
                let replicas = primaryState.replicas.map { ValkeyServerAddress.hostname($0.ip, port: $0.port) }
                // add nodes primary found
                let action = self.stateMachine.withLock { $0.addNewNodesFromRefresh(replicas) }
                for replicaClient in action.clientsToRun {
                    self.queueAction(.runNodeClient(replicaClient))
                }
                // verify all replicas are replicas
                guard try await self.verifyReplicas(action.clientsToRun) else { throw NotReplicaError() }

                topology = .primary(replicas: replicas)
                self.logger.debug("Found replicas \(replicas)")

            case .replica(let replica):
                if !self.configuration.connectingToReplica {
                    let primary = ValkeyServerAddress.hostname(replica.primaryIP, port: replica.primaryPort)
                    topology = .replica(primary: primary)
                    self.logger.debug("Redirect to primary \(primary)")
                } else {
                    topology = .primary(replicas: [])
                }
                break
            case .sentinel:
                preconditionFailure("Valkey-swift does not support sentinel at this point in time.")
            }

            let action = self.stateMachine.withLock { $0.topologyRefreshSucceeded(topology) }
            for node in action.clientsToRun {
                self.queueAction(.runNodeClient(node))
            }
            for node in action.clientsToShutdown {
                node.triggerGracefulShutdown()
            }
            switch action.nextAction {
            case .refreshTopology:
                self.queueAction(.runRole)
            case .startTimer(let timer):
                self.queueAction(.runTimer(timer))
            case .doNothing:
                break
            }
        } catch {
            let action = self.stateMachine.withLock { $0.topologyRefreshFailed() }
            if let timer = action.retryTimer {
                self.queueAction(.runTimer(timer))
            }
        }
    }

    /// Run timer action
    ///
    /// Run timer task that triggers timer after specified time, register timer cancellation token with
    /// state machine and run second task waiting on cancellation token. Wait for one of these tasks to
    /// finish and cancel the other
    private func runTimerAction(_ timer: ValkeyTimer) async {
        await withTaskGroup(of: Void.self) { taskGroup in
            taskGroup.addTask {
                do {
                    try await self.clock.sleep(for: timer.duration)
                    // timer has hit
                    let timerFiredAction = self.stateMachine.withLock {
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

            let action = self.stateMachine.withLock {
                $0.registerTimerCancellationToken(continuation, for: timer)
            }
            switch action {
            case .cancelTimer(let token):
                token.finish()
            case .doNothing:
                break
            }

            await taskGroup.next()
            taskGroup.cancelAll()
        }
    }

    private func runTimerFiredAction(_ action: StateMachine.TimerFiredAction) {
        switch action {
        case .runRole:
            self.queueAction(.runRole)

        case .doNothing:
            break
        }
    }

    private func runAskSentinelForPrimary(_ sentinelClient: ValkeySentinelClient) async {
        do {
            let nodes = try await sentinelClient.getNodes()
            self.setTopology(primary: nodes.primary, replicas: nodes.replicas)
        } catch {
            let action = self.stateMachine.withLock { $0.sentinelReportError(error: error) }
            switch action {
            case .reportError(let waiters):
                for waiter in waiters {
                    waiter.resume(throwing: error)
                }
            case .doNothing:
                break
            }
        }
    }

    private func verifyReplicas(_ replicas: [ValkeyNodeClient]) async throws -> Bool {
        try await withThrowingTaskGroup(of: Bool.self) { group in
            for replica in replicas {
                group.addTask {
                    let role = try await replica.execute(ROLE())
                    guard case .replica = role else {
                        return false
                    }
                    return true
                }
            }
            return try await group.reduce(true) { $0 && $1 }
        }
    }

    @usableFromInline
    func refreshPrimary() {
        let action = self.stateMachine.withLock { $0.sentinelSetWaitingForPrimary() }
        switch action {
        case .triggerGetPrimary:
            switch self.topology {
            case .sentinel(let client):
                self.queueAction(.askSentinelForPrimary(client))
            case .standalone:
                preconditionFailure("Cannot refresh primary in standalone mode")
            }
        case .doNothing:
            break
        }
    }
}

// MARK: ValkeyClientProtocol methods

/// Extend ValkeyClient so we can call commands directly from it
@available(valkeySwift 1.0, *)
extension ValkeyClient: ValkeyClientProtocol {
    /// Send command to Valkey connection from connection pool
    /// - Parameter command: Valkey command
    /// - Returns: Response from Valkey command
    @inlinable
    public func execute<Command: ValkeyCommand>(_ command: Command) async throws(ValkeyClientError) -> Command.Response {
        var attempt = 0
        repeat {
            do {
                return try await self.withConnection(readOnly: command.isReadOnly) { connection in
                    try await connection.execute(command)
                }
            } catch let error as ValkeyClientError {
                switch self.getRetryAction(from: error) {
                case .redirect(let redirectError):
                    guard let wait = self.configuration.retryParameters.calculateWaitTime(attempt: attempt) else {
                        throw error
                    }
                    try? await Task.sleep(for: wait)
                    attempt += 1
                    self.setPrimary(redirectError.address)
                case .tryAgain(let refreshPrimary):
                    if refreshPrimary {
                        self.refreshPrimary()
                    }
                    guard let wait = self.configuration.retryParameters.calculateWaitTime(attempt: attempt) else {
                        throw error
                    }
                    try? await Task.sleep(for: wait)
                    attempt += 1

                case .dontRetry:
                    throw error
                }
            } catch {
                throw ValkeyClientError(.unrecognisedError, error: error)
            }
        } while !Task.isCancelled
        throw ValkeyClientError(.cancelled)
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
    ) async -> sending (repeat Result<(each Command).Response, ValkeyClientError>) {
        var readOnly = true
        for command in repeat each commands {
            readOnly = readOnly && command.isReadOnly
        }
        var attempt = 0
        do {
            var node = try await self.getNode(readOnly: readOnly)
            executeCommands: while true {
                let results = await node.execute(repeat each commands)
                if Task.isCancelled {
                    return results
                }
                for result in repeat each results {
                    if case .failure(let error) = result {
                        switch self.getRetryAction(from: error) {
                        case .redirect(let redirectError):
                            guard let wait = self.configuration.retryParameters.calculateWaitTime(attempt: attempt) else {
                                return results
                            }
                            try? await Task.sleep(for: wait)
                            attempt += 1
                            self.setPrimary(redirectError.address)
                            node = try await self.getNode(readOnly: false)
                            continue executeCommands
                        case .tryAgain(let refreshPrimary):
                            if refreshPrimary {
                                self.refreshPrimary()
                            }
                            guard let wait = self.configuration.retryParameters.calculateWaitTime(attempt: attempt) else {
                                return results
                            }
                            try? await Task.sleep(for: wait)
                            attempt += 1
                            node = try await self.getNode(readOnly: readOnly)
                            continue executeCommands

                        case .dontRetry:
                            break
                        }
                    }
                }
                return results
            }
        } catch {
            return (repeat Result<(each Command).Response, ValkeyClientError>.failure(error))
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
    public func execute<Commands: Collection>(
        _ commands: Commands
    ) async -> [Result<RESPToken, ValkeyClientError>] where Commands.Element == any ValkeyCommand {
        let readOnly =
            if self.configuration.readOnlyCommandNodeSelection == .primary {
                false
            } else {
                commands.reduce(true) { $0 && $1.isReadOnly }
            }
        // get node client and execute commands
        do {
            var node = try await self.getNode(readOnly: readOnly)
            var results = await node.execute(commands)

            var attempt = 0
            var startIndex = commands.startIndex
            var resultIndex = results.startIndex

            // Process results, If we find one that needs a retry, then retry command and all the commands that follow
            while !Task.isCancelled {
                // loop through results that haven't been checked
                resultLoop: for result in results[resultIndex...] {
                    if case .failure(let error) = result {
                        switch self.getRetryAction(from: error) {
                        case .redirect(let redirectError):
                            guard let wait = self.configuration.retryParameters.calculateWaitTime(attempt: attempt) else {
                                return results
                            }
                            try? await Task.sleep(for: wait)
                            attempt += 1
                            self.setPrimary(redirectError.address)
                            node = try await self.getNode(readOnly: false)
                            break resultLoop
                        case .tryAgain(let refreshPrimary):
                            if refreshPrimary {
                                self.refreshPrimary()
                            }
                            guard let wait = self.configuration.retryParameters.calculateWaitTime(attempt: attempt) else {
                                return results
                            }
                            try? await Task.sleep(for: wait)
                            attempt += 1
                            node = try await self.getNode(readOnly: readOnly)
                            break resultLoop

                        case .dontRetry:
                            break
                        }
                    }
                    resultIndex += 1
                    startIndex = commands.index(after: startIndex)
                }
                // if no results require a retry break out of loop
                if resultIndex == results.count {
                    break
                }
                // Retry commands that failed and all subsequent commands
                let newResults = await node.execute(commands[startIndex...])
                // Replace old results with new results
                results.removeLast(newResults.count)
                results.append(contentsOf: newResults)
            }
            return results
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
    public func transaction<each Command: ValkeyCommand>(
        _ commands: repeat each Command
    ) async throws -> sending (repeat Result<(each Command).Response, ValkeyClientError>) {
        var readOnly = true
        for command in repeat each commands {
            readOnly = readOnly && command.isReadOnly
        }
        var attempt = 0
        outsideLoop: repeat {
            let node = try await self.getNode(readOnly: readOnly)
            do {
                return try await node.transaction(repeat each commands)
            } catch let error as ValkeyTransactionError {
                if case .transactionErrors(let results, _) = error {
                    for result in results {
                        if case .failure(let error) = result {
                            switch self.getRetryAction(from: error) {
                            case .redirect(let redirectError):
                                guard let wait = self.configuration.retryParameters.calculateWaitTime(attempt: attempt) else {
                                    break
                                }
                                try? await Task.sleep(for: wait)
                                attempt += 1
                                self.setPrimary(redirectError.address)
                                continue outsideLoop
                            case .tryAgain(let refreshPrimary):
                                if refreshPrimary {
                                    self.refreshPrimary()
                                }
                                guard let wait = self.configuration.retryParameters.calculateWaitTime(attempt: attempt) else {
                                    break
                                }
                                try? await Task.sleep(for: wait)
                                attempt += 1
                                continue outsideLoop

                            case .dontRetry:
                                break
                            }
                        }
                    }
                }
                throw error
            }
        } while !Task.isCancelled
        throw ValkeyClientError(.cancelled)
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
    public func transaction<Commands: Collection>(
        _ commands: Commands
    ) async throws -> [Result<RESPToken, ValkeyClientError>] where Commands.Element == any ValkeyCommand {
        let readOnly =
            if self.configuration.readOnlyCommandNodeSelection == .primary {
                false
            } else {
                commands.reduce(true) { $0 && $1.isReadOnly }
            }
        var attempt = 0
        outsideLoop: repeat {
            let node = try await self.getNode(readOnly: readOnly)
            do {
                return try await node.transaction(commands)
            } catch let error as ValkeyTransactionError {
                if case .transactionErrors(let results, _) = error {
                    for result in results {
                        if case .failure(let error) = result {
                            switch self.getRetryAction(from: error) {
                            case .redirect(let redirectError):
                                guard let wait = self.configuration.retryParameters.calculateWaitTime(attempt: attempt) else {
                                    break
                                }
                                try? await Task.sleep(for: wait)
                                attempt += 1
                                self.setPrimary(redirectError.address)
                                continue outsideLoop
                            case .tryAgain(let refreshPrimary):
                                if refreshPrimary {
                                    self.refreshPrimary()
                                }
                                guard let wait = self.configuration.retryParameters.calculateWaitTime(attempt: attempt) else {
                                    break
                                }
                                try? await Task.sleep(for: wait)
                                attempt += 1
                                continue outsideLoop
                            case .dontRetry:
                                break
                            }
                        }
                    }
                }
                throw error
            }
        } while !Task.isCancelled
        throw ValkeyClientError(.cancelled)
    }
}

// MARK: Private methods
@available(valkeySwift 1.0, *)
extension ValkeyClient {
    @usableFromInline
    /* private */ func setPrimary(_ address: ValkeyServerAddress) {
        let action = self.stateMachine.withLock { $0.setPrimary(address) }
        if let node = action.nodeToRun {
            self.queueAction(.runNodeClient(node))
            for waiter in action.waiters {
                waiter.resume(returning: node)
            }
        }
        switch action.nextAction {
        case .refreshTopology(let cancelTimer):
            cancelTimer?.yield()
            self.queueAction(.runRole)
        case .doNothing:
            break
        }
    }

    @usableFromInline
    /* private */ func setTopology(primary: ValkeyServerAddress, replicas: [ValkeyServerAddress]) {
        let action = self.stateMachine.withLock { $0.sentinelSetTopology(primary: primary, replicas: replicas) }
        for client in action.clientsToRun {
            self.queueAction(.runNodeClient(client))
        }
        for client in action.clientsToShutdown {
            client.triggerForceShutdown()
        }
        for waiter in action.waiters {
            waiter.resume(returning: action.primaryClient)
        }
    }

    @usableFromInline
    enum RetryAction {
        case redirect(ValkeyRedirectError)
        case tryAgain(refreshPrimary: Bool)
        case dontRetry
    }

    @usableFromInline
    /* private */ func getRetryAction(from error: ValkeyClientError) -> RetryAction {
        switch error.errorCode {
        case .commandError:
            guard let errorMessage = error.message else {
                return .dontRetry
            }
            if let redirectError = ValkeyRedirectError(errorMessage) {
                self.logger.trace("Received redirect error", metadata: ["error": "\(redirectError)"])
                return .redirect(redirectError)
            } else {
                let prefix = errorMessage.prefix { $0 != " " }
                switch prefix {
                case "LOADING", "BUSY":
                    self.logger.trace("Received cluster error", metadata: ["error": "\(prefix)"])
                    return .tryAgain(refreshPrimary: false)
                default:
                    return .dontRetry
                }
            }
        case .connectionClosed, .connectionClosing:
            switch self.topology {
            case .standalone: return .tryAgain(refreshPrimary: false)
            case .sentinel: return .tryAgain(refreshPrimary: true)
            }
        case .connectionClosedDueToCancellation:
            return .tryAgain(refreshPrimary: false)
        case .connectionCreationCircuitBreakerTripped:
            switch self.topology {
            case .standalone: return .dontRetry
            case .sentinel: return .tryAgain(refreshPrimary: true)
            }
        default:
            return .dontRetry
        }
    }
}

#if ServiceLifecycleSupport
@available(valkeySwift 1.0, *)
extension ValkeyClient: Service {}
#endif  // ServiceLifecycle
