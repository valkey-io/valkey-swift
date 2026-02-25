//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

/// Cluster topology description with nodes assigned to roles
package struct ValkeyClusterTopology: Sendable, Equatable, Hashable {
    /// Details for a node within a cluster shard.
    public struct Node: Hashable, Sendable, ValkeyNodeDescriptionProtocol {
        /// The ID of the node
        public var id: String
        /// The port
        public var port: Int
        /// The endpoint
        public var endpoint: String
        /// The health of the node
        public var health: ValkeyClusterDescription.Node.Health

        public init(_ description: ValkeyClusterDescription.Node) {
            self.id = description.id
            self.endpoint = description.endpoint
            self.port = description.tlsPort ?? description.port ?? 6379
            self.health = description.health
        }

        public var nodeID: ValkeyNodeID { .init(endpoint: self.endpoint, port: self.port) }
    }

    /// Shard description where nodes are allocated to their roles
    ///
    /// Failed replicas and failed primaries (if there is another online primary) are dropped
    package struct Shard: Sendable, Equatable, Hashable {
        package let slots: HashSlots
        package var primary: Node { nodes.last! }
        package let replicas: ArraySlice<Node>
        package let nodes: [Node]

        init(_ shard: ValkeyClusterDescription.Shard) throws(ValkeyClusterError) {
            var primary: Node? = nil
            var isFailedPrimary = false
            var nodes = [Node]()
            nodes.reserveCapacity(shard.nodes.count)

            for node in shard.nodes {
                switch node.role.base {
                case .primary:
                    switch (primary, isFailedPrimary) {
                    case (.some, false):
                        if node.health != .fail {
                            throw ValkeyClusterError.shardHasMultiplePrimaryNodes
                        }
                    case (.some, true), (.none, _):
                        primary = Node(node)
                        isFailedPrimary = (node.health == .fail)
                    }
                case .replica:
                    if node.health == .online {
                        nodes.append(Node(node))
                    }
                }
            }
            guard let primary else { throw ValkeyClusterError.shardIsMissingPrimaryNode }

            // sort nodes before adding primary
            nodes.sort { lhs, rhs in
                if lhs.endpoint != rhs.endpoint {
                    return lhs.endpoint < rhs.endpoint
                }
                if lhs.port != rhs.port {
                    return lhs.port < rhs.port
                }
                return true
            }
            let replicaCount = nodes.count
            nodes.append(primary)
            self.nodes = nodes
            if replicaCount > 0 {
                self.replicas = nodes[..<replicaCount]
            } else {
                self.replicas = .init()
            }
            self.slots = shard.slots.sorted(by: { $0.startIndex < $1.startIndex })
        }

        package static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.slots == rhs.slots && lhs.nodes == rhs.nodes
        }
    }

    package init(_ description: ValkeyClusterDescription) throws(ValkeyClusterError) {
        let shards = try description.shards.map { (shard) throws(ValkeyClusterError) in try Shard(shard) }
        self.shards = shards.sorted { lhs, rhs in
            (lhs.slots.first?.startIndex ?? .pastEnd) < (rhs.slots.first?.startIndex ?? .pastEnd)
        }
    }

    /// The individual portions of a valkey cluster, known as shards.
    package var shards: [Shard]
}
