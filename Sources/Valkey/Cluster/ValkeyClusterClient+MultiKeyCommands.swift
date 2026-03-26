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

        // Build one sub-command per slot, cast to the type-erased protocol.
        let subCommands: [any ValkeyCommand] = partitions.map { command.subCommand(for: $0.indices) }

        // Dispatch in parallel using the existing cross-node pipelining path.
        // Each sub-command contains only same-slot keys, so hashSlot() never
        // throws keysInCommandRequireMultipleHashSlots for sub-commands.
        let rawResults = await self.execute(subCommands)

        // Map each raw Result<RESPToken, ValkeyClientError> to the typed Response.
        let slotResults = partitions.enumerated().map { i, partition in
            (indices: partition.indices, result: rawResults[i].convertFromRESP(to: Command.Response.self))
        }

        return try Command.assemble(originalKeyCount: keys.count, slotResults: slotResults)
    }

    // MARK: - Concrete mget / mset (shadow ValkeyClientProtocol extension methods)
    //
    // These concrete methods are preferred over the protocol-extension defaults
    // for static dispatch on ValkeyClusterClient. They call execute(_:) which
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

    /// Sets the string values of one or more keys, transparently routing
    /// sub-commands across cluster nodes for keys in different hash slots.
    ///
    /// - Documentation: [MSET](https://valkey.io/commands/mset)
    /// - Complexity: O(N) where N is the number of keys to set.
    /// - Important: Cross-slot `MSET` is **not atomic**. Keys on different nodes
    ///   may be written at different times. Use hash tags to co-locate keys that
    ///   need to be set atomically.
    /// - Parameter data: Key-value pairs to set.
    /// - Throws: ``ValkeyClientError`` if any node fails. Keys already written
    ///   to other nodes are **not** rolled back.
    @inlinable
    public func mset<Value: RESPStringRenderable>(data: [MSET<Value>.Data]) async throws(ValkeyClientError) {
        _ = try await execute(MSET(data: data))
    }

    // MARK: - Internal helpers

    /// Groups key indices by hash slot, preserving insertion order of first occurrence.
    ///
    /// - Returns: An array of `(indices, slot)` pairs, one per unique slot, in the
    ///   order the slots were first encountered while iterating `keys`.
    @usableFromInline
    /* private */ func partitionBySlot(
        keys: some Collection<ValkeyKey>
    ) -> [(indices: [Int], slot: HashSlot)] {
        var slotOrder: [HashSlot] = []
        var slotIndices: [HashSlot: [Int]] = [:]

        for (i, key) in keys.enumerated() {
            let slot = HashSlot(key: key)
            if slotIndices[slot] == nil {
                slotOrder.append(slot)
                slotIndices[slot] = []
            }
            slotIndices[slot]!.append(i)
        }

        return slotOrder.map { (indices: slotIndices[$0]!, slot: $0) }
    }
}
