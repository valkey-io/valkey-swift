//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

@usableFromInline
@available(valkeySwift 1.0, *)
struct ValkeyClientStateMachine<
    ConnectionPool: ValkeyNodeConnectionPool,
    ConnectionPoolFactory: ValkeyNodeConnectionPoolFactory,
    TimerCancellationToken: Sendable
> where ConnectionPoolFactory.ConnectionPool == ConnectionPool, ConnectionPoolFactory.NodeDescription == ValkeyNodeClientFactory.NodeDescription {
    /// State machine configuration
    @usableFromInline
    struct Configuration {
        let findReplicas: Bool
        let topologyRefreshInterval: Duration
        var backoffParameters: ValkeyClientConfiguration.RetryParameters
    }
    /// State machine timer description
    @usableFromInline
    struct Timer: Sendable {
        let id: Int
        var cancellationToken: TimerCancellationToken?
    }
    /// Current state
    @usableFromInline
    enum State {
        case uninitialized
        case running(ValkeyNodeIDs<ValkeyServerAddress>)
        case shutdown
    }
    /// Topology refresh state
    @usableFromInline
    enum TopologyRefreshState {
        @usableFromInline
        struct WaitingContext {
            var timer: Timer
        }
        @usableFromInline
        struct RefreshContext {
            var attempts: Int

            init(attempts: Int = 0) {
                self.attempts = attempts
            }
        }
        case notRefreshing
        case waitingForNextRefresh(WaitingContext)
        case refreshing(RefreshContext)
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
            topologyRefreshInterval: configuration.standalone.topologyRefreshInternal,
            backoffParameters: configuration.standalone.topologyDiscoveryBackoffParameters
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
                self.topologyRefreshState = .refreshing(.init())
                return SetPrimaryAction(nextAction: .refreshTopology(nil), nodeToRun: client)
            case .refreshing:
                return .init(nodeToRun: client)
            case .waitingForNextRefresh(let waitingState):
                self.topologyRefreshState = .refreshing(.init())
                return SetPrimaryAction(nextAction: .refreshTopology(waitingState.timer.cancellationToken), nodeToRun: client)
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
            case .waitingForNextRefresh(let waitingState):
                guard timer.timerID == waitingState.timer.id else { return .doNothing }
                self.topologyRefreshState = .refreshing(.init())
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
            case .waitingForNextRefresh(var waitingState):
                guard timer.timerID == waitingState.timer.id else { return .cancelTimer(token) }
                waitingState.timer.cancellationToken = token
                self.topologyRefreshState = .waitingForNextRefresh(waitingState)
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

    /// Input to topologyRefreshSucceeded
    enum TopologyRefreshInput {
        /// We are connected to a primary and here is a list of its replicas
        case primary(replicas: [ValkeyServerAddress])
        /// We are connected to a replica and here is its primary
        case replica(primary: ValkeyServerAddress)
    }

    /// Report topology refresh
    ///
    /// Depending on what node we are connected to we either get a primary node or a list of replicas
    mutating func topologyRefreshSucceeded(_ topology: TopologyRefreshInput) -> TopologyRefreshAction {
        // If we are shutdown ignore
        guard case .running(let nodes) = self.state else {
            return .init()
        }

        switch self.topologyRefreshState {
        case .notRefreshing, .waitingForNextRefresh:
            preconditionFailure("Invalid state: \(self.topologyRefreshState)")

        case .refreshing:
            switch topology {
            case .primary(let replicas):
                var nodeDescriptions = [
                    ValkeyClientNodeDescription(address: nodes.primary)
                ]
                nodeDescriptions.append(
                    contentsOf: replicas.lazy.map { ValkeyClientNodeDescription(address: $0) }
                )
                let newNodes = ValkeyNodeIDs(primary: nodes.primary, replicas: replicas)
                self.state = .running(newNodes)
                let action = self.runningClients.updateNodes(nodeDescriptions, removeUnmentionedPools: true)
                let refreshTimerID = self.nextTimerID()
                self.topologyRefreshState = .waitingForNextRefresh(.init(timer: .init(id: refreshTimerID)))
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

            case .replica(let primary):
                let nodeDescriptions = [
                    ValkeyClientNodeDescription(address: primary)
                ]
                let newNodes = ValkeyNodeIDs(primary: primary, replicas: [])
                self.state = .running(newNodes)
                let action = self.runningClients.updateNodes(nodeDescriptions, removeUnmentionedPools: false)
                return .init(
                    nextAction: .refreshTopology,
                    clientsToShutdown: action.poolsToShutdown,
                    clientsToRun: action.poolsToRun.map { $0.0 }
                )
            }
        }
    }

    struct TopologyRefreshFailedAction {
        let retryTimer: ValkeyTimer?
    }

    mutating func topologyRefreshFailed() -> TopologyRefreshFailedAction {
        // If we are shutdown ignore
        guard case .running = self.state else {
            return .init(retryTimer: nil)
        }
        switch self.topologyRefreshState {
        case .notRefreshing, .waitingForNextRefresh:
            preconditionFailure("Invalid state: \(self.topologyRefreshState)")

        case .refreshing(var refreshState):
            refreshState.attempts += 1
            self.topologyRefreshState = .refreshing(refreshState)
            if let backoff = self.configuration.backoffParameters.calculateWaitTime(attempt: refreshState.attempts - 1) {
                let refreshTimerID = self.nextTimerID()
                return .init(
                    retryTimer: .init(
                        timerID: refreshTimerID,
                        useCase: .nextTopologyDiscovery,
                        duration: backoff
                    )
                )
            } else {
                self.topologyRefreshState = .notRefreshing
                return .init(retryTimer: nil)
            }
        }
    }

    private mutating func nextTimerID() -> Int {
        defer { self._nextTimerID += 1 }
        return self._nextTimerID
    }
}

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
