//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import Testing
import Valkey

@Suite("Topology Election Tests")
struct ValkeyTopologyElectionTests {
    /// Creates a simple cluster description with a single shard and node
    func createSingleShardCluster(
        id: String = "node1",
        endpoint: String = "localhost",
        slots: [ClosedRange<HashSlot>] = [0...5]
    ) -> ValkeyClusterDescription {
        let node = ValkeyClusterDescription.Node(
            id: id,
            port: 6379,
            tlsPort: 6380,
            ip: "127.0.0.1",
            hostname: "localhost",
            endpoint: endpoint,
            role: .primary,
            replicationOffset: 0,
            health: .online
        )

        let shard = ValkeyClusterDescription.Shard(slots: slots, nodes: [node])
        return ValkeyClusterDescription([shard])
    }

    /// Creates a cluster description with multiple shards
    func createMultiShardCluster() -> ValkeyClusterDescription {
        let node1 = ValkeyClusterDescription.Node(
            id: "node1",
            port: 6379,
            tlsPort: 6380,
            ip: "127.0.0.1",
            hostname: "server1",
            endpoint: "server1.example.com",
            role: .primary,
            replicationOffset: 0,
            health: .online
        )

        let node2 = ValkeyClusterDescription.Node(
            id: "node2",
            port: 6379,
            tlsPort: 6380,
            ip: "127.0.0.2",
            hostname: "server2",
            endpoint: "server2.example.com",
            role: .primary,
            replicationOffset: 0,
            health: .online
        )

        let shard1 = ValkeyClusterDescription.Shard(slots: [0...8000], nodes: [node1])
        let shard2 = ValkeyClusterDescription.Shard(slots: [8001...16383], nodes: [node2])
        return ValkeyClusterDescription([shard1, shard2])
    }

    /// Creates a cluster description with a primary and replica nodes
    static func createClusterWithReplicas() -> ValkeyClusterDescription {
        let primary = ValkeyClusterDescription.Node(
            id: "primary1",
            port: 6379,
            tlsPort: 6380,
            ip: "127.0.0.1",
            hostname: "primary",
            endpoint: "primary.example.com",
            role: .primary,
            replicationOffset: 100,
            health: .online
        )

        let replica1 = ValkeyClusterDescription.Node(
            id: "replica1",
            port: 6379,
            tlsPort: 6380,
            ip: "127.0.0.2",
            hostname: "replica1",
            endpoint: "replica1.example.com",
            role: .replica,
            replicationOffset: 95,
            health: .online
        )

        let replica2 = ValkeyClusterDescription.Node(
            id: "replica2",
            port: 6379,
            tlsPort: 6380,
            ip: "127.0.0.3",
            hostname: "replica2",
            endpoint: "replica2.example.com",
            role: .replica,
            replicationOffset: 98,
            health: .online
        )

        let shard = ValkeyClusterDescription.Shard(
            slots: [0...16383],
            nodes: [primary, replica1, replica2]
        )
        return ValkeyClusterDescription([shard])
    }

    @Test("Initial state has no winner")
    @available(valkeySwift 1.0, *)
    func initialState() {
        let election = ValkeyTopologyElection()
        #expect(election.winner == nil)
    }

    @Test("Single vote does not establish a winner in multi node scenario")
    @available(valkeySwift 1.0, *)
    func singleVoteBelowThreshold() throws {
        var election = ValkeyTopologyElection()

        // Create a larger cluster description so a single vote isn't enough to win
        let multiNodeDescription = Self.createClusterWithReplicas()

        let voterID = ValkeyNodeID(endpoint: "voter1.example.com", port: 6380)
        let metrics = try election.voteReceived(for: ValkeyClusterTopology(multiNodeDescription), from: voterID)

        // With 3 nodes in the cluster, we need 2 votes to win (3/2 + 1 = 2)
        #expect(metrics.votesNeeded == 2)
        #expect(metrics.votesReceived == 1)
        #expect(metrics.candidateCount == 1)
        #expect(election.winner == nil, "A single vote shouldn't be enough to win")
    }

    @Test("Sufficient votes establish a winner")
    @available(valkeySwift 1.0, *)
    func sufficientVotesToWin() throws {
        var election = ValkeyTopologyElection()
        let description = createSingleShardCluster()

        // Single node cluster only needs 1 vote to win (1/2 + 1 = 1)
        let voterID = ValkeyNodeID(endpoint: "voter1.example.com", port: 6380)
        let metrics = try election.voteReceived(for: ValkeyClusterTopology(description), from: voterID)

        #expect(metrics.votesNeeded == 1)
        #expect(metrics.votesReceived == 1)
        #expect(election.winner != nil, "Should have a winner with sufficient votes")
        #expect(election.winner?.shards.count == 1, "Winner should match the voted description")
    }

    @Test("First candidate to reach threshold becomes winner")
    @available(valkeySwift 1.0, *)
    func firstCandidateWins() throws {
        var election = ValkeyTopologyElection()

        // Create two different cluster descriptions
        let description1 = createSingleShardCluster(endpoint: "node1")
        let description2 = createSingleShardCluster(endpoint: "node2")
        let topology1 = try ValkeyClusterTopology(description1)
        let topology2 = try ValkeyClusterTopology(description2)

        // Vote for the first configuration
        let voter1 = ValkeyNodeID(endpoint: "voter1.example.com", port: 6380)
        let voteMetrics1 = try election.voteReceived(for: topology1, from: voter1)

        #expect(voteMetrics1.votesReceived == 1)
        #expect(voteMetrics1.votesNeeded == 1)
        #expect(voteMetrics1.candidateCount == 1)

        // At this point description1 should be the winner
        #expect(election.winner == topology1, "Should have a winner")

        // Vote for the second configuration
        let voter2 = ValkeyNodeID(endpoint: "voter2.example.com", port: 6380)
        let voteMetrics2 = try election.voteReceived(for: topology2, from: voter2)

        #expect(voteMetrics2.votesReceived == 1)
        #expect(voteMetrics2.votesNeeded == 1)
        #expect(voteMetrics2.candidateCount == 2)

        // The winner should still be the first description
        #expect(election.winner == topology1, "Winner shouldn't change once established")
    }

    @Test("The same instance voting twice for the same candidate doesn't count twice")
    @available(valkeySwift 1.0, *)
    func sameInstanceVotingTwiceDoesntCountTwice() throws {
        var election = ValkeyTopologyElection()

        // Create a description that will need 3 votes to win
        let description = Self.createClusterWithReplicas()
        let topology = try ValkeyClusterTopology(description)

        // Cast 3 votes from different voters
        let voter1 = ValkeyNodeID(endpoint: "primary.example.com", port: 6380)
        let voter2 = ValkeyNodeID(endpoint: "replica1.example.com", port: 6380)
        let voter3 = ValkeyNodeID(endpoint: "replica2.example.com", port: 6380)

        let metrics1 = try election.voteReceived(for: topology, from: voter1)
        #expect(metrics1.votesReceived == 1)
        #expect(metrics1.votesNeeded == 2)  // (3 nodes / 2) + 1 = 2
        #expect(election.winner == nil)

        let metrics2 = try election.voteReceived(for: topology, from: voter1)
        #expect(metrics2.votesReceived == 1)
        #expect(metrics2.votesNeeded == 2)  // (3 nodes / 2) + 1 = 2
        #expect(election.winner == nil)

        let metrics3 = try election.voteReceived(for: topology, from: voter2)
        #expect(metrics3.votesReceived == 2)
        #expect(election.winner == topology, "Should have a winner after reaching the threshold")

        let metrics4 = try election.voteReceived(for: topology, from: voter3)
        #expect(metrics4.votesReceived == 3, "Should count additional votes even after winning")
    }

    @Test("The same instance can move its vote to another candidate")
    @available(valkeySwift 1.0, *)
    func sameInstanceVotingTwiceRemovesCountForInitialVote() throws {
        var election = ValkeyTopologyElection()

        // Create a description that will need 3 votes to win
        let description1 = Self.createClusterWithReplicas()
        let topology1 = try ValkeyClusterTopology(description1)

        // Cast 3 votes from different voters
        let voter1 = ValkeyNodeID(endpoint: "primary.example.com", port: 6380)
        let voter2 = ValkeyNodeID(endpoint: "replica1.example.com", port: 6380)
        let voter3 = ValkeyNodeID(endpoint: "replica2.example.com", port: 6380)

        var description2 = description1
        description2.shards[0].nodes.removeLast()
        let topology2 = try ValkeyClusterTopology(description2)

        let metrics1 = try election.voteReceived(for: topology1, from: voter1)
        #expect(metrics1.votesReceived == 1)
        #expect(metrics1.votesNeeded == 2)  // (3 nodes / 2) + 1 = 2
        #expect(election.winner == nil)

        let metrics2 = try election.voteReceived(for: topology2, from: voter1)
        #expect(metrics2.votesReceived == 1)
        #expect(metrics2.votesNeeded == 2)  // (3 nodes / 2) + 1 = 2
        #expect(election.winner == nil)

        let metrics3 = try election.voteReceived(for: topology1, from: voter2)
        #expect(metrics3.votesReceived == 1, "Vote count still at one, because voter1 moved his vote to description2")
        #expect(election.winner == nil, "Should have a winner after reaching the threshold")

        let metrics4 = try election.voteReceived(for: topology1, from: voter3)
        #expect(metrics4.votesReceived == 2, "Should count additional votes")
        #expect(election.winner == topology1, "voter2 and voter3 make description1 the winner")
    }

    @Test("Topology candidates with same structure are equal")
    @available(valkeySwift 1.0, *)
    func topologyCandidateEquality() throws {
        // Create two descriptions with the same structure but different node IDs
        let description1 = createSingleShardCluster(id: "node1")
        let description2 = createSingleShardCluster(id: "node2")

        let candidate1 = try ValkeyTopologyCandidate(ValkeyClusterTopology(description1))
        let candidate2 = try ValkeyTopologyCandidate(ValkeyClusterTopology(description2))

        // The candidates should be considered equal since they have the same structure
        // Note: This assumes ValkeyTopologyCandidate equality is based on structure, not node IDs
        #expect(
            candidate1 == candidate2,
            "Candidates with same structure but different node IDs should be equal"
        )
    }

    @Test("Different topology structures produce different candidates")
    @available(valkeySwift 1.0, *)
    func differentTopologyStructures() throws {
        let description1 = createSingleShardCluster(slots: [0...5000])
        let description2 = createSingleShardCluster(slots: [0...8000])

        let candidate1 = try ValkeyTopologyCandidate(ValkeyClusterTopology(description1))
        let candidate2 = try ValkeyTopologyCandidate(ValkeyClusterTopology(description2))

        #expect(
            candidate1 != candidate2,
            "Candidates with different slot ranges should not be equal"
        )
    }
}
