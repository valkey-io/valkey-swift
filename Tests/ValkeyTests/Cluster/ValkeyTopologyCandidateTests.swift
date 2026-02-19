//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import Testing
import Valkey

@Suite("Topology Candidate Tests")
struct ValkeyTopologyCandidateTests {

    @Test("Ensure the same description in different order is considered equal")
    @available(valkeySwift 1.0, *)
    func ensureOrderDoesntMatter() throws {
        let description = ValkeyClusterDescription([
            .init(
                slots: [0...2000, 8000...12000],
                nodes: [
                    .init(
                        id: "node1",
                        port: nil,
                        tlsPort: 6379,
                        ip: "192.168.12.1",
                        hostname: "node1",
                        endpoint: "node1",
                        role: .replica,
                        replicationOffset: 123,
                        health: .online
                    ),
                    .init(
                        id: "node2",
                        port: nil,
                        tlsPort: 6379,
                        ip: "192.168.12.2",
                        hostname: "node2",
                        endpoint: "node2",
                        role: .replica,
                        replicationOffset: 123,
                        health: .online
                    ),
                    .init(
                        id: "node3",
                        port: nil,
                        tlsPort: 6379,
                        ip: "192.168.12.3",
                        hostname: "node3",
                        endpoint: "node3",
                        role: .primary,
                        replicationOffset: 123,
                        health: .online
                    ),
                ]
            ),
            .init(
                slots: [3000...8000, 12000...13000],
                nodes: [
                    .init(
                        id: "node4",
                        port: nil,
                        tlsPort: 6379,
                        ip: "192.168.12.4",
                        hostname: "node4",
                        endpoint: "node4",
                        role: .replica,
                        replicationOffset: 123,
                        health: .online
                    ),
                    .init(
                        id: "node5",
                        port: nil,
                        tlsPort: 6379,
                        ip: "192.168.12.5",
                        hostname: "node5",
                        endpoint: "node5",
                        role: .replica,
                        replicationOffset: 123,
                        health: .online
                    ),
                    .init(
                        id: "node6",
                        port: nil,
                        tlsPort: 6379,
                        ip: "192.168.12.6",
                        hostname: "node6",
                        endpoint: "node6",
                        role: .primary,
                        replicationOffset: 123,
                        health: .online
                    ),
                ]
            ),
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

    @Test("Two primary nodes for the same shard throws")
    @available(valkeySwift 1.0, *)
    func twoPrimaryNodesForTheSameShardThrows() {
        let description = ValkeyClusterDescription([
            .init(
                slots: [0...2000, 8000...12000],
                nodes: [
                    .init(
                        id: "node1",
                        port: nil,
                        tlsPort: 6379,
                        ip: "192.168.12.1",
                        hostname: "node1",
                        endpoint: "node1",
                        role: .replica,
                        replicationOffset: 123,
                        health: .online
                    ),
                    .init(
                        id: "node2",
                        port: nil,
                        tlsPort: 6379,
                        ip: "192.168.12.2",
                        hostname: "node2",
                        endpoint: "node2",
                        role: .primary,
                        replicationOffset: 123,
                        health: .online
                    ),
                    .init(
                        id: "node3",
                        port: nil,
                        tlsPort: 6379,
                        ip: "192.168.12.3",
                        hostname: "node3",
                        endpoint: "node3",
                        role: .primary,
                        replicationOffset: 123,
                        health: .online
                    ),
                ]
            )
        ])

        #expect(throws: ValkeyClusterError.shardHasMultiplePrimaryNodes) { try ValkeyTopologyCandidate(description) }
    }

    @Test("No primary node for a shard throws")
    @available(valkeySwift 1.0, *)
    func noPrimaryNodeForAShardThrows() {
        let description = ValkeyClusterDescription([
            .init(
                slots: [0...2000, 8000...12000],
                nodes: [
                    .init(
                        id: "node1",
                        port: nil,
                        tlsPort: 6379,
                        ip: "192.168.12.1",
                        hostname: "node1",
                        endpoint: "node1",
                        role: .replica,
                        replicationOffset: 123,
                        health: .online
                    ),
                    .init(
                        id: "node2",
                        port: nil,
                        tlsPort: 6379,
                        ip: "192.168.12.2",
                        hostname: "node2",
                        endpoint: "node2",
                        role: .replica,
                        replicationOffset: 123,
                        health: .online
                    ),
                    .init(
                        id: "node3",
                        port: nil,
                        tlsPort: 6379,
                        ip: "192.168.12.3",
                        hostname: "node3",
                        endpoint: "node3",
                        role: .replica,
                        replicationOffset: 123,
                        health: .online
                    ),
                ]
            )
        ])

        #expect(throws: ValkeyClusterError.shardIsMissingPrimaryNode) { try ValkeyTopologyCandidate(description) }
    }

    @Test("Failover with one failed and one online primary succeeds")
    @available(valkeySwift 1.0, *)
    func failoverWithOneFailedAndOneOnlinePrimarySucceeds() throws {
        let description = ValkeyClusterDescription([
            .init(
                slots: [0...2000, 8000...12000],
                nodes: [
                    .init(
                        id: "node1",
                        port: nil,
                        tlsPort: 6379,
                        ip: "192.168.12.1",
                        hostname: "node1",
                        endpoint: "node1",
                        role: .replica,
                        replicationOffset: 123,
                        health: .online
                    ),
                    .init(
                        id: "node2-old-primary",
                        port: nil,
                        tlsPort: 6379,
                        ip: "192.168.12.2",
                        hostname: "node2",
                        endpoint: "node2",
                        role: .primary,
                        replicationOffset: 123,
                        health: .fail  // Failed primary
                    ),
                    .init(
                        id: "node3-new-primary",
                        port: nil,
                        tlsPort: 6379,
                        ip: "192.168.12.3",
                        hostname: "node3",
                        endpoint: "node3",
                        role: .primary,
                        replicationOffset: 123,
                        health: .online  // New primary after failover
                    ),
                ]
            )
        ])
        // Should not throw - this is a valid failover scenario
        let candidate = try ValkeyTopologyCandidate(description)

        // Verify it selected the online primary (node3)
        #expect(candidate.shards.count == 1)
        #expect(candidate.shards[0].primary.endpoint == "node3")
    }
}
