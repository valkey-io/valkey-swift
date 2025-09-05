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
    ConnectionPoolFactory: ValkeyNodeConnectionPoolFactory
> where ConnectionPoolFactory.ConnectionPool == ConnectionPool {
    /// Represents the mapping of primary and replica nodes.
    @usableFromInline
    package struct ValkeyNodeIDs: Hashable, Sendable {
        /// The primary node responsible for handling write operations for this shard.
        @usableFromInline
        package var primary: ValkeyNodeID

        /// The replica nodes that maintain copies of the primary's data.
        /// Replicas can handle read operations but not writes.
        @usableFromInline
        package var replicas: [ValkeyNodeID]

        /// Creates a new shard node mapping with the specified primary and optional replicas.
        ///
        /// - Parameters:
        ///   - primary: The primary node ID for this shard
        ///   - replicas: An array of replica node IDs, defaults to empty
        package init(primary: ValkeyNodeID, replicas: [ValkeyNodeID] = []) {
            self.primary = primary
            self.replicas = replicas
        }
    }

    @usableFromInline
    enum State {
        case uninitialized
        case running(ValkeyNodeIDs)
    }
    @usableFromInline
    var runningClients: ValkeyRunningClientsStateMachine<ConnectionPool, ConnectionPoolFactory>
    @usableFromInline
    var state: State

    init(poolFactory: ConnectionPoolFactory) {
        self.runningClients = .init(poolFactory: poolFactory)
        self.state = .uninitialized
    }

    @usableFromInline
    func getNode() -> ConnectionPool {
        guard case .running(let nodes) = self.state else {
            preconditionFailure("Cannot get a node if the client statemachine isn't initialized")
        }
        let nodeID = nodes.primary
        if let pool = self.runningClients[nodeID]?.pool {
            return pool
        } else {
            precondition(false)
        }
    }

    enum SetPrimaryAction {
        case runNodeAndFindReplicas(ConnectionPool)
        case findReplicas
        case doNothing
    }
    mutating func setPrimary(nodeID: ValkeyNodeID) -> SetPrimaryAction {
        let nodes = ValkeyNodeIDs(primary: nodeID)
        let action = self.runningClients.addNode(.init(endpoint: nodeID.endpoint, port: nodeID.port, useTLS: false))
        self.state = .running(nodes)
        return switch action {
        case .doNothing: .findReplicas
        case .runNode(let pool): .runNodeAndFindReplicas(pool)
        }
    }

    struct AddReplicasAction {
        var poolsToShutdown: [ConnectionPool]
        var poolsToRun: [(ConnectionPool, ValkeyNodeID)]
    }

    mutating func addReplicas(nodeIDs: [ValkeyNodeID]) -> AddReplicasAction {
        switch self.state {
        case .uninitialized:
            preconditionFailure("Cannot get a node if the client statemachine isn't initialized")
        case .running(let nodes):
            var nodeDescriptions = [ValkeyNodeDescription(endpoint: nodes.primary.endpoint, port: nodes.primary.port, useTLS: false)]
            nodeDescriptions.append(contentsOf: nodeIDs.lazy.map { .init(endpoint: $0.endpoint, port: $0.port, useTLS: false) })
            let action = self.runningClients.updateNodes(nodeDescriptions, removeUnmentionedPools: true)
            let newNodes = ValkeyNodeIDs(primary: nodes.primary, replicas: nodeIDs)
            self.state = .running(newNodes)
            return .init(poolsToShutdown: action.poolsToShutdown, poolsToRun: action.poolsToRun)
        }
    }
}
