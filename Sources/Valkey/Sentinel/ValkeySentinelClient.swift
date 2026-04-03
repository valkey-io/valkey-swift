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
import ServiceLifecycle
import Synchronization

@available(valkeySwift 1.0, *)
package final class ValkeySentinelClient: Sendable {
    @usableFromInline
    typealias StateMachine = ValkeySentinelClientStateMachine<
        ValkeyNodeClient, ValkeyClusterNodeClientFactory, CheckedContinuation<Void, any Error>, AsyncStream<Void>.Continuation
    >

    let primaryName: String
    let nodeClientFactory: ValkeyClusterNodeClientFactory
    /// single node
    @usableFromInline
    let stateMachine: Mutex<StateMachine>
    let logger: Logger
    private let nodeDiscovery: any ValkeyNodeDiscovery

    private enum RunAction {
        case runSentinelDiscovery(runNodeDiscover: Bool)
        case runNodeClient(ValkeyNodeClient)
    }
    private let actionStream: AsyncStream<RunAction>
    private let actionStreamContinuation: AsyncStream<RunAction>.Continuation

    package init(
        primaryName: String,
        nodeDiscovery: any ValkeyNodeDiscovery,
        configuration: ValkeySentinelClientConfiguration,
        eventLoopGroup: any EventLoopGroup = MultiThreadedEventLoopGroup.singleton,
        logger: Logger
    ) {
        let connectionFactory = ValkeyConnectionFactory(configuration: configuration.clientConfiguration)
        self.nodeClientFactory = ValkeyClusterNodeClientFactory(
            logger: logger,
            configuration: connectionFactory.configuration,
            connectionFactory: ValkeyConnectionFactory(
                configuration: connectionFactory.configuration,
                customHandler: nil
            ),
            eventLoopGroup: eventLoopGroup
        )
        self.stateMachine = .init(.init(poolFactory: self.nodeClientFactory, configuration: .init()))
        self.primaryName = primaryName
        self.logger = logger
        self.nodeDiscovery = nodeDiscovery
        (self.actionStream, self.actionStreamContinuation) = AsyncStream.makeStream(of: RunAction.self)
    }

    /// Run ValkeySentinelClient connection pool, and other supporting processes
    package func run() async {
        self.queueAction(.runSentinelDiscovery(runNodeDiscover: true))

        /// Run discarding task group running actions
        await withDiscardingTaskGroup { group in
            for await action in self.actionStream {
                group.addTask {
                    await self.runAction(action)
                }
            }
        }
    }

    /// Get primary and replica nodes from sentinel
    package func getNodes() async throws -> ValkeyNodeIDs<ValkeyServerAddress> {
        // get list of sentinel clients
        let sentinels = try await self.getSentinelClients()
        return try await withThrowingTaskGroup(of: (index: Int, address: ValkeyNodeIDs<ValkeyServerAddress>).self) { group in
            // For each sentinel add a task to get primary and replica nodes. The first node that returns
            // values will be accepted
            for index in 0..<sentinels.count {
                group.addTask {
                    let (primaryResult, replicaResults) = await sentinels[index].execute(
                        SENTINEL.GETPRIMARYADDRBYNAME(primaryName: self.primaryName),
                        SENTINEL.REPLICAS(primaryName: self.primaryName)
                    )
                    let (primaryHost, primaryPort) = try primaryResult.get().decodeElements(as: (String, Int).self)
                    let replicas = try replicaResults.get()
                        .decode(as: [SentinelInstance].self)
                        .compactMap {
                            if !$0.flags.contains(.disconnected) && !$0.flags.contains(.s_down) {
                                ValkeyServerAddress.hostname($0.endpoint, port: $0.port)
                            } else {
                                nil
                            }
                        }
                    return (index, .init(primary: .hostname(primaryHost, port: primaryPort), replicas: replicas))
                }
            }
            // Add a timeout task
            group.addTask {
                try await Task.sleep(for: .milliseconds(500))
                throw CancellationError()
            }
            while let result = await group.nextResult() {
                switch result {
                case .success(let successfulResult):
                    return successfulResult.address
                case .failure(let error):
                    switch error {
                    case is CancellationError:
                        throw ValkeyClientError(.timeout)
                    default:
                        break
                    }
                    break
                }
            }
            throw ValkeySentinelError.sentinelIsUnavailable
        }
    }

    /// Subscribe to sentinel events
    package func subscribeEvents(command: some ValkeySubscribeCommand, _ operation: (ValkeyClientSubscription) async throws -> Void) async throws {
        try await withSubscriptionConnection { connection in
            try await connection._subscribe(command: command) { subscription in
                try await operation(.init(base: subscription))
            }
        }
    }

    // get sentinel clients from statemachine
    private func getSentinelClients() async throws -> [ValkeyNodeClient] {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, any Error>) in
            switch self.stateMachine.withLock({ $0.waitForDiscovery(cont) }) {
            case .complete:
                cont.resume()
            case .fail(let error):
                cont.resume(throwing: error)
            case .doNothing:
                break
            }
        }
        return self.stateMachine.withLock({ $0.getSentinelClients() })
    }

    /// Run operation with the valkey subscription connection
    ///
    /// - Parameters:
    ///   - operation: Closure to run with subscription connection
    @inlinable
    func withSubscriptionConnection<Value>(
        _ operation: (ValkeyConnection) async throws -> Value
    ) async throws -> Value {
        guard let node = try await self.getSentinelClients().randomElement() else {
            throw ValkeySentinelError.sentinelIsUnavailable
        }
        let id = node.subscriptionConnectionIDGenerator.next()

        let connection = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<ValkeyConnection, Error>) in
                node.leaseSubscriptionConnection(id: id, request: cont)
            }
        } onCancel: {
            node.cancelSubscriptionConnection(id: id)
        }

        defer {
            node.releaseSubscriptionConnection(id: id)
        }
        return try await operation(connection)
    }
}

// MARK: Actions

@available(valkeySwift 1.0, *)
extension ValkeySentinelClient {
    private func queueAction(_ action: RunAction) {
        self.actionStreamContinuation.yield(action)
    }

    private func runAction(_ action: RunAction) async {
        switch action {
        case .runNodeClient(let nodeClient):
            await nodeClient.run()

        case .runSentinelDiscovery(let runNodeDiscoveryFirst):
            await runSentinelDiscoveryAction(runNodeDiscoveryFirst: runNodeDiscoveryFirst)
        }
    }

    private func runSentinelDiscoveryAction(runNodeDiscoveryFirst: Bool) async {
        do {
            self.logger.trace("Running node discovery")
            let voters =
                if runNodeDiscoveryFirst {
                    try await runNodeDiscovery(self.nodeDiscovery)
                } else {
                    stateMachine.withLock { $0.getInitialVoters() }
                }
            let sentinelNodes = try await self.runSentinelConsensusDiscoveryAction(voters: voters)
            let action = self.stateMachine.withLock {
                $0.topologyDiscoverySucceeded(sentinelNodes)
            }
            for node in action.clientsToRun {
                self.queueAction(.runNodeClient(node))
            }
            for node in action.clientsToShutdown {
                node.triggerGracefulShutdown()
            }
            for waiter in action.waitersToSucceed {
                waiter.resume()
            }

            self.logger.debug(
                "Discovered nodes",
                metadata: ["node_count": "\(sentinelNodes.nodes.count)"]
            )
        } catch {
            self.logger.debug(
                "Failed to discover nodes",
                metadata: [
                    "error": "\(error)"
                ]
            )
            let action = self.stateMachine.withLock {
                $0.topologyDiscoveryFailed(error: error)
            }
            for waiter in action.waitersToFail {
                waiter.resume(throwing: error)
            }
        }
    }

    private func runSentinelConsensusDiscoveryAction(voters: [ValkeyTopologyVoter<ValkeyNodeClient>]) async throws -> ValkeySentinelNodeList {
        try await withThrowingTaskGroup(of: (ValkeySentinelNodeList, ValkeyNodeID).self) { taskGroup in
            for voter in voters {
                taskGroup.addTask {
                    (try await self.getSentinelList(voter.client, nodeID: voter.nodeID), voter.nodeID)
                }
            }

            var election = ValkeyTopologyElection<ValkeySentinelNodeList>()

            var primaryNameErrorCount = 0
            var resultCount = 0
            while let result = await taskGroup.nextResult() {
                resultCount += 1
                switch result {
                case .success((let sentinels, let serverAddress)):
                    let metrics = election.voteReceived(for: sentinels, from: serverAddress)

                    self.logger.debug(
                        "Vote received",
                        metadata: [
                            "candidate_count": "\(metrics.candidateCount)",
                            "candidate": "\(sentinels)",
                            "votes_received": "\(metrics.votesReceived)",
                            "votes_needed": "\(metrics.votesNeeded)",
                        ]
                    )

                    if let electionWinner = election.winner {
                        taskGroup.cancelAll()
                        return electionWinner
                    }

                    // ensure that we have pools for all returned nodes so that we can reach consensus
                    let action = self.stateMachine.withLock { $0.updateSentinelNodes(sentinels) }
                    runUpdateSentinelNodesAction(action)

                    for voter in action.voters {
                        taskGroup.addTask {
                            (try await self.getSentinelList(voter.client, nodeID: voter.nodeID), voter.nodeID)
                        }
                    }

                case .failure(let error):
                    self.logger.debug(
                        "Received an error while asking for sentinel node list",
                        metadata: [
                            "error": "\(error)"
                        ]
                    )
                    if let clientError = error as? ValkeyClientError, clientError.errorCode == .commandError,
                        clientError.message == "ERR No such master with that name"
                    {
                        primaryNameErrorCount += 1
                    }
                }
            }
            if primaryNameErrorCount == resultCount {
                throw ValkeySentinelError.sentinelUnknownPrimary
            } else {
                // no consensus reached
                throw ValkeySentinelError.sentinelNoConsensusReached
            }
        }
    }

    /// Get sentinel list returned by this sentinel
    private func getSentinelList(_ node: ValkeyNodeClient, nodeID: ValkeyNodeID) async throws -> ValkeySentinelNodeList {
        var sentinels = try await node.execute(SENTINEL.SENTINELS(primaryName: self.primaryName))
            .decode(as: [SentinelInstance].self)
            .compactMap {
                // filter out disconnected or nodes flagged as `s_down`.
                if !$0.flags.contains(.disconnected) && !$0.flags.contains(.s_down) {
                    ValkeyNodeDescription(endpoint: $0.endpoint, port: $0.port)
                } else {
                    nil
                }
            }
        // include itself in the list
        sentinels.append(.init(endpoint: nodeID.endpoint, port: nodeID.port))
        return .init(sentinels)
    }

    private func runNodeDiscovery(_ nodeDiscovery: some ValkeyNodeDiscovery) async throws -> [ValkeyTopologyVoter<ValkeyNodeClient>] {
        self.logger.trace("Running node discovery")
        let nodes = try await nodeDiscovery.lookupNodes()
        let sentinelNodes = ValkeySentinelNodeList(nodes.map { ValkeyNodeDescription(description: $0) })
        let action = self.stateMachine.withLock {
            $0.updateSentinelNodes(sentinelNodes)
        }
        runUpdateSentinelNodesAction(action)
        return action.voters
    }

    private func runUpdateSentinelNodesAction(_ action: StateMachine.UpdateNodesAction) {
        for node in action.clientsToRun {
            self.queueAction(.runNodeClient(node))
        }
        for node in action.clientsToShutdown {
            node.triggerGracefulShutdown()
        }
    }
}

/// Sentinel instance
struct SentinelInstance: RESPTokenDecodable {
    enum Flag: Substring {
        case primary = "master"
        case replica = "slave"
        case sentinel
        case disconnected
        case s_down
        // case o_down
        case master_down
    }
    let endpoint: String
    let port: Int
    let flags: Set<Flag>

    init(_ token: RESPToken) throws(RESPDecodeError) {
        let flags: String
        (self.endpoint, self.port, flags) = try token.decodeMapValues("ip", "port", "flags", as: (String, Int, String).self)
        let splitFlags = flags.splitSequence(separator: ",")
        self.flags = Set(splitFlags.compactMap { Flag(rawValue: $0) })
    }
}
