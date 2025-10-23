//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

@usableFromInline
package enum ValkeyClusterNodeSelection: Sendable {
    case primary
    case cycleReplicas(Int)

    /// Select node from node ids
    /// - Parameter nodeIDs: Primary and replica nodes
    /// - Returns: ID of selected node
    @usableFromInline
    func select(nodeIDs: ValkeyShardNodeIDs) -> ValkeyNodeID {
        switch self {
        case .primary:
            return nodeIDs.primary
        case .cycleReplicas(let index):
            guard nodeIDs.replicas.count > 0 else { return nodeIDs.primary }
            return nodeIDs.replicas[index % nodeIDs.replicas.count]
        }
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyClientConfiguration.ReadOnlyReplicaSelection {
    /// Convert from read only replica selection to node selection
    @usableFromInline
    var clusterNodeSelection: ValkeyClusterNodeSelection {
        switch self.value {
        case .none:
            .primary
        case .cycle:
            .cycleReplicas(Self.idGenerator.next())
        }
    }

    static let idGenerator: IDGenerator = .init()
}
