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
    
    @Test
    func testShardWithReplicas() {
        var map = HashSlotShardMap()
        
        // Create a shard with a master and two replicas
        let shard = ValkeyClusterDescription.Shard(
            slots: [0...100],
            nodes: [
                // Master node
                .init(
                    id: "master1",
                    port: 5,
                    tlsPort: 6,
                    ip: "127.0.0.1",
                    hostname: "master1",
                    endpoint: "master1.example.com",
                    role: .master,
                    replicationOffset: 100,
                    health: .online
                ),
                // Replica 1
                .init(
                    id: "replica1",
                    port: 7,
                    tlsPort: 8,
                    ip: "127.0.0.2",
                    hostname: "replica1",
                    endpoint: "replica1.example.com",
                    role: .replica,
                    replicationOffset: 95,
                    health: .online
                ),
                // Replica 2
                .init(
                    id: "replica2",
                    port: 9,
                    tlsPort: 10,
                    ip: "127.0.0.3",
                    hostname: "replica2",
                    endpoint: "replica2.example.com",
                    role: .replica,
                    replicationOffset: 98,
                    health: .online
                )
            ]
        )
        
        map.updateCluster([shard])
        
        // Verify that the shard node IDs include both master and replicas
        let expectedMaster = ValkeyNodeID(endpoint: "master1.example.com", port: 6)
        let expectedReplica1 = ValkeyNodeID(endpoint: "replica1.example.com", port: 8)
        let expectedReplica2 = ValkeyNodeID(endpoint: "replica2.example.com", port: 10)
        
        let shardNodes = map[50]!
        #expect(shardNodes.master == expectedMaster)
        #expect(shardNodes.replicas.count == 2)
        #expect(shardNodes.replicas.contains(expectedReplica1))
        #expect(shardNodes.replicas.contains(expectedReplica2))
        
        // Test nodeID(for:) continues to return correct master when replicas exist
        let nodeID = try! map.nodeID(for: [50, 75])
        #expect(nodeID.master == expectedMaster)
        #expect(nodeID.replicas.count == 2)
    }
    
    @Test
    func testMultipleShardWithReplicas() {
        var map = HashSlotShardMap()
        
        // Create two shards, each with replicas
        let shard1 = ValkeyClusterDescription.Shard(
            slots: [0...5000],
            nodes: [
                // Master node for shard 1
                .init(
                    id: "master1",
                    port: 5,
                    tlsPort: 6,
                    ip: "127.0.0.1",
                    hostname: "master1",
                    endpoint: "master1.example.com",
                    role: .master,
                    replicationOffset: 100,
                    health: .online
                ),
                // Replica for shard 1
                .init(
                    id: "replica1",
                    port: 7,
                    tlsPort: 8,
                    ip: "127.0.0.2",
                    hostname: "replica1",
                    endpoint: "replica1.example.com",
                    role: .replica,
                    replicationOffset: 95,
                    health: .online
                )
            ]
        )
        
        let shard2 = ValkeyClusterDescription.Shard(
            slots: [5001...16383],
            nodes: [
                // Master node for shard 2
                .init(
                    id: "master2",
                    port: 9,
                    tlsPort: 10,
                    ip: "127.0.0.3",
                    hostname: "master2",
                    endpoint: "master2.example.com",
                    role: .master,
                    replicationOffset: 200,
                    health: .online
                ),
                // Replica 1 for shard 2
                .init(
                    id: "replica2-1",
                    port: 11,
                    tlsPort: 12,
                    ip: "127.0.0.4",
                    hostname: "replica2-1",
                    endpoint: "replica2-1.example.com",
                    role: .replica,
                    replicationOffset: 195,
                    health: .online
                ),
                // Replica 2 for shard 2
                .init(
                    id: "replica2-2",
                    port: 13,
                    tlsPort: 14,
                    ip: "127.0.0.5",
                    hostname: "replica2-2",
                    endpoint: "replica2-2.example.com",
                    role: .replica,
                    replicationOffset: 198,
                    health: .online
                )
            ]
        )
        
        map.updateCluster([shard1, shard2])
        
        // Test slots from shard 1
        let expectedMaster1 = ValkeyNodeID(endpoint: "master1.example.com", port: 6)
        let expectedReplica1 = ValkeyNodeID(endpoint: "replica1.example.com", port: 8)
        
        let shardNodes1 = map[1000]!
        #expect(shardNodes1.master == expectedMaster1)
        #expect(shardNodes1.replicas.count == 1)
        #expect(shardNodes1.replicas[0] == expectedReplica1)
        
        // Test slots from shard 2
        let expectedMaster2 = ValkeyNodeID(endpoint: "master2.example.com", port: 10)
        let expectedReplica2_1 = ValkeyNodeID(endpoint: "replica2-1.example.com", port: 12)
        let expectedReplica2_2 = ValkeyNodeID(endpoint: "replica2-2.example.com", port: 14)
        
        let shardNodes2 = map[10000]!
        #expect(shardNodes2.master == expectedMaster2)
        #expect(shardNodes2.replicas.count == 2)
        #expect(shardNodes2.replicas.contains(expectedReplica2_1))
        #expect(shardNodes2.replicas.contains(expectedReplica2_2))
        
        // Verify that nodeID(for:) still throws when slots span multiple shards
        #expect(throws: ValkeyClusterError.keysInCommandRequireMultipleNodes) {
            _ = try map.nodeID(for: [1000, 10000])
        }
    }
    
    @Test
    func testShardWithoutNodes() {
        var map = HashSlotShardMap()
        
        // Create a normal shard with nodes
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
        
        // Create a shard without any nodes (empty nodes array)
        let emptyNodeShard = ValkeyClusterDescription.Shard(
            slots: [200...300],
            nodes: []
        )
        
        // The updateCluster implementation should skip shards without a master
        map.updateCluster([shard1, emptyNodeShard])
        
        // Slots from shard1 should be assigned
        #expect(map[50] != nil)
        
        // Slots from the empty shard should be unassigned
        #expect(map[250] == nil)
    }
    
    @Test
    func testNodeHealthStatus() {
        var map = HashSlotShardMap()
        
        // Create a shard with a master that's failed and a healthy replica
        let shard = ValkeyClusterDescription.Shard(
            slots: [0...100],
            nodes: [
                // Failed master node
                .init(
                    id: "master1",
                    port: 5,
                    tlsPort: 6,
                    ip: "127.0.0.1",
                    hostname: "master1",
                    endpoint: "master1.example.com",
                    role: .master,
                    replicationOffset: 100,
                    health: .failed
                ),
                // Healthy replica node
                .init(
                    id: "replica1",
                    port: 7,
                    tlsPort: 8,
                    ip: "127.0.0.2",
                    hostname: "replica1",
                    endpoint: "replica1.example.com",
                    role: .replica,
                    replicationOffset: 95,
                    health: .online
                )
            ]
        )
        
        map.updateCluster([shard])
        
        // Verify that even though the master is failed, it's still mapped correctly
        let expectedMaster = ValkeyNodeID(endpoint: "master1.example.com", port: 6)
        let expectedReplica = ValkeyNodeID(endpoint: "replica1.example.com", port: 8)
        
        let shardNodes = map[50]!
        #expect(shardNodes.master == expectedMaster)
        #expect(shardNodes.replicas.count == 1)
        #expect(shardNodes.replicas[0] == expectedReplica)
    }
    
    @Test
    func testReplicaLoadingState() {
        var map = HashSlotShardMap()
        
        // Create a shard with a master and replicas in different health states
        let shard = ValkeyClusterDescription.Shard(
            slots: [0...100],
            nodes: [
                // Master node
                .init(
                    id: "master1",
                    port: 5,
                    tlsPort: 6,
                    ip: "127.0.0.1",
                    hostname: "master1",
                    endpoint: "master1.example.com",
                    role: .master,
                    replicationOffset: 100,
                    health: .online
                ),
                // Online replica
                .init(
                    id: "replica1",
                    port: 7,
                    tlsPort: 8,
                    ip: "127.0.0.2",
                    hostname: "replica1",
                    endpoint: "replica1.example.com",
                    role: .replica,
                    replicationOffset: 95,
                    health: .online
                ),
                // Loading replica
                .init(
                    id: "replica2",
                    port: 9,
                    tlsPort: 10,
                    ip: "127.0.0.3",
                    hostname: "replica2",
                    endpoint: "replica2.example.com",
                    role: .replica,
                    replicationOffset: 90,
                    health: .loading
                )
            ]
        )
        
        map.updateCluster([shard])
        
        // Verify all nodes (including loading replica) are included in the mapping
        let expectedMaster = ValkeyNodeID(endpoint: "master1.example.com", port: 6)
        let expectedReplica1 = ValkeyNodeID(endpoint: "replica1.example.com", port: 8)
        let expectedReplica2 = ValkeyNodeID(endpoint: "replica2.example.com", port: 10) 
        
        let shardNodes = map[50]!
        #expect(shardNodes.master == expectedMaster)
        #expect(shardNodes.replicas.count == 2)
        #expect(shardNodes.replicas.contains(expectedReplica1))
        #expect(shardNodes.replicas.contains(expectedReplica2))
    }
    
    @Test
    func testReplicaWithoutTLSPort() {
        var map = HashSlotShardMap()
        
        // Create a shard with replicas that have different port configurations
        let shard = ValkeyClusterDescription.Shard(
            slots: [0...100],
            nodes: [
                // Master node with TLS port
                .init(
                    id: "master1",
                    port: 5,
                    tlsPort: 6,
                    ip: "127.0.0.1",
                    hostname: "master1",
                    endpoint: "master1.example.com",
                    role: .master,
                    replicationOffset: 100,
                    health: .online
                ),
                // Replica with TLS port
                .init(
                    id: "replica1",
                    port: 7,
                    tlsPort: 8,
                    ip: "127.0.0.2",
                    hostname: "replica1",
                    endpoint: "replica1.example.com",
                    role: .replica,
                    replicationOffset: 95,
                    health: .online
                ),
                // Replica without TLS port
                .init(
                    id: "replica2",
                    port: 9,
                    tlsPort: nil,
                    ip: "127.0.0.3",
                    hostname: "replica2",
                    endpoint: "replica2.example.com",
                    role: .replica,
                    replicationOffset: 98,
                    health: .online
                )
            ]
        )
        
        map.updateCluster([shard])
        
        // Verify the mapping correctly handles nil ports
        let expectedMaster = ValkeyNodeID(endpoint: "master1.example.com", port: 6)
        let expectedReplica1 = ValkeyNodeID(endpoint: "replica1.example.com", port: 8)
        let expectedReplica2 = ValkeyNodeID(endpoint: "replica2.example.com", port: 9) // Should use non-TLS port
        
        let shardNodes = map[50]!
        #expect(shardNodes.master == expectedMaster)
        #expect(shardNodes.replicas.count == 2)
        #expect(shardNodes.replicas.contains(expectedReplica1))
        #expect(shardNodes.replicas.contains(expectedReplica2))
    }

    func makeExampleCusterWithNShardsAndMReplicasPerShard(shards: Int, replicas: Int) -> ValkeyClusterDescription {
        let defaultRangeSize = Int(HashSlot.max.rawValue + 1) / shards
        var range: ClosedRange<HashSlot> = 0...0

        var result = [ValkeyClusterDescription.Shard]()
        var nodeIndex = 1

        for i in 0..<shards {
            if i == 0 {
                if shards == 1 {
                    range = HashSlot.min...HashSlot.max
                } else {
                    range = HashSlot.min...(range.upperBound.advanced(by: defaultRangeSize - 1))
                }
            } else if i == shards - 1 {
                range = (range.upperBound.advanced(by: 1))...HashSlot.max
            } else {
                range = (range.upperBound.advanced(by: 1))...(range.upperBound.advanced(by: defaultRangeSize - 1))
            }

            var shard = ValkeyClusterDescription.Shard(slots: [range], nodes: [])
            for _ in 0..<(replicas + 1) {
                defer { nodeIndex += 1 }
                shard.nodes.append(
                    .init(
                        id: "node-\(nodeIndex)",
                        port: nil,
                        tlsPort: 6379,
                        ip: "192.168.64.\(nodeIndex)",
                        hostname: "node-\(nodeIndex).valkey.io",
                        endpoint: "node-\(nodeIndex).valkey.io",
                        role: .replica,
                        replicationOffset: 14,
                        health: .online
                    )
                )
            }
            let primaryIndex = shard.nodes.indices.randomElement()!
            shard.nodes[primaryIndex].role = .master

            result.append(shard)
        }

        return ValkeyClusterDescription(result)
    }

    @Test("Case 1: MovedError specifies the already exisiting shard primary node")
    func movedErrorSpecifiesTheAlreadyExisitingShardPrimaryNode() throws {
        let clusterDescription = self.makeExampleCusterWithNShardsAndMReplicasPerShard(shards: 3, replicas: 1)

        var map = HashSlotShardMap()
        map.updateCluster(clusterDescription.shards)

        let ogShard = try map.nodeID(for: CollectionOfOne(2))
        let update = map.updateSlots(with: ValkeyMovedError(slot: 2, endpoint: ogShard.master.endpoint, port: ogShard.master.port))
        #expect(update == .updatedSlotToExistingNode)
        let updatedShard = try map.nodeID(for: CollectionOfOne(2))
        #expect(updatedShard == ogShard)
    }

    @Test("Case 2: MovedError specifies a previous shard replica node")
    func movedErrorSpecifiesAPreviousShardReplicaNode() throws {
        let clusterDescription = self.makeExampleCusterWithNShardsAndMReplicasPerShard(shards: 3, replicas: 3)

        var map = HashSlotShardMap()
        map.updateCluster(clusterDescription.shards)

        let ogShard = try map.nodeID(for: CollectionOfOne(2))
        let luckyReplica = ogShard.replicas.randomElement()!

        let update = map.updateSlots(with: ValkeyMovedError(slot: 2, endpoint: luckyReplica.endpoint, port: luckyReplica.port))
        #expect(update == .updatedSlotToExistingNode)
        let updatedShard = try map.nodeID(for: CollectionOfOne(2))
        #expect(updatedShard.master == luckyReplica)
        #expect(updatedShard != ogShard)

        // test neighboring hashes have seen an update as well
        let updatedShard1 = try map.nodeID(for: CollectionOfOne(1))
        let updatedShard3 = try map.nodeID(for: CollectionOfOne(3))

        #expect(updatedShard == updatedShard1)
        #expect(updatedShard == updatedShard3)
    }

    @Test("Case 3: MovedError specifies another shards primary node")
    func movedErrorSpecifiesOtherShardPrimaryNode() throws {
        let clusterDescription = self.makeExampleCusterWithNShardsAndMReplicasPerShard(shards: 3, replicas: 3)

        var map = HashSlotShardMap()
        map.updateCluster(clusterDescription.shards)

        let ogShard = try map.nodeID(for: CollectionOfOne(2))
        let otherShard = try map.nodeID(for: CollectionOfOne(.max))
        let newPrimary = otherShard.master

        let update = map.updateSlots(with: ValkeyMovedError(slot: 2, endpoint: newPrimary.endpoint, port: newPrimary.port))
        #expect(update == .updatedSlotToExistingNode)
        let updatedShard = try map.nodeID(for: CollectionOfOne(2))
        #expect(updatedShard == otherShard)

        // test neighboring hashes have not been updated
        let updatedShard1 = try map.nodeID(for: CollectionOfOne(1))
        let updatedShard3 = try map.nodeID(for: CollectionOfOne(3))

        #expect(ogShard == updatedShard1)
        #expect(ogShard == updatedShard3)
    }

    @Test("Case 4: MovedError specifies another shards replica node")
    func movedErrorSpecifiesOtherShardReplicaNode() throws {
        let clusterDescription = self.makeExampleCusterWithNShardsAndMReplicasPerShard(shards: 3, replicas: 3)

        var map = HashSlotShardMap()
        map.updateCluster(clusterDescription.shards)

        let ogShard = try map.nodeID(for: CollectionOfOne(2))
        let otherShard = try map.nodeID(for: CollectionOfOne(.max))
        let newPrimary = otherShard.replicas.randomElement()!

        let update = map.updateSlots(with: ValkeyMovedError(slot: 2, endpoint: newPrimary.endpoint, port: newPrimary.port))
        #expect(update == .updatedSlotToExistingNode)
        let updatedShard = try map.nodeID(for: CollectionOfOne(2))
        #expect(updatedShard.master == newPrimary)
        #expect(updatedShard.replicas.isEmpty)
        #expect(updatedShard != ogShard)

        // test neighboring hashes have not been updated
        let updatedShard1 = try map.nodeID(for: CollectionOfOne(1))
        let updatedShard3 = try map.nodeID(for: CollectionOfOne(3))

        #expect(ogShard == updatedShard1)
        #expect(ogShard == updatedShard3)

        // test other shard has been updated and new primary replica has been removed there
        let otherShardUpdated = try map.nodeID(for: CollectionOfOne(.max))
        #expect(!otherShardUpdated.replicas.contains(newPrimary))
    }

    @Test("Case 5: MovedError specifies previously unknown node")
    func movedErrorSpecifiesPreviouslyUnknownNode() throws {
        let clusterDescription = self.makeExampleCusterWithNShardsAndMReplicasPerShard(shards: 3, replicas: 3)

        var map = HashSlotShardMap()
        map.updateCluster(clusterDescription.shards)

        let ogShard = try map.nodeID(for: CollectionOfOne(2))
        let otherShard = try map.nodeID(for: CollectionOfOne(.max))
        let newPrimary = ValkeyNodeID(endpoint: "new.valkey.io", port: 6379)

        let update = map.updateSlots(with: ValkeyMovedError(slot: 2, endpoint: newPrimary.endpoint, port: newPrimary.port))
        #expect(update == .updatedSlotToUnknownNode)
        let updatedShard = try map.nodeID(for: CollectionOfOne(2))
        #expect(updatedShard.master == newPrimary)
        #expect(updatedShard.replicas.isEmpty)
        #expect(updatedShard != ogShard)

        // test neighboring hashes have not been updated
        let updatedShard1 = try map.nodeID(for: CollectionOfOne(1))
        let updatedShard3 = try map.nodeID(for: CollectionOfOne(3))

        #expect(ogShard == updatedShard1)
        #expect(ogShard == updatedShard3)

        // test other shard has been updated and new primary replica has been removed there
        let otherShardUpdated = try map.nodeID(for: CollectionOfOne(.max))
        #expect(!otherShardUpdated.replicas.contains(newPrimary))
    }
}
