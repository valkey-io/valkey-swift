//
// This source file is part of the valkey-swift project
// Copyright (c) 2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
/// Represents the mapping of nodes in a Valkey shard, consisting of a primary node and optional replicas.
@usableFromInline
package struct ValkeyNodeIDs<ID: Sendable & Hashable>: Hashable, Sendable {
    /// The primary node responsible for handling write operations for this shard.
    @usableFromInline
    package var primary: ID

    /// The replica nodes that maintain copies of the primary's data.
    /// Replicas can handle read operations but not writes.
    @usableFromInline
    package var replicas: [ID]

    /// Creates a new shard node mapping with the specified primary and optional replicas.
    ///
    /// - Parameters:
    ///   - primary: The primary node ID for this shard
    ///   - replicas: An array of replica node IDs, defaults to empty
    @inlinable
    package init(primary: ID, replicas: [ID] = []) {
        self.primary = primary
        self.replicas = replicas
    }
}

extension ValkeyNodeIDs: ExpressibleByArrayLiteral {
    @usableFromInline
    package typealias ArrayLiteralElement = ID

    @usableFromInline
    package init(arrayLiteral elements: ID...) {
        precondition(!elements.isEmpty, "ValkeyShardNodeIDs requires at least one node ID for the primary")
        self.primary = elements.first!
        self.replicas = Array(elements.dropFirst())
    }
}
