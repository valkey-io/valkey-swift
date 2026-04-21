//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

/// A Valkey command that operates on multiple keys and can be transparently
/// scattered across cluster nodes when keys span multiple hash slots.
///
/// When executed against a ``ValkeyClusterClient``, the client partitions keys by
/// hash slot, dispatches one sub-command per slot in parallel, and reassembles
/// results in the original key order.
///
/// Conforming types must implement two requirements:
/// - ``createSubCommand(for:)`` — produce a sub-command scoped to a subset of keys.
/// - ``combineResults(originalKeyCount:slotResults:)`` — merge per-slot results back
///   into the full command response.
@available(valkeySwift 1.0, *)
package protocol ValkeyClusterMultiKeyCommand: ValkeyCommand {

    /// Returns a sub-command containing only the keys at the given indices.
    ///
    /// - Parameter indices: Positions into this command's full key list that
    ///   belong to a single hash slot.
    /// - Returns: A new command of the same type scoped to those keys.
    func createSubCommand(for indices: [Int]) -> Self

    /// Combines per-slot raw RESP results into the final command response.
    ///
    /// Conforming types receive the raw ``RESPToken`` from each sub-command,
    /// avoiding an intermediate conversion to the typed `Response`. This lets
    /// implementations parse RESP directly and reduce allocations.
    ///
    /// - Parameters:
    ///   - originalKeyCount: Total number of keys in the original command.
    ///   - slotResults: One entry per slot, each containing the original key
    ///     indices for that slot and the successful RESP token.
    /// - Returns: The fully combined response in original key order.
    /// - Throws: ``RESPDecodeError`` if any sub-result cannot be decoded.
    static func combineResults(
        originalKeyCount: Int,
        slotResults: [(indices: [Int], result: RESPToken)]
    ) throws(RESPDecodeError) -> Self.Response
}
