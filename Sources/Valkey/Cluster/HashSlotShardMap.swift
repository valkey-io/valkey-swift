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

/// This object allows us to very efficiently look up the valkey shard given a hashkey.
///
/// The ``HashSlotShardMap`` has an internal array where each element corresponds to one HashSlot. This makes
/// looking up the Shard as efficient as an Array element access.
package struct HashSlotShardMap {
    package typealias Input = HashSlot

    private static let allSlotsMissing = [OptionalShardID](repeating: .missing, count: HashSlot.count)

    private var slotToShardID: [OptionalShardID] = Self.allSlotsMissing
    private var shardIDToShard: [ValkeyClusterDescription.Shard] = []

    package init() {}

    package subscript(_ key: HashSlot) -> ValkeyClusterDescription.Shard? {
        guard let shardID = self.slotToShardID[Int(key.rawValue)].value else {
            return nil
        }
        return self.shardIDToShard[shardID]
    }

    package mutating func updateCluster(_ shards: some Collection<ValkeyClusterDescription.Shard>) {
        self.slotToShardID = Self.allSlotsMissing
        self.shardIDToShard.removeAll(keepingCapacity: true)
        self.shardIDToShard.reserveCapacity(shards.count)

        var shardID = 0
        for shard in shards {
            defer { shardID += 1 }
            self.shardIDToShard.append(shard)

            for range in shard.slots {
                for slot in range {
                    self.slotToShardID[Int(slot.rawValue)] = .init(shardID)
                }
            }
        }
    }

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

