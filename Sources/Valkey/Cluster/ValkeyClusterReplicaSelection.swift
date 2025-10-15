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
extension ValkeyClientConfiguration.ReadOnlyReplicaSelection {
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
