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
/// - ``subCommand(for:)`` — produce a sub-command scoped to a subset of keys.
/// - ``assemble(originalKeyCount:slotResults:)`` — merge per-slot results back
///   into the full command response.
@available(valkeySwift 1.0, *)
public protocol ValkeyClusterMultiKeyCommand: ValkeyCommand {

    /// Returns a sub-command containing only the keys at the given indices.
    ///
    /// - Parameter indices: Positions into this command's full key list that
    ///   belong to a single hash slot.
    /// - Returns: A new command of the same type scoped to those keys.
    func subCommand(for indices: [Int]) -> Self

    /// Assembles per-slot sub-results into the final command response.
    ///
    /// - Parameters:
    ///   - originalKeyCount: Total number of keys in the original command.
    ///   - slotResults: One entry per slot, each containing the original key
    ///     indices for that slot and the sub-command result.
    /// - Returns: The fully assembled response in original key order.
    /// - Throws: ``ValkeyClientError`` if any sub-result is a failure.
    static func assemble(
        originalKeyCount: Int,
        slotResults: [(indices: [Int], result: Result<Self.Response, ValkeyClientError>)]
    ) throws(ValkeyClientError) -> Self.Response
}
