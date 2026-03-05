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
        ValkeyNodeClient, ValkeyNodeClientFactory, CheckedContinuation<Void, any Error>, AsyncStream<Void>.Continuation
    >

    let primaryName: String
    let nodeClientFactory: ValkeyNodeClientFactory
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
        self.nodeClientFactory = ValkeyNodeClientFactory(
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

    /// Run ValkeyClient connection pool
    public func run() async {
        self.queueAction(.runSentinelDiscovery(runNodeDiscover: true))

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
            let nodes =
                if runNodeDiscoveryFirst {
                    try await runNodeDiscovery(self.nodeDiscovery)
                } else {
                    stateMachine.withLock { $0.getSentinelClients() }
                }
            try await withThrowingTaskGroup(of: (RESPToken.Array, ValkeyServerAddress).self) { taskGroup in
                for node in nodes {
                    taskGroup.addTask {
                        let sentinelsResponse = try await node.execute(SENTINEL.SENTINELS(primaryName: self.primaryName))
                        return (sentinelsResponse, node.serverAddress)
                    }
                }

                var election = ValkeyTopologyElection<ValkeySentinelNodes, ValkeyServerAddress>()

                while let result = await taskGroup.nextResult() {
                    switch result {
                    case .success((let sentinelsResponse, let serverAddress)):
                        do {
                            let nodes = sentinelsResponse.asMap().map {
                                ValkeyNodeDescription(endpoint: $0.key.decode(as: String.self), port: $0.value.decode(as: Int.self))
                            }
                            let sentinelNodes = ValkeySentinelNodes(nodes)
                            let metrics = try election.voteReceived(for: sentinelNodes, from: serverAddress)

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
                                    "nodeID": "\(serverAddress)",
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
                        let action = self.stateMachine.withLock { $0.updateSentinelNodes(sentinelNodes) }
                        for node in action.clientsToRun {
                            self.queueAction(.runNodeClient(node))
                        }
                        for node in action.clientsToShutdown {
                            node.triggerGracefulShutdown()
                        }

                        for node in action.clients {
                            taskGroup.addTask {
                                let sentinelsResponse = try await node.execute(SENTINEL.SENTINELS(primaryName: self.primaryName))
                                return (sentinelsResponse, node.serverAddress)
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
                throw ValkeyClientError.init(.timeout)
            }
            let sentinelNodes = ValkeySentinelNodes(nodes)
            let action = self.stateMachine.withLock {
                $0.updateSentinelNodes(sentinelNodes)
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
                metadata: ["node_count": "\(nodes.count)"]
            )
        } catch {
            self.logger.debug(
                "Failed to discover nodes",
                metadata: [
                    "error": "\(error)"
                ]
            )
            _ = self.stateMachine.withLock {
                $0.topologyDiscoveryFailed(error: error)
            }
        }
    }

    private func runNodeDiscovery(_ nodeDiscovery: some ValkeyNodeDiscovery) async throws -> [ValkeyNodeClient] {
        self.logger.trace("Running node discovery")
        let nodes = try await nodeDiscovery.lookupNodes()
        let sentinelNodes = ValkeySentinelNodes(nodes.map { ValkeyNodeDescription(description: $0) })
        let action = self.stateMachine.withLock {
            $0.updateSentinelNodes(sentinelNodes)
        }
        for node in action.clientsToRun {
            self.queueAction(.runNodeClient(node))
        }
        for node in action.clientsToShutdown {
            node.triggerGracefulShutdown()
        }
        return action.clients
    }

    public func getPrimaryNode() async throws -> ValkeyServerAddress {
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
        let sentinels = self.stateMachine.withLock({ $0.getSentinelClients() })
        return try await withThrowingTaskGroup(of: (index: Int, address: ValkeyServerAddress).self) { group in
            for index in 0..<sentinels.count {
                group.addTask {
                    let primaryName = try await sentinels[index].execute(SENTINEL.GETPRIMARYADDRBYNAME(primaryName: self.primaryName))
                    let (host, port) = try primaryName.decodeElements(as: (String, Int).self)
                    return (index, .hostname(host, port: port))
                }
            }
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
            throw ValkeyClientError(.timeout)
        }
    }
}
