//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey project
//
// Copyright (c) 2025 the swift-valkey authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See swift-valkey/CONTRIBUTORS.txt for the list of swift-valkey authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Testing
import Valkey

@Suite("Topology Candidate Tests")
struct ValkeyTopologyCandidateTests {

    @Test("Ensure the same description in different order is considered equal")
    func ensureOrderDoesntMatter() throws {
        let description = ValkeyClusterDescription([
            .init(
                slots: [0...2000, 8000...12000],
                nodes: [
                    .init(id: "node1", port: nil, tlsPort: 6379, ip: "192.168.12.1", hostname: "node1", endpoint: "node1", role: .replica, replicationOffset: 123, health: .online),
                    .init(id: "node2", port: nil, tlsPort: 6379, ip: "192.168.12.2", hostname: "node2", endpoint: "node2", role: .replica, replicationOffset: 123, health: .online),
                    .init(id: "node3", port: nil, tlsPort: 6379, ip: "192.168.12.3", hostname: "node3", endpoint: "node3", role: .master, replicationOffset: 123, health: .online),
                ]
            ),
            .init(
                slots: [3000...8000, 12000...13000],
                nodes: [
                    .init(id: "node4", port: nil, tlsPort: 6379, ip: "192.168.12.4", hostname: "node4", endpoint: "node4", role: .replica, replicationOffset: 123, health: .online),
                    .init(id: "node5", port: nil, tlsPort: 6379, ip: "192.168.12.5", hostname: "node5", endpoint: "node5", role: .replica, replicationOffset: 123, health: .online),
                    .init(id: "node6", port: nil, tlsPort: 6379, ip: "192.168.12.6", hostname: "node6", endpoint: "node6", role: .master, replicationOffset: 123, health: .online),
                ]
            )
        ])

        var copy1 = description
        copy1.shards = description.shards.reversed()
        copy1.shards[0].nodes = description.shards[0].nodes.reversed()
        copy1.shards[1].nodes = description.shards[1].nodes.reversed()
        copy1.shards[0].slots = description.shards[0].slots.reversed()
        copy1.shards[1].slots = description.shards[1].slots.reversed()

        let candidate1 = try ValkeyTopologyCandidate(description)
        let candidate2 = try ValkeyTopologyCandidate(copy1)

        #expect(candidate1 == candidate2)
    }

    @Test("Two master nodes for the same shard throws")
    func twoMasterNodesForTheSameShardThrows() {
        let description = ValkeyClusterDescription([
            .init(
                slots: [0...2000, 8000...12000],
                nodes: [
                    .init(id: "node1", port: nil, tlsPort: 6379, ip: "192.168.12.1", hostname: "node1", endpoint: "node1", role: .replica, replicationOffset: 123, health: .online),
                    .init(id: "node2", port: nil, tlsPort: 6379, ip: "192.168.12.2", hostname: "node2", endpoint: "node2", role: .master, replicationOffset: 123, health: .online),
                    .init(id: "node3", port: nil, tlsPort: 6379, ip: "192.168.12.3", hostname: "node3", endpoint: "node3", role: .master, replicationOffset: 123, health: .online),
                ]
            ),
        ])

        #expect(throws: ValkeyClusterError.shardHasMultipleMasterNodes) { try ValkeyTopologyCandidate(description) }
    }

    @Test("No master node for a shard throws")
    func noMasterNodeForAShardThrows() {
        let description = ValkeyClusterDescription([
            .init(
                slots: [0...2000, 8000...12000],
                nodes: [
                    .init(id: "node1", port: nil, tlsPort: 6379, ip: "192.168.12.1", hostname: "node1", endpoint: "node1", role: .replica, replicationOffset: 123, health: .online),
                    .init(id: "node2", port: nil, tlsPort: 6379, ip: "192.168.12.2", hostname: "node2", endpoint: "node2", role: .replica, replicationOffset: 123, health: .online),
                    .init(id: "node3", port: nil, tlsPort: 6379, ip: "192.168.12.3", hostname: "node3", endpoint: "node3", role: .replica, replicationOffset: 123, health: .online),
                ]
            ),
        ])

        #expect(throws: ValkeyClusterError.shardIsMissingMasterNode) { try ValkeyTopologyCandidate(description) }
    }
}
