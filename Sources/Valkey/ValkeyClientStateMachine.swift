//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

@available(valkeySwift 1.0, *)
struct ValkeyClientStateMachine<
    ConnectionPool: ValkeyNodeConnectionPool,
    ConnectionPoolFactory: ValkeyNodeConnectionPoolFactory
> where ConnectionPoolFactory.ConnectionPool == ConnectionPool {
    /// Represents the mapping of primary and replica nodes.
    @usableFromInline
    package struct ValkeyNodeIDs: Hashable, Sendable {
        package var nodes: [ValkeyNodeID]

        /// The primary node responsible for handling write operations for this shard.
        @usableFromInline
        package var primary: ValkeyNodeID { self.nodes.first! }

        /// The replica nodes that maintain copies of the primary's data.
        /// Replicas can handle read operations but not writes.
        @usableFromInline
        package var replicas: ArraySlice<ValkeyNodeID> { self.nodes.dropFirst() }

        /// Creates a new node mapping with the specified primary and optional replicas.
        ///
        /// - Parameters:
        ///   - primary: The primary node ID for this shard
        ///   - replicas: An array of replica node IDs, defaults to empty
        package init(primary: ValkeyNodeID, replicas: [ValkeyNodeID] = []) {
            self.nodes = [primary] + replicas
        }
    }

    var runningClients: ValkeyRunningClientsStateMachine<ConnectionPool, ConnectionPoolFactory>
    var nodes: ValkeyNodeIDs

    func getNode(readOnly: Bool) -> ConnectionPool {
        let nodeID =
            if readOnly {
                nodes.nodes[Int.random(in: 0..<nodes.nodes.count)]
            } else {
                nodes.primary
            }
        if let pool = self.runningClients[nodeID]?.pool {
            return pool
        } else {
            precondition(false)
        }
    }

    enum AddPrimaryAction {
        case runNodeAndFindReplicas(ConnectionPool)
        case findReplicas
        case doNothing
    }
    mutating func addPrimary(nodeID: ValkeyNodeID) -> AddPrimaryAction {
        guard self.nodes.primary != nodeID else { return .doNothing }
        self.nodes = .init(primary: nodeID)
        let action = self.runningClients.addNode(.init(endpoint: nodeID.endpoint, port: nodeID.port, useTLS: false))
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
        var nodes = [ValkeyNodeDescription(endpoint: self.nodes.primary.endpoint, port: self.nodes.primary.port, useTLS: false)]
        nodes.append(contentsOf: nodeIDs.lazy.map { .init(endpoint: $0.endpoint, port: $0.port, useTLS: false) })
        let action = self.runningClients.updateNodes(nodes, removeUnmentionedPools: true)
        return .init(poolsToShutdown: action.poolsToShutdown, poolsToRun: action.poolsToRun)
    }
}
