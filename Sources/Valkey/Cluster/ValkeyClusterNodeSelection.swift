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
    case cycleAllNodes(Int)

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
        case .cycleAllNodes(let index):
            let index = index % (nodeIDs.replicas.count + 1)
            if index == 0 {
                return nodeIDs.primary
            } else {
                return nodeIDs.replicas[index - 1]
            }
        }
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyClientConfiguration.ReadOnlyCommandNodeSelection {
    /// Convert from ``ValkeyClientConfiguration/ReadOnlyCommandNodeSelection`` to node selection
    @usableFromInline
    var clusterNodeSelection: ValkeyClusterNodeSelection {
        switch self.value {
        case .primary:
            .primary
        case .cycleReplicas:
            .cycleReplicas(Self.idGenerator.next())
        case .cycleAllNodes:
            .cycleAllNodes(Self.idGenerator.next())
        }
    }

    static let idGenerator: IDGenerator = .init()
}
