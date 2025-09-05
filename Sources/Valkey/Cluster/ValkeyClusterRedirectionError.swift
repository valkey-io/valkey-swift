//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore

/// Represents a redirection error from a Valkey cluster node.
///
/// When a client sends a command to a Valkey cluster node that doesn't own
/// the hash slot for the specified key, the node responds with a `MOVED` error
/// containing information about which node actually owns that slot.
///
/// When a client sends a command to a Valkey cluster node for a hash slot that
/// is currently migrating for a key that does not exist the node responds
/// with a `ASK` error containing information about which node is importing
/// that hash slot
///
/// This error provides the necessary information for clients to redirect their
/// request to the correct node in the cluster.
@usableFromInline
package struct ValkeyClusterRedirectionError: Hashable, Sendable {
    @usableFromInline
    package enum Redirection: Sendable {
        case move
        case ask
    }

    /// Request type
    @usableFromInline
    package var redirection: Redirection

    /// The hash slot number that triggered the redirection.
    package var slot: HashSlot

    /// The hostname or IP address of the node that owns the requested hash slot.
    package var endpoint: String

    /// The port number of the node that owns the requested hash slot.
    package var port: Int

    package init(request: Redirection, slot: HashSlot, endpoint: String, port: Int) {
        self.redirection = request
        self.slot = slot
        self.endpoint = endpoint
        self.port = port
    }

    @usableFromInline
    package var nodeID: ValkeyNodeID {
        ValkeyNodeID(endpoint: self.endpoint, port: self.port)
    }
}

extension ValkeyClusterRedirectionError {
    static let movedPrefix = "MOVED "
    static let askPrefix = "ASK "

    /// Attempts to parse a Valkey MOVED/ASK error from a String.
    ///
    /// This method extracts the hash slot, endpoint, and port information from the string
    /// if it represents a Valkey MOVED/ASK error. Redirection errors are returned by Valkey
    /// cluster nodes when a client attempts to access a key that belongs to a different node
    /// or the hashslot is currently migrating.
    ///
    /// The error format is expected to be: `"MOVED <slot> <endpoint>:<port>"`
    ///
    /// - Returns: A `ValkeyClusterRedirectionError` if the token represents a valid MOVED/ASK error, or `nil` otherwise.
    @usableFromInline
    init?(_ errorMessage: String) {
        let msg: String.SubSequence
        let request: Redirection
        if errorMessage.hasPrefix(Self.movedPrefix) {
            msg = errorMessage.dropFirst(Self.movedPrefix.count)
            request = .move
        } else if errorMessage.hasPrefix(Self.askPrefix) {
            msg = errorMessage.dropFirst(Self.askPrefix.count)
            request = .ask
        } else {
            return nil
        }
        guard let spaceAfterSlotIndex = msg.firstIndex(where: { $0 == " " }) else {
            return nil
        }

        let hashSlice = msg[msg.startIndex..<spaceAfterSlotIndex]
        guard let hashInt = UInt16(hashSlice), let slot = HashSlot(rawValue: hashInt) else {
            return nil
        }

        let firstEndpointIndex = msg.index(after: spaceAfterSlotIndex)

        guard let colonIndex = msg[spaceAfterSlotIndex...].lastIndex(of: ":") else {
            return nil
        }

        let firstPortIndex = msg.index(after: colonIndex)

        let endpoint = msg[firstEndpointIndex..<colonIndex]
        guard let port = Int(msg[firstPortIndex...]) else {
            return nil
        }

        self = ValkeyClusterRedirectionError(request: request, slot: slot, endpoint: Swift.String(endpoint), port: port)
    }
}
