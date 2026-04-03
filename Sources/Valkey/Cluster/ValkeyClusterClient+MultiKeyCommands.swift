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
    @inlinable
    public func execute<Command: ValkeyClusterMultiKeyCommand>(
        _ command: Command
    ) async throws(ValkeyClientError) -> Command.Response {
        let keys = command.keysAffected
        let partitions = partitionBySlot(keys: keys)

        // Single-slot fast path: all keys hash to the same slot, so execute
        // the original command directly via the standard code path.
        // This avoids sub-command creation and result recombination.
        if partitions.count <= 1 {
            return try await executeSingleCommand(command)
        }

        // Build one sub-command per slot, cast to the type-erased protocol.
        let subCommands: [any ValkeyCommand] = partitions.map { command.createSubCommand(for: $0.indices) }

        // Dispatch in parallel using the existing cross-node pipelining path.
        // Each sub-command contains only same-slot keys, so hashSlot() never
        // throws keysInCommandRequireMultipleHashSlots for sub-commands.
        let rawResults = await self.execute(subCommands)

        // Pair each raw result with its original key indices for combineResults.
        let slotResults = partitions.enumerated().map { i, partition in
            (indices: partition.indices, result: rawResults[i])
        }

        return try Command.combineResults(originalKeyCount: keys.count, slotResults: slotResults)
    }

    // MARK: - Concrete mget (shadow ValkeyClientProtocol extension method)
    //
    // This concrete method is preferred over the protocol-extension default
    // for static dispatch on ValkeyClusterClient. It calls execute(_:) which
    // resolves — via static dispatch — to the constrained
    // execute<Command: ValkeyClusterMultiKeyCommand> overload above, enabling
    // transparent cross-slot scatter/gather.

    /// Atomically returns the string values of one or more keys, transparently
    /// routing sub-commands across cluster nodes for keys in different hash slots.
    ///
    /// - Documentation: [MGET](https://valkey.io/commands/mget)
    /// - Complexity: O(N) where N is the number of keys to retrieve.
    /// - Parameter keys: The keys whose values to retrieve.
    /// - Returns: A ``RESPToken/Array`` with values in the same order as `keys`.
    ///   Null tokens represent absent keys.
    /// - Throws: ``ValkeyClientError`` if any node fails.
    @inlinable
    public func mget(keys: [ValkeyKey]) async throws(ValkeyClientError) -> RESPToken.Array {
        try await execute(MGET(keys: keys))
    }

    // MARK: - Internal helpers

    /// Executes a single command via the standard ``ValkeyCommand`` code path.
    ///
    /// This trampoline exists because `execute<C: ValkeyClusterMultiKeyCommand>`
    /// would otherwise recursively call itself — Swift overload resolution prefers
    /// the more constrained overload. Inside this helper the compiler only sees
    /// `Command: ValkeyCommand`, so it resolves to the base `execute` overload.
    @usableFromInline
    /* private */ func executeSingleCommand<Command: ValkeyCommand>(
        _ command: Command
    ) async throws(ValkeyClientError) -> Command.Response {
        try await self.execute(command)
    }

    /// Groups key indices by hash slot.
    ///
    /// - Returns: An array of `(slot, indices)` pairs, one per unique slot.
    @usableFromInline
    /* private */ func partitionBySlot(
        keys: some Collection<ValkeyKey>
    ) -> [(slot: HashSlot, indices: [Int])] {
        var slotIndices: [HashSlot: [Int]] = [:]

        for (i, key) in keys.enumerated() {
            let slot = HashSlot(key: key)
            slotIndices[slot, default: []].append(i)
        }

        return slotIndices.map { (slot: $0.key, indices: $0.value) }
    }
}
