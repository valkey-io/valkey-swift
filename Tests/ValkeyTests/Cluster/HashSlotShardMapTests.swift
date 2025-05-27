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

@Suite
struct HashSlotShardMapTests {

    @Test
    func testShardMap() {
        var map = HashSlotShardMap()

        var shard1 = ValkeyClusterDescription.Shard(
            slots: [0...5, 100...1024],
            nodes: [
                .init(
                    id: "foo",
                    port: 5,
                    tlsPort: 6,
                    ip: "127.0.0.1",
                    hostname: "mockHostname",
                    endpoint: "mockEndpoint",
                    role: .master,
                    replicationOffset: 22,
                    health: .online
                )
            ]
        )
        var shard2 = ValkeyClusterDescription.Shard(
            slots: [12...80],
            nodes: [
                .init(
                    id: "foo2",
                    port: 8,
                    tlsPort: 9,
                    ip: "127.0.0.1",
                    hostname: "mockHostname2",
                    endpoint: "mockEndpoint2",
                    role: .master,
                    replicationOffset: 23,
                    health: .online
                )
            ]
        )
        map.updateCluster([shard1, shard2])

        let expectedShard1: ValkeyShardNodeIDs = [.init(endpoint: "mockEndpoint", port: 6)]
        let expectedShard2: ValkeyShardNodeIDs = [.init(endpoint: "mockEndpoint2", port: 9)]

        #expect(map[3] == expectedShard1)
        #expect(map[6] == nil)
        #expect(map[150] == expectedShard1)
        #expect(map[76] == expectedShard2)

        shard1.slots = [16...16, 18...18]
        shard2.slots = [17...17]

        map.updateCluster([shard1, shard2])

        #expect(map[3] == nil)
        #expect(map[16] == expectedShard1)
        #expect(map[17] == expectedShard2)
        #expect(map[18] == expectedShard1)
        #expect(map[150] == nil)
        #expect(map[76] == nil)
    }
    
    @Test
    func testEmptyCluster() {
        // Test handling of an empty cluster
        var map = HashSlotShardMap()
        map.updateCluster([])
        
        // All slots should be unassigned
        #expect(map[0] == nil)
        #expect(map[HashSlot.max] == nil)
        
        // Attempting to get a nodeID for a slot should throw
        #expect(throws: ValkeyClusterError.clusterIsMissingSlotAssignment) { try map.nodeID(for: [0]) }
    }
    
    @Test
    func testNodeIDForEmptySlotsCollection() {
        // Set up a non-empty cluster
        var map = HashSlotShardMap()
        let shard = ValkeyClusterDescription.Shard(
            slots: [0...5],
            nodes: [
                .init(
                    id: "node1",
                    port: 5,
                    tlsPort: 6,
                    ip: "127.0.0.1",
                    hostname: "mockHostname",
                    endpoint: "mockEndpoint",
                    role: .master,
                    replicationOffset: 22,
                    health: .online
                )
            ]
        )
        
        map.updateCluster([shard])
        
        // When we pass an empty collection of slots to nodeID(for:), it should choose a random node
        #expect(throws: Never.self) { try map.nodeID(for: [] as [HashSlot]) }
        
        // Now with an empty cluster, it should throw clusterHasNoNodes
        map.updateCluster([])
        #expect(throws: ValkeyClusterError.clusterHasNoNodes) { try map.nodeID(for: [] as [HashSlot]) }
    }
    
    @Test
    func testBoundarySlots() {
        var map = HashSlotShardMap()
        
        // Test the min and max valid slot values
        let shard = ValkeyClusterDescription.Shard(
            slots: [HashSlot.min...5, HashSlot.max...HashSlot.max],
            nodes: [
                .init(
                    id: "node1",
                    port: 5,
                    tlsPort: 6,
                    ip: "127.0.0.1",
                    hostname: "mockHostname",
                    endpoint: "mockEndpoint",
                    role: .master,
                    replicationOffset: 22,
                    health: .online
                )
            ]
        )
        
        map.updateCluster([shard])
        
        let expected: ValkeyShardNodeIDs = [.init(endpoint: "mockEndpoint", port: 6)]
        #expect(map[HashSlot.min] == expected)
        #expect(map[HashSlot.max] == expected)
    }
    
    @Test
    func testMultipleNodeID() throws {
        // Test the nodeID(for:) method with multiple slots that map to the same shard
        var map = HashSlotShardMap()
        
        let shard1 = ValkeyClusterDescription.Shard(
            slots: [0...100, 200...300],
            nodes: [
                .init(
                    id: "node1",
                    port: 5,
                    tlsPort: 6,
                    ip: "127.0.0.1",
                    hostname: "node1",
                    endpoint: "node1.example.com",
                    role: .master,
                    replicationOffset: 22,
                    health: .online
                )
            ]
        )
        
        let shard2 = ValkeyClusterDescription.Shard(
            slots: [101...199],
            nodes: [
                .init(
                    id: "node2",
                    port: 5,
                    tlsPort: 6,
                    ip: "127.0.0.2",
                    hostname: "node2",
                    endpoint: "node2.example.com",
                    role: .master,
                    replicationOffset: 22,
                    health: .online
                )
            ]
        )
        
        map.updateCluster([shard1, shard2])
        
        // Test slots from the same shard
        let sameShardSlots: [HashSlot] = [5, 50, 250]
        let nodeID = try map.nodeID(for: sameShardSlots)
        #expect(nodeID.master.endpoint == "node1.example.com")
        
        // Test slots from different shards - should throw
        let differentShardSlots: [HashSlot] = [5, 150] // 5 from shard1, 150 from shard2
        #expect(throws: ValkeyClusterError.keysInCommandRequireMultipleNodes) {
            try map.nodeID(for: differentShardSlots)
        }
    }
    
    @Test
    func testUnassignedSlotsInNodeIDRequest() {
        var map = HashSlotShardMap()
        
        let shard = ValkeyClusterDescription.Shard(
            slots: [0...100],
            nodes: [
                .init(
                    id: "node1",
                    port: 5,
                    tlsPort: 6,
                    ip: "127.0.0.1",
                    hostname: "node1",
                    endpoint: "node1.example.com",
                    role: .master,
                    replicationOffset: 22,
                    health: .online
                )
            ]
        )
        
        map.updateCluster([shard])
        
        // Requesting an unassigned slot should throw
        #expect(throws: ValkeyClusterError.clusterIsMissingSlotAssignment) {
            _ = try map.nodeID(for: [500])
        }
        
        // Requesting a mix of assigned and unassigned slots should throw for the first unassigned slot
        #expect(throws: ValkeyClusterError.clusterIsMissingSlotAssignment) {
            _ = try map.nodeID(for: [50, 500])
        }
    }
    
    @Test
    func testClusterUpdates() {
        var map = HashSlotShardMap()
        
        // Initial cluster state
        let shard1 = ValkeyClusterDescription.Shard(
            slots: [0...100],
            nodes: [
                .init(
                    id: "node1",
                    port: 5,
                    tlsPort: 6,
                    ip: "127.0.0.1",
                    hostname: "node1",
                    endpoint: "node1.example.com",
                    role: .master,
                    replicationOffset: 22,
                    health: .online
                )
            ]
        )
        
        map.updateCluster([shard1])
        
        let expected1: ValkeyShardNodeIDs = [.init(endpoint: "node1.example.com", port: 6)]
        #expect(map[50] == expected1)
        
        // Update the cluster - same node but different endpoint/port
        let shard2 = ValkeyClusterDescription.Shard(
            slots: [0...100],
            nodes: [
                .init(
                    id: "node1",
                    port: 7,
                    tlsPort: 8,
                    ip: "127.0.0.1",
                    hostname: "node1-new",
                    endpoint: "node1-new.example.com",
                    role: .master,
                    replicationOffset: 25,
                    health: .online
                )
            ]
        )
        
        map.updateCluster([shard2])
        
        let expected2: ValkeyShardNodeIDs = [.init(endpoint: "node1-new.example.com", port: 8)]
        #expect(map[50] == expected2)
        #expect(map[50] != expected1)
    }
}
