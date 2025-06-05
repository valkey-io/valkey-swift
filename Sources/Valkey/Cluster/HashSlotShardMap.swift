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

/// Represents the mapping of nodes in a Valkey shard, consisting of a master node and optional replicas.
///
/// In a Valkey cluster, each shard consists of one master node and zero or more replica nodes.
@usableFromInline
package struct ValkeyShardNodeIDs: Hashable, Sendable {
    /// The master node responsible for handling write operations for this shard.
    @usableFromInline
    package var master: ValkeyNodeID

    /// The replica nodes that maintain copies of the master's data.
    /// Replicas can handle read operations but not writes.
    @usableFromInline
    package var replicas: [ValkeyNodeID]

    /// Creates a new shard node mapping with the specified master and optional replicas.
    ///
    /// - Parameters:
    ///   - master: The master node ID for this shard
    ///   - replicas: An array of replica node IDs, defaults to empty
    package init(master: ValkeyNodeID, replicas: [ValkeyNodeID] = []) {
        self.master = master
        self.replicas = replicas
    }
}

extension ValkeyShardNodeIDs: ExpressibleByArrayLiteral {
    @usableFromInline
    package typealias ArrayLiteralElement = ValkeyNodeID

    @usableFromInline
    package init(arrayLiteral elements: ValkeyNodeID...) {
        precondition(!elements.isEmpty, "ValkeyShardNodeIDs requires at least one node ID for the master")
        self.master = elements.first!
        self.replicas = Array(elements.dropFirst())
    }
}

/// This object allows us to efficiently look up the Valkey shard given a hash slot.
///
/// The `HashSlotShardMap` maintains an internal array where each element corresponds to one hash slot (0-16383).
/// This makes looking up the shard as efficient as a simple array access operation.
///
/// Hash slots are assigned to shards in a Valkey cluster, and each key is mapped to a specific slot
/// using the CRC16 algorithm, allowing the client to determine which node should handle a given command.
@usableFromInline
package struct HashSlotShardMap: Sendable {
    private static let allSlotsMissing = [OptionalShardID](repeating: .missing, count: HashSlot.count)

    private var slotToShardID: [OptionalShardID] = Self.allSlotsMissing
    private var shardIDToShard: [ValkeyShardNodeIDs] = []

    package init() {}

    /// Returns the shard node information for the given hash slot, or nil if the slot is unassigned.
    ///
    /// - Parameter key: The hash slot to look up
    /// - Returns: The shard node information if the slot is assigned, or nil otherwise
    @usableFromInline
    package subscript(_ key: HashSlot) -> ValkeyShardNodeIDs? {
        guard let shardID = self.slotToShardID[Int(key.rawValue)].value else {
            return nil
        }
        return self.shardIDToShard[shardID]
    }

    /// Determines the appropriate shard node information for a collection of hash slots.
    ///
    /// All slots must map to the same shard, otherwise an error is thrown.
    /// If no slots are provided, a random shard is returned.
    ///
    /// - Parameter slots: A collection of hash slots that should map to the same shard
    /// - Returns: The shard node information for the given slots
    /// - Throws: `ValkeyClusterError.clusterHasNoNodes` if the cluster has no nodes
    ///           `ValkeyClusterError.clusterIsMissingSlotAssignment` if any slot is unassigned
    ///           `ValkeyClusterError.keysInCommandRequireMultipleNodes` if slots map to different shards
    @usableFromInline
    package func nodeID(for slots: some Collection<HashSlot>) throws(ValkeyClusterError) -> ValkeyShardNodeIDs {
        guard let firstSlot = slots.first else {
            if let shardID = self.shardIDToShard.randomElement() {
                return shardID
            } else {
                throw ValkeyClusterError.clusterHasNoNodes
            }
        }

        let ogNodeID = self.slotToShardID[Int(firstSlot.rawValue)]
        guard let ogNodeIndex = ogNodeID.value else {
            throw ValkeyClusterError.clusterIsMissingSlotAssignment
        }

        for slot in slots.dropFirst() {
            let nodeID = self.slotToShardID[Int(slot.rawValue)]
            if nodeID == .missing {
                throw ValkeyClusterError.clusterIsMissingSlotAssignment
            }
            guard ogNodeID == nodeID else {
                throw ValkeyClusterError.keysInCommandRequireMultipleNodes
            }
        }

        return self.shardIDToShard[ogNodeIndex]
    }

    /// Updates the cluster mapping with new shard information.
    ///
    /// This method resets the current mapping and rebuilds it based on the provided shard descriptions.
    /// It performs the following operations:
    /// 1. Resets the slot-to-shard mapping (all slots become unassigned)
    /// 2. Clears the current shard collection
    /// 3. For each valid shard (that has a master node):
    ///    - Creates a `ValkeyShardNodeIDs` object with the master and its replicas
    ///    - Assigns all slots belonging to this shard in the mapping
    ///
    /// - Parameter shards: A collection of shard descriptions containing slot assignments and node information
    package mutating func updateCluster(_ shards: some Collection<ValkeyClusterDescription.Shard>) {
        self.slotToShardID = Self.allSlotsMissing
        self.shardIDToShard.removeAll(keepingCapacity: true)
        self.shardIDToShard.reserveCapacity(shards.count)

        var shardID = 0
        for shard in shards {
            var master: ValkeyNodeID?
            var replicas = [ValkeyNodeID]()
            replicas.reserveCapacity(shard.nodes.count - 1)

            for node in shard.nodes {
                switch node.role.base {
                case .master:
                    master = node.nodeID

                case .replica:
                    replicas.append(node.nodeID)
                }
            }

            guard let master else {
                continue
            }

            let nodeIDs = ValkeyShardNodeIDs(
                master: master,
                replicas: replicas
            )

            defer { shardID += 1 }
            self.shardIDToShard.append(nodeIDs)

            for range in shard.slots {
                for slot in range {
                    self.slotToShardID[Int(slot.rawValue)] = .init(shardID)
                }
            }
        }
    }

    /// An internal type representing an optional shard ID with efficient storage.
    ///
    /// This type uses a special sentinel value to represent a missing shard ID
    /// without requiring the overhead of an actual Optional type.
    private struct OptionalShardID: Equatable {
        private let _rawValue: UInt16

        static let missing: OptionalShardID = .init(verified: UInt16.max)

        private init(verified: UInt16) {
            self._rawValue = verified
        }

        init(_ value: Int) {
            precondition(value >= 0 && value <= Int(HashSlot.max.rawValue))
            self._rawValue = UInt16(value)
        }

        var value: Int? {
            guard self != .missing else {
                return nil
            }
            return Int(self._rawValue)
        }
    }
}
