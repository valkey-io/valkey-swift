//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

@usableFromInline
protocol SelectableNodeIdentifier: Sendable {
    var availabilityZone: String? { get }
}

@usableFromInline
package indirect enum ValkeyNodeSelection: Sendable {
    case primary
    case cycleReplicas(Int)
    case cycleAllNodes(Int)
    case az(String, Int, ValkeyNodeSelection)

    /// Select node from node ids
    /// - Parameter nodeIDs: Primary and replica nodes
    /// - Returns: ID of selected node
    @usableFromInline
    func select<ID: SelectableNodeIdentifier>(nodeIDs: ValkeyNodeIDs<ID>) -> ID {
        switch self {
        case .primary:
            return nodeIDs.primary
        case .cycleReplicas(let index):
            guard nodeIDs.replicas.count > 0 else { return nodeIDs.primary }
            return nodeIDs.replicas[index % nodeIDs.replicas.count]
        case .cycleAllNodes(let index):
            let index = index % (nodeIDs.replicas.count + 1)
            if index == 0 {
                return nodeIDs.primary
            } else {
                return nodeIDs.replicas[index - 1]
            }
        case .az(let zone, let index, let backup):
            let replicaNodesInAvailabilityZone = nodeIDs.replicas.filter { $0.availabilityZone == zone }
            if nodeIDs.primary.availabilityZone == zone {
                let index = index % (replicaNodesInAvailabilityZone.count + 1)
                if index == 0 {
                    return nodeIDs.primary
                } else {
                    return replicaNodesInAvailabilityZone[index - 1]
                }
            } else {
                guard replicaNodesInAvailabilityZone.count > 0 else { return backup.select(nodeIDs: nodeIDs) }
                return replicaNodesInAvailabilityZone[index % replicaNodesInAvailabilityZone.count]
            }
        }
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyClientConfiguration.ReadOnlyCommandNodeSelection {
    /// Convert from ``ValkeyClientConfiguration/ReadOnlyCommandNodeSelection`` to node selection
    @usableFromInline
    var nodeSelection: ValkeyNodeSelection {
        switch self.value {
        case .primary:
            .primary
        case .cycleReplicas:
            .cycleReplicas(Self.idGenerator.next())
        case .cycleAllNodes:
            .cycleAllNodes(Self.idGenerator.next())
        case .az(let zone, let backup):
            .az(zone, Self.idGenerator.next(), backup.nodeSelection)
        }
    }

    static let idGenerator: IDGenerator = .init()
}

extension ValkeyServerAddress: SelectableNodeIdentifier {
    @usableFromInline
    var availabilityZone: String? { nil }
}
