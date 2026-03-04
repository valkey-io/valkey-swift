//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

@available(valkeySwift 1.0, *)
package struct ValkeyTimer: Sendable, Hashable {
    package enum UseCase: Hashable {
        case nextTopologyDiscovery
    }

    package var useCase: UseCase
    package var duration: Duration
    package var timerID: Int

    package init(timerID: Int, useCase: UseCase, duration: Duration) {
        self.useCase = useCase
        self.timerID = timerID
        self.duration = duration
    }
}

@usableFromInline
@available(valkeySwift 1.0, *)
struct ValkeyClientStateMachine<
    ConnectionPool: ValkeyNodeConnectionPool,
    ConnectionPoolFactory: ValkeyNodeConnectionPoolFactory,
    TimerCancellationToken: Sendable
> where ConnectionPoolFactory.ConnectionPool == ConnectionPool, ConnectionPoolFactory.NodeDescription == ValkeyNodeClientFactory.NodeDescription {
    @usableFromInline
    struct Configuration {
        let findReplicas: Bool
        let topologyRefreshInterval: Duration
    }
    @usableFromInline
    struct Timer: Sendable {
        let id: Int
        var cancellationToken: TimerCancellationToken?
    }
    @usableFromInline
    enum State {
        case uninitialized
        case running(ValkeyNodeIDs<ValkeyServerAddress>)
        case shutdown
    }
    @usableFromInline
    enum TopologyRefreshState {
        case notRefreshing
        case waitingForNextRefresh(Timer)
        case refreshing
    }

    @usableFromInline
    var runningClients: ValkeyRunningClientsStateMachine<ConnectionPool, ConnectionPoolFactory>
    @usableFromInline
    var state: State
    @usableFromInline
    var topologyRefreshState: TopologyRefreshState
    @usableFromInline
    let configuration: Configuration

    private var _nextTimerID = 0

    init(poolFactory: ConnectionPoolFactory, configuration: ValkeyClientConfiguration) {
        self.runningClients = .init(poolFactory: poolFactory)
        self.state = .uninitialized
        self.topologyRefreshState = .notRefreshing
        self.configuration = .init(
            findReplicas: configuration.readOnlyCommandNodeSelection != .primary,
            topologyRefreshInterval: .seconds(30)
        )
    }

    @inlinable
    func getNode(_ selection: ValkeyNodeSelection) -> ConnectionPool {
        guard case .running(let nodes) = self.state else {
            preconditionFailure("Cannot get a node if the client statemachine isn't initialized")
        }
        let nodeID = selection.select(nodeIDs: nodes)
        if let pool = self.runningClients[nodeID]?.pool {
            return pool
        } else {
            preconditionFailure()
        }
    }

    @usableFromInline
    struct SetPrimaryAction {
        enum NextAction {
            case refreshTopology(TimerCancellationToken?)
            case doNothing
        }
        let nextAction: NextAction
        let nodeToRun: ConnectionPool?

        init(nextAction: NextAction = .doNothing, nodeToRun: ConnectionPool? = nil) {
            self.nextAction = nextAction
            self.nodeToRun = nodeToRun
        }
    }
    @usableFromInline
    mutating func setPrimary(_ address: ValkeyServerAddress) -> SetPrimaryAction {
        print("Set primary \(address)")
        let nodes = ValkeyNodeIDs(primary: address)
        let action = self.runningClients.addNode(.init(address: address))
        let client: ConnectionPool?
        switch action {
        case .useExistingPool:
            if case .running(let currentNodes) = self.state {
                if currentNodes.primary == address {
                    return .init()
                }
            }
            client = nil
        case .runAndUsePool(let node):
            client = node
        }

        self.state = .running(nodes)
        if self.configuration.findReplicas {
            switch self.topologyRefreshState {
            case .notRefreshing:
                self.topologyRefreshState = .refreshing
                return SetPrimaryAction(nextAction: .refreshTopology(nil), nodeToRun: client)
            case .refreshing:
                return .init(nodeToRun: client)
            case .waitingForNextRefresh(let timer):
                self.topologyRefreshState = .refreshing
                return SetPrimaryAction(nextAction: .refreshTopology(timer.cancellationToken), nodeToRun: client)
            }
        } else {
            return SetPrimaryAction(nextAction: .doNothing, nodeToRun: client)
        }
    }

    enum TimerFiredAction {
        case runRole
        case doNothing
    }

    mutating func timerFired(_ timer: ValkeyTimer) -> TimerFiredAction {
        switch timer.useCase {
        case .nextTopologyDiscovery:
            switch self.state {
            case .uninitialized:
                preconditionFailure("Invalid state: \(self.state)")
            case .running:
                break
            case .shutdown:
                return .doNothing
            }

            switch self.topologyRefreshState {
            case .notRefreshing, .refreshing:
                return .doNothing
            case .waitingForNextRefresh(let timerState):
                guard timer.timerID == timerState.id else { return .doNothing }
                self.topologyRefreshState = .refreshing
                return .runRole
            }
        }
    }

    enum RegisterTimerCancellationTokenAction {
        case cancelTimer(TimerCancellationToken)
        case doNothing
    }

    mutating func registerTimerCancellationToken(_ token: TimerCancellationToken, for timer: ValkeyTimer) -> RegisterTimerCancellationTokenAction {
        switch timer.useCase {
        case .nextTopologyDiscovery:
            switch self.state {
            case .shutdown, .uninitialized:
                return .cancelTimer(token)
            case .running:
                break
            }

            switch self.topologyRefreshState {
            case .notRefreshing, .refreshing:
                return .cancelTimer(token)
            case .waitingForNextRefresh(var timerState):
                guard timer.timerID == timerState.id else { return .cancelTimer(token) }
                timerState.cancellationToken = token
                self.topologyRefreshState = .waitingForNextRefresh(timerState)
                return .doNothing
            }
        }
    }

    struct TopologyRefreshAction {
        enum NextAction: Equatable {
            case refreshTopology
            case startTimer(ValkeyTimer)
            case doNothing
        }
        var nextAction: NextAction = .doNothing
        var clientsToShutdown: [ConnectionPool] = []
        var clientsToRun: [ConnectionPool] = []
    }

    mutating func topologyRefreshSucceeded(primary: ValkeyServerAddress?, replicas: [ValkeyServerAddress]?) -> TopologyRefreshAction {
        // If we are shutdown ignore
        guard case .running(let nodes) = self.state else {
            return .init()
        }
        switch self.topologyRefreshState {
        case .notRefreshing, .waitingForNextRefresh:
            preconditionFailure("Invalid state: \(self.topologyRefreshState)")

        case .refreshing:
            let newPrimary = primary ?? nodes.primary
            let newReplicas = replicas ?? []
            let rebuildPools = (replicas != nil)
            var nodeDescriptions = [
                ValkeyClientNodeDescription(address: newPrimary)
            ]
            nodeDescriptions.append(
                contentsOf: newReplicas.lazy.map { ValkeyClientNodeDescription(address: $0) }
            )
            let newNodes = ValkeyNodeIDs(primary: newPrimary, replicas: newReplicas)
            self.state = .running(newNodes)
            let action = self.runningClients.updateNodes(nodeDescriptions, removeUnmentionedPools: rebuildPools)
            // if primary was set but no replicas were set then refresh topology to get replica list
            if primary != nil, replicas == nil {
                return .init(
                    nextAction: .refreshTopology,
                    clientsToShutdown: action.poolsToShutdown,
                    clientsToRun: action.poolsToRun.map { $0.0 }
                )
            } else {
                let refreshTimerID = self.nextTimerID()
                self.topologyRefreshState = .waitingForNextRefresh(.init(id: refreshTimerID))
                return .init(
                    nextAction: .startTimer(
                        .init(
                            timerID: refreshTimerID,
                            useCase: .nextTopologyDiscovery,
                            duration: self.configuration.topologyRefreshInterval
                        )
                    ),
                    clientsToShutdown: action.poolsToShutdown,
                    clientsToRun: action.poolsToRun.map { $0.0 }
                )
            }
        }
    }

    func topologyRefreshFailed() {

    }

    private mutating func nextTimerID() -> Int {
        defer { self._nextTimerID += 1 }
        return self._nextTimerID
    }
}
