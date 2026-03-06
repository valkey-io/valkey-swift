//
// This source file is part of the valkey-swift project
// Copyright (c) 2025-2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

@usableFromInline
@available(valkeySwift 1.0, *)
struct ValkeySentinelClientStateMachine<
    ConnectionPool: ValkeyNodeConnectionPool,
    ConnectionPoolFactory: ValkeyNodeConnectionPoolFactory,
    WaiterToken: Sendable,
    TimerCancellationToken: Sendable
>
where ConnectionPoolFactory.ConnectionPool == ConnectionPool, ConnectionPoolFactory.NodeDescription == ValkeyClusterNodeClientFactory.NodeDescription
{
    /// Configuration
    @usableFromInline
    struct Configuration {}
    /// current state
    @usableFromInline
    enum State {
        @usableFromInline
        struct UnavailableState {
            var waiters: [WaiterToken]
            let error: (any Error)?
        }
        @usableFromInline
        struct HealthyState {
            let nodes: ValkeySentinelNodes
        }
        @usableFromInline
        struct DegradedState {
            let nodes: ValkeySentinelNodes
        }
        case unavailable(UnavailableState)
        case degraded(DegradedState)
        case healthy(HealthyState)
        case shutdown
    }
    @usableFromInline
    var state: State
    @usableFromInline
    var runningClients: ValkeyRunningClientsStateMachine<ConnectionPool, ConnectionPoolFactory>

    init(poolFactory: ConnectionPoolFactory, configuration: Configuration) {
        self.state = .unavailable(.init(waiters: [], error: nil))
        self.runningClients = .init(poolFactory: poolFactory)
    }

    func getInitialVoters() -> [ValkeyTopologyVoter<ConnectionPool>] {
        switch self.state {
        case .unavailable, .shutdown:
            return []
        case .degraded(let degradedState):
            return degradedState.nodes.nodes.compactMap { (element) -> ValkeyTopologyVoter<ConnectionPool>? in
                self.runningClients[element.id].map { .init(client: $0.pool, nodeID: $0.nodeID) }
            }
        case .healthy(let healthyState):
            return healthyState.nodes.nodes.compactMap { (element) -> ValkeyTopologyVoter<ConnectionPool>? in
                self.runningClients[element.id].map { .init(client: $0.pool, nodeID: $0.nodeID) }
            }
        }
    }

    func getSentinelClients() -> [ConnectionPool] {
        switch self.state {
        case .unavailable, .shutdown:
            return []
        case .degraded(let degradedState):
            return degradedState.nodes.nodes.compactMap { (element) -> ConnectionPool? in
                self.runningClients[element.id].map { $0.pool }
            }
        case .healthy(let healthyState):
            return healthyState.nodes.nodes.compactMap { (element) -> ConnectionPool? in
                self.runningClients[element.id].map { $0.pool }
            }
        }
    }

    struct UpdateNodesAction {
        let clientsToRun: [ConnectionPool]
        let clientsToShutdown: [ConnectionPool]
        let voters: [ValkeyTopologyVoter<ConnectionPool>]
    }
    mutating func updateSentinelNodes(_ nodes: ValkeySentinelNodes) -> UpdateNodesAction {
        let action = self.runningClients.updateNodes(nodes.nodes, removeUnmentionedPools: false)
        return .init(
            clientsToRun: action.poolsToRun.map { $0.0 },
            clientsToShutdown: action.poolsToShutdown,
            voters: action.poolsToRun.map { .init(client: $0.0, nodeID: $0.1) }
        )
    }

    struct DiscoverySucceededAction {
        let waitersToSucceed: [WaiterToken]
        let clientsToRun: [ConnectionPool]
        let clientsToShutdown: [ConnectionPool]
    }
    mutating func topologyDiscoverySucceeded(_ nodes: ValkeySentinelNodes) -> DiscoverySucceededAction {
        switch self.state {
        case .unavailable(let unavailableState):
            self.state = .healthy(.init(nodes: nodes))
            let action = self.runningClients.updateNodes(nodes.nodes, removeUnmentionedPools: true)
            return .init(
                waitersToSucceed: unavailableState.waiters,
                clientsToRun: action.poolsToRun.map { $0.0 },
                clientsToShutdown: action.poolsToShutdown
            )

        case .degraded:
            self.state = .healthy(.init(nodes: nodes))
            let action = self.runningClients.updateNodes(nodes.nodes, removeUnmentionedPools: true)
            return .init(
                waitersToSucceed: [],
                clientsToRun: action.poolsToRun.map { $0.0 },
                clientsToShutdown: action.poolsToShutdown
            )

        case .healthy:
            self.state = .healthy(.init(nodes: nodes))
            let action = self.runningClients.updateNodes(nodes.nodes, removeUnmentionedPools: true)
            return .init(
                waitersToSucceed: [],
                clientsToRun: action.poolsToRun.map { $0.0 },
                clientsToShutdown: action.poolsToShutdown
            )
        case .shutdown:
            preconditionFailure()
        }
    }

    struct DiscoveryFailedAction {
        let waitersToFail: [WaiterToken]
    }

    mutating func topologyDiscoveryFailed(error: any Error) -> DiscoveryFailedAction {
        switch self.state {
        case .unavailable(let unavailableState):
            if unavailableState.error == nil {
                self.state = .unavailable(.init(waiters: unavailableState.waiters, error: error))
            }
            return .init(waitersToFail: unavailableState.waiters)
        case .degraded:
            return .init(waitersToFail: [])

        case .healthy(let healthyState):
            self.state = .degraded(.init(nodes: healthyState.nodes))
            return .init(waitersToFail: [])

        case .shutdown:
            return .init(waitersToFail: [])
        }
    }

    enum WaitForDiscoveryAction {
        case complete
        case fail(ValkeyClientError)
        case doNothing
    }
    mutating func waitForDiscovery(_ waiter: WaiterToken) -> WaitForDiscoveryAction {
        switch self.state {
        case .unavailable(var unavailableState):
            unavailableState.waiters.append(waiter)
            self.state = .unavailable(unavailableState)
            return .doNothing
        case .degraded:
            return .complete
        case .healthy:
            return .complete
        case .shutdown:
            return .fail(.init(.clientIsShutDown))
        }
    }
}
