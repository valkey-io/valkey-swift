//
// This source file is part of the valkey-swift project
// Copyright (c) 2025-2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

@usableFromInline
struct ValkeySentinelNodes: Equatable, Sendable {
    let nodes: [ValkeyNodeDescription]

    /// Initial Sentinel node collection
    init(_ nodes: some Collection<ValkeyNodeDescription>) {
        let nodes = nodes.map { ValkeyNodeDescription(endpoint: $0.endpoint, port: $0.port) }
        self.nodes = nodes.sorted(by: { $0.id.hashValue < $1.id.hashValue })
    }
}

extension ValkeySentinelNodes: ValkeyTopologyElectable {
    // Calculate the needed votes as a simple majority of all nodes across all shards
    package var votesNeeded: Int { self.nodes.count / 2 + 1 }

    // Calculate the hash by hashing the important elements of each node
    package var topologyHash: Int {
        var hasher = Hasher()
        for node in nodes {
            hasher.combine(node.endpoint)
            hasher.combine(node.port)
        }
        return hasher.finalize()
    }
}
