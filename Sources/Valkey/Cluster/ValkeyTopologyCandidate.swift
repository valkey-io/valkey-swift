//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
/// A simplified representation of a Valkey cluster topology.
///
/// `ValkeyTopologyCandidate` provides a stripped-down version of `ValkeyClusterDescription`
/// designed specifically for efficient comparison during cluster updates. It preserves
/// only the essential properties needed to determine if a topology has changed, while
/// maintaining consistent ordering of elements to ensure reliable equality checks.
@available(valkeySwift 1.0, *)
package struct ValkeyTopologyCandidate: Hashable {
    /// Represents a shard (hash slot range) within a Valkey cluster topology.
    ///
    /// A shard consists of a set of hash slots assigned to a primary node and optional replica nodes.
    package struct Shard: Hashable {
        /// The hash slots assigned to this shard.
        package var slots: HashSlots

        /// The primary node responsible for this shard.
        package var primary: Node

        /// The replica nodes for this shard, sorted by endpoint, port, and TLS status for consistent equality checking.
        package var replicas: [Node]
    }

    /// Represents a node (either primary or replica) in the Valkey cluster topology.
    ///
    /// Contains only the essential connection properties needed to identify and connect to a node.
    package struct Node: Hashable {
        /// The endpoint (hostname or IP address) of the node.
        package var endpoint: String

        /// The port to connect to (either standard port or TLS port).
        package var port: Int

        /// Creates a simplified node representation from a `ValkeyClusterDescription.Node`.
        ///
        /// - Parameter node: The source node from a cluster description.
        package init(_ node: ValkeyClusterTopology.Node) {
            self.endpoint = node.endpoint
            self.port = node.port
        }
    }

    /// Shards in the cluster topology, sorted by starting hash slot for consistent equality checking.
    package var shards: [Shard]

    /// Creates a topology candidate from a cluster description.
    ///
    /// This initializer:
    /// - Filters out non-essential details from the cluster description
    /// - Sorts replicas within each shard for consistent equality checking
    /// - Sorts shards by their starting hash slot for consistent equality checking
    ///
    /// - Parameter description: The cluster description to create a topology candidate from.
    package init(_ description: ValkeyClusterTopology) throws(ValkeyClusterError) {
        self.shards = try description.shards.map({ shard throws(ValkeyClusterError) in
            Shard(
                slots: shard.slots,
                primary: Node(shard.primary),
                replicas: shard.replicas.map { Node($0) }
            )
        })
        // Sort shards by starting hash slot
        self.shards = self.shards.sorted(by: { (lhs, rhs) in (lhs.slots.first?.startIndex ?? .pastEnd) < (rhs.slots.first?.startIndex ?? .pastEnd) })
    }
}

@available(valkeySwift 1.0, *)
package struct ValkeyClusterVoter<ConnectionPool: ValkeyNodeConnectionPool> {
    package var client: ConnectionPool
    package var nodeID: ValkeyNodeID

    package init(client: ConnectionPool, nodeID: ValkeyNodeID) {
        self.client = client
        self.nodeID = nodeID
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyTopologyCandidate.Shard: CustomStringConvertible {
    package var description: String {
        var string = "Shard("
        string += "slots: [\(self.slots.lazy.map { "\($0.lowerBound)...\($0.upperBound)" }.joined(separator: ", "))], "
        string += "primary: Node(\(self.primary.endpoint), \(self.primary.port)), "
        string += "replicas: [\(self.replicas.lazy.map { "Node(\($0.endpoint), port: \($0.port))" }.joined(separator: ", "))]) "
        return string
    }
}
