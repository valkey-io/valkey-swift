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

/// Represents the mapping of nodes in a Valkey shard, consisting of a primary node and optional replicas.
///
/// In a Valkey cluster, each shard consists of one primary node and zero or more replica nodes.
@usableFromInline
package struct ValkeyShardNodeIDs: Hashable, Sendable {
    /// The primary node responsible for handling write operations for this shard.
    @usableFromInline
    package var primary: ValkeyNodeID

    /// The replica nodes that maintain copies of the primary's data.
    /// Replicas can handle read operations but not writes.
    @usableFromInline
    package var replicas: [ValkeyNodeID]

    /// Creates a new shard node mapping with the specified primary and optional replicas.
    ///
    /// - Parameters:
    ///   - primary: The primary node ID for this shard
    ///   - replicas: An array of replica node IDs, defaults to empty
    package init(primary: ValkeyNodeID, replicas: [ValkeyNodeID] = []) {
        self.primary = primary
        self.replicas = replicas
    }

    /// Return random node from shard
    @usableFromInline
    package var randomNode: ValkeyNodeID {
        let value = Int.random(in: 0...replicas.count)
        if value == 0 {
            return self.primary
        } else {
            return self.replicas[value - 1]
        }
    }
}

extension ValkeyShardNodeIDs: ExpressibleByArrayLiteral {
    @usableFromInline
    package typealias ArrayLiteralElement = ValkeyNodeID

    @usableFromInline
    package init(arrayLiteral elements: ValkeyNodeID...) {
        precondition(!elements.isEmpty, "ValkeyShardNodeIDs requires at least one node ID for the primary")
        self.primary = elements.first!
        self.replicas = Array(elements.dropFirst())
    }
}

/// This object allows us to efficiently look up the Valkey shard given a hash slot.
///
/// The ``HashSlotShardMap`` maintains an internal array where each element corresponds to one hash slot (0-16383).
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
    package func nodeIDs(for slots: some Collection<HashSlot>) throws(ValkeyClusterError) -> ValkeyShardNodeIDs {
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
    /// 3. For each valid shard (that has a primary node):
    ///    - Creates a `ValkeyShardNodeIDs` object with the primary and its replicas
    ///    - Assigns all slots belonging to this shard in the mapping
    ///
    /// - Parameter shards: A collection of shard descriptions containing slot assignments and node information
    package mutating func updateCluster(_ shards: some Collection<ValkeyClusterDescription.Shard>) {
        self.slotToShardID = Self.allSlotsMissing
        self.shardIDToShard.removeAll(keepingCapacity: true)
        self.shardIDToShard.reserveCapacity(shards.count)

        var shardID = 0
        for shard in shards {
            var primary: ValkeyNodeID?
            var replicas = [ValkeyNodeID]()
            replicas.reserveCapacity(shard.nodes.count - 1)

            for node in shard.nodes {
                switch node.role.base {
                case .primary:
                    primary = node.nodeID

                case .replica:
                    replicas.append(node.nodeID)
                }
            }

            guard let primary else {
                continue
            }

            let nodeIDs = ValkeyShardNodeIDs(
                primary: primary,
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

    @usableFromInline
    package enum UpdateSlotsResult: Equatable {
        case updatedSlotToExistingNode
        case updatedSlotToUnknownNode
    }

    /// Handles MOVED errors by updating the client's slot and node mappings based on the new primary's role:
    ///
    /// 1. **No Change**: If the new primary is already the current slot owner, no updates are needed.
    /// 2. **Failover**: If the new primary is a replica within the same shard (indicating a failover),
    ///    the slot ownership is updated by promoting the replica to the primary in the existing shard addresses.
    /// 3. **Slot Migration**: If the new primary is an existing primary in another shard, this indicates a slot migration,
    ///    and the slot mapping is updated to point to the new shard addresses.
    /// 4. **Replica Moved to a Different Shard**: If the new primary is a replica in a different shard, it can be due to:
    ///    - The replica became the primary of its shard after a failover, with new slots migrated to it.
    ///    - The replica has moved to a different shard as the primary.
    ///      Since further information is unknown, the replica is removed from its original shard and added as the primary of a new shard.
    /// 5. **New Node**: If the new primary is unknown, it is added as a new node in a new shard, possibly indicating scale-out.
    ///
    /// This logic was first implemented in `valkey-glide` (see `Notice.txt`) and adopted for Swift here.
    @usableFromInline
    package mutating func updateSlots(with movedError: ValkeyMovedError) -> UpdateSlotsResult {
        if let shardIndex = self.slotToShardID[Int(movedError.slot.rawValue)].value {
            // if the slot had a shard assignment before
            var shard = self.shardIDToShard[shardIndex]

            // 1. No change
            if shard.primary == movedError.nodeID {
                return .updatedSlotToExistingNode
            }

            // 2. Failover
            if shard.replicas.contains(movedError.nodeID) {
                // lets promote the replica to be the primary and remove the old primary for now
                shard.primary = movedError.nodeID
                shard.replicas.removeAll { $0 == movedError.nodeID }
                self.shardIDToShard[shardIndex] = shard
                return .updatedSlotToExistingNode
            }
        }

        // 3. Slot migration to an existing primary
        if let newShardIndex = self.shardIDToShard.firstIndex(where: { $0.primary == movedError.nodeID }) {
            self.slotToShardID[Int(movedError.slot.rawValue)] = .init(newShardIndex)
            return .updatedSlotToExistingNode
        }

        // 4. Replica moved to a different shard
        if let ogShardIndexOfNewPrimary = self.shardIDToShard.firstIndex(where: { $0.replicas.contains(movedError.nodeID) }) {
            // remove replica from its og shard
            self.shardIDToShard[ogShardIndexOfNewPrimary].replicas.removeAll(where: { $0 == movedError.nodeID })
            // create a new shard with the replica
            let newShardIndex = self.shardIDToShard.endIndex
            self.shardIDToShard.append(.init(primary: movedError.nodeID))
            self.slotToShardID[Int(movedError.slot.rawValue)] = .init(newShardIndex)
            return .updatedSlotToExistingNode
        }

        // 5. totally new node
        let newShardIndex = self.shardIDToShard.endIndex
        self.shardIDToShard.append(.init(primary: movedError.nodeID))
        self.slotToShardID[Int(movedError.slot.rawValue)] = .init(newShardIndex)
        return .updatedSlotToUnknownNode
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
