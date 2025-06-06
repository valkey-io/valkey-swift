//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift project
//
// Copyright (c) 2025 the valkey-swift authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See valkey-swift/CONTRIBUTORS.txt for the list of valkey-swift authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// ``ValkeyTopologyElection`` manages the consensus process for electing a cluster topology.
///
/// This struct tracks votes from cluster nodes for different topology candidates, keeping count of
/// received votes and determining when a consensus is reached. Once a candidate receives more than half
/// of the possible votes from all nodes in the cluster, it becomes the elected topology configuration.
///
/// The election process handles:
/// - Recording votes from nodes
/// - Tracking vote counts for each topology candidate
/// - Managing revotes (nodes changing their vote)
/// - Determining when a winner has been elected
package struct ValkeyTopologyElection {
    /// Represents a candidate in the topology election, tracking votes and thresholds.
    ///
    /// Each candidate corresponds to a specific cluster description and maintains
    /// count of the votes it has received and how many votes it needs to win.
    private struct Candidate {
        /// The cluster configuration this candidate represents.
        var description: ValkeyClusterDescription

        /// The number of votes needed for this candidate to win the election.
        /// Calculated as a simple majority of the total nodes in the cluster.
        var needed: Int

        /// The number of votes this candidate has received so far.
        var received: Int

        init(description: ValkeyClusterDescription) {
            self.description = description
            // Calculate the needed votes as a simple majority of all nodes across all shards
            self.needed = description.shards.reduce(0) { $0 + $1.nodes.count } / 2 + 1
            self.received = 0
        }

        /// Adds a vote for this candidate and checks if it has reached the winning threshold.
        ///
        /// - Returns: `true` if this candidate has received enough votes to win, `false` otherwise
        mutating func addVote() -> Bool {
            self.received += 1
            return self.received >= self.needed
        }
    }

    /// Provides metrics about the current state of the election process.
    ///
    /// This structure encapsulates information about a specific topology candidate,
    /// including how many votes it has received and how many it needs to win.
    package struct VoteMetrics {
        /// The total number of topology configurations being considered in this election.
        package var candidateCount: Int

        /// The specific topology candidate these metrics refer to.
        package var candidate: ValkeyTopologyCandidate

        /// The number of votes this candidate has received so far.
        package var votesReceived: Int

        /// The number of votes needed for this candidate to win the election.
        /// This is calculated as (total nodes / 2) + 1, representing a simple majority.
        package var votesNeeded: Int
    }

    private var votes = [ValkeyNodeID: ValkeyTopologyCandidate]()
    private var results = [ValkeyTopologyCandidate: Candidate]()

    /// The currently elected cluster configuration, if any.
    /// This is set to the first candidate that reaches the required vote threshold.
    package private(set) var winner: ValkeyClusterDescription?

    package init() {}

    /// Records a vote from a node for a specific cluster description.
    ///
    /// This method handles the core voting logic:
    /// 1. If the node has voted before, its previous vote is removed
    /// 2. The new vote is recorded
    /// 3. If this vote causes a candidate to reach the required threshold, it becomes the winner
    ///
    /// - Parameters:
    ///   - description: The cluster configuration the node is voting for
    ///   - voter: The ID of the node casting the vote
    ///
    /// - Returns: Metrics about the current state of the election after recording this vote
    ///
    /// - Throws: ``ValkeyClusterError`` if the provided cluster description cannot be converted to a valid topology candidate
    package mutating func voteReceived(
        for description: ValkeyClusterDescription,
        from voter: ValkeyNodeID
    ) throws(ValkeyClusterError) -> VoteMetrics {
        // 1. check that the voter hasn't voted before.
        //    - if it has voted before, remove its earlier vote.

        let topologyCandidate = try ValkeyTopologyCandidate(description)

        if let previousVote = self.votes[voter] {
            self.results[previousVote]!.received -= 1
        }

        self.votes[voter] = topologyCandidate
        if self.results[topologyCandidate, default: .init(description: description)].addVote() {
            if self.winner == nil {
                self.winner = description
            }
        }

        return VoteMetrics(
            candidateCount: self.results.count,
            candidate: topologyCandidate,
            votesReceived: self.results[topologyCandidate]!.received,
            votesNeeded: self.results[topologyCandidate]!.needed
        )
    }
}
