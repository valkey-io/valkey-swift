//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

@available(valkeySwift 1.0, *)
extension ValkeyClusterClient {

    // MARK: - Scatter-gather execute

    /// Executes a multi-key command against the cluster using scatter-gather.
    ///
    /// Keys are partitioned by hash slot. One sub-command is dispatched per slot,
    /// all slots are executed in parallel, and results are reassembled in the
    /// original key order via ``ValkeyClusterMultiKeyCommand/assemble(originalKeyCount:slotResults:)``.
    ///
    /// - Parameter command: A command conforming to ``ValkeyClusterMultiKeyCommand``.
    /// - Returns: The assembled command response in original key order.
    /// - Throws: ``ValkeyClientError`` if execution on any node fails.
    package func executeMultiKeyCommand<Command: ValkeyClusterMultiKeyCommand>(
        _ command: Command
    ) async throws(ValkeyClientError) -> Command.Response {
        let keys = command.keysAffected

        // Single-slot fast path
        guard let partitions = partitionBySlot(keys: keys) else {
            return try await execute(command)
        }

        // Build one sub-command per slot
        let subCommands: [any ValkeyCommand] = partitions.map { command.createSubCommand(for: $0.indices) }

        // Dispatch in parallel using the existing cross-node pipelining path.
        let rawResults = await self.execute(subCommands)

        // Unwrap results and pair with original key indices for combineResults.
        var slotResults: [(indices: [Int], result: RESPToken)] = []
        slotResults.reserveCapacity(partitions.count)
        for (i, partition) in partitions.enumerated() {
            let token = try rawResults[i].get()
            slotResults.append((indices: partition.indices, result: token))
        }

        do {
            return try Command.combineResults(originalKeyCount: keys.count, slotResults: slotResults)
        } catch {
            throw ValkeyClientError(.respDecodeError, error: error)
        }
    }

    /// Groups key indices by hash slot.
    ///
    /// Returns `nil` when all keys belong to a single slot (or there are no keys),
    /// otherwise returns an array containing slot and indices for keys belonging to the slot.
    ///
    /// - Returns: An array of `(slot, indices)` pairs when keys span multiple slots, or `nil`.
    private func partitionBySlot(
        keys: some Collection<ValkeyKey>
    ) -> [(slot: HashSlot, indices: [Int])]? {
        guard let firstKey = keys.first else { return nil }

        let firstSlot = HashSlot(key: firstKey)
        var slotIndices: [HashSlot: [Int]]?

        for (i, key) in keys.enumerated() {
            let slot = HashSlot(key: key)
            if slotIndices != nil {
                slotIndices![slot, default: []].append(i)
            } else if slot != firstSlot {
                // Second distinct slot found — backfill indices for firstSlot
                slotIndices = [firstSlot: Array(0..<i), slot: [i]]
            }
        }

        guard let slotIndices else { return nil }
        return slotIndices.map { (slot: $0.key, indices: $0.value) }
    }
}
