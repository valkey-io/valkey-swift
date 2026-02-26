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
    let stateMachine: Mutex<ValkeyClientStateMachine<ValkeyNodeClient, ValkeyNodeClientFactory>>
    /// configuration
    @usableFromInline
    var configuration: ValkeyClientConfiguration { self.nodeClientFactory.configuration }
    /// EventLoopGroup to use
    let eventLoopGroup: any EventLoopGroup
    /// Logger
    let logger: Logger
    /// running atomic
    let runningAtomic: Atomic<Bool>

    enum RunAction: Sendable {
        case runNodeClient(ValkeyNodeClient)
        case runRole
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
        self.eventLoopGroup = eventLoopGroup
        self.logger = logger
        self.runningAtomic = .init(false)
        self.stateMachine = .init(.init(poolFactory: self.nodeClientFactory, configuration: connectionFactory.configuration))
        (self.actionStream, self.actionStreamContinuation) = AsyncStream.makeStream(of: RunAction.self)
        self.setPrimary(address)
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
        let node = self.getNode(readOnly: readOnly)
        return try await node.withConnection(operation: operation)
    }

    @inlinable
    func getNode(readOnly: Bool) -> ValkeyNodeClient {
        let selection =
            if readOnly {
                self.configuration.readOnlyCommandNodeSelection.nodeSelection
            } else {
                ValkeyNodeSelection.primary
            }
        return self.stateMachine.withLock { $0.getNode(selection) }
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

        case .runRole:
            var replicas: [ValkeyServerAddress] = []
            let nodeClient = self.getNode(readOnly: false)
            if let role = try? await nodeClient.execute(ROLE()) {
                switch role {
                case .primary(let primary):
                    replicas = primary.replicas.map { .hostname($0.ip, port: $0.port) }
                    self.logger.debug("Found replicas \(replicas)")

                case .replica(let replica):
                    if !self.configuration.connectingToReplica {
                        // if client is pointing to a replica then redirect to the primary
                        self.setPrimary(.hostname(replica.primaryIP, port: replica.primaryPort))
                    }
                    break
                case .sentinel:
                    preconditionFailure("Valkey-swift does not support sentinel at this point in time.")
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
                case .tryAgain:
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
        executeCommands: while true {
            let node = self.getNode(readOnly: readOnly)
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
                        continue executeCommands
                    case .tryAgain:
                        guard let wait = self.configuration.retryParameters.calculateWaitTime(attempt: attempt) else {
                            return results
                        }
                        try? await Task.sleep(for: wait)
                        attempt += 1
                        continue executeCommands

                    case .dontRetry:
                        break
                    }

                }
            }
            return results
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
        var attempt = 0
        let index = commands.startIndex
        #if compiler(<6.2)
        let node = self.getNode(readOnly: readOnly)
        return await node.execute(commands[index...])
        #else
        outsideLoop: while true {
            let node = self.getNode(readOnly: readOnly)
            let results = await node.execute(commands[index...])
            if Task.isCancelled {
                return results
            }
            for result in results {
                if case .failure(let error) = result {
                    switch self.getRetryAction(from: error) {
                    case .redirect(let redirectError):
                        guard let wait = self.configuration.retryParameters.calculateWaitTime(attempt: attempt) else {
                            return results
                        }
                        try? await Task.sleep(for: wait)
                        attempt += 1
                        self.setPrimary(redirectError.address)
                        continue outsideLoop
                    case .tryAgain:
                        guard let wait = self.configuration.retryParameters.calculateWaitTime(attempt: attempt) else {
                            return results
                        }
                        try? await Task.sleep(for: wait)
                        attempt += 1
                        continue outsideLoop

                    case .dontRetry:
                        break
                    }

                }
            }
            return results
        }
        #endif
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
            let node = self.getNode(readOnly: readOnly)
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
                            case .tryAgain:
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
            let node = self.getNode(readOnly: readOnly)
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
                            case .tryAgain:
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
        switch action {
        case .runNode(let client):
            self.queueAction(.runNodeClient(client))
        case .runNodeAndFindReplicas(let client):
            self.queueAction(.runNodeClient(client))
            self.queueAction(.runRole)
        case .findReplicas:
            self.queueAction(.runRole)
        case .doNothing:
            break
        }
    }

    @usableFromInline
    enum RetryAction {
        case redirect(ValkeyRedirectError)
        case tryAgain
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
                    return .tryAgain
                default:
                    return .dontRetry
                }
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
