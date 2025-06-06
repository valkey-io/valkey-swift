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

/// A simplified representation of a Valkey cluster topology.
///
/// `ValkeyTopologyCandidate` provides a stripped-down version of `ValkeyClusterDescription`
/// designed specifically for efficient comparison during cluster updates. It preserves
/// only the essential properties needed to determine if a topology has changed, while
/// maintaining consistent ordering of elements to ensure reliable equality checks.
package struct ValkeyTopologyCandidate: Hashable {
    /// Represents a shard (hash slot range) within a Valkey cluster topology.
    ///
    /// A shard consists of a set of hash slots assigned to a master node and optional replica nodes.
    package struct Shard: Hashable {
        /// The hash slots assigned to this shard.
        package var slots: HashSlots

        /// The master node responsible for this shard.
        package var master: Node

        /// The replica nodes for this shard, sorted by endpoint, port, and TLS status for consistent equality checking.
        package var replicas: [Node]
    }

    /// Represents a node (either master or replica) in the Valkey cluster topology.
    ///
    /// Contains only the essential connection properties needed to identify and connect to a node.
    package struct Node: Hashable {
        /// The endpoint (hostname or IP address) of the node.
        package var endpoint: String

        /// The port to connect to (either standard port or TLS port).
        package var port: Int

        /// Whether TLS should be used for connecting to this node.
        package var useTLS: Bool

        /// Creates a simplified node representation from a `ValkeyClusterDescription.Node`.
        ///
        /// - Parameter node: The source node from a cluster description.
        package init(_ node: ValkeyClusterDescription.Node) {
            self.endpoint = node.endpoint
            self.port = node.tlsPort ?? node.port ?? 6379
            self.useTLS = node.tlsPort != nil
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
    package init(_ description: ValkeyClusterDescription) throws(ValkeyClusterError) {

        self.shards = try description.shards.map({ shard throws(ValkeyClusterError) in
            var master: Node?
            var replicas = [Node]()
            replicas.reserveCapacity(shard.nodes.count)

            for node in shard.nodes {
                switch node.role.base {
                case .master:
                    if master != nil {
                        throw ValkeyClusterError.shardHasMultipleMasterNodes
                    }
                    master = Node(node)
                case .replica:
                    replicas.append(Node(node))
                }
            }

            let sorted = replicas.sorted(by: { lhs, rhs in
                if lhs.endpoint != rhs.endpoint {
                    return lhs.endpoint < rhs.endpoint
                }
                if lhs.port != rhs.port {
                    return lhs.port < rhs.port
                }
                if lhs.useTLS != rhs.useTLS {
                    return !lhs.useTLS
                }
                return true
            })

            guard let master else {
                throw ValkeyClusterError.shardIsMissingMasterNode
            }

            return Shard(
                slots: shard.slots.sorted(by: { $0.startIndex < $1.startIndex }),
                master: master,
                replicas: sorted
            )
        })
        // Sort shards by starting hash slot
        self.shards = self.shards.sorted(by: { (lhs, rhs) in (lhs.slots.first?.startIndex ?? .pastEnd) < (rhs.slots.first?.startIndex ?? .pastEnd) })
    }
}

struct ValkeyClusterVoter<ConnectionPool: ValkeyNodeConnectionPool> {
    var client: ConnectionPool
    var nodeID: ValkeyNodeID
}
