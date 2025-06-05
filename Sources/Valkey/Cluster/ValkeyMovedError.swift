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

import NIOCore

/// Represents a `MOVED` redirection error from a Valkey cluster node.
///
/// When a client sends a command to a Valkey cluster node that doesn't own
/// the hash slot for the specified key, the node responds with a `MOVED` error
/// containing information about which node actually owns that slot.
///
/// This error provides the necessary information for clients to redirect their
/// request to the correct node in the cluster.
@usableFromInline
struct ValkeyMovedError: Hashable, Sendable {
    /// The hash slot number that triggered the redirection.
    var slot: HashSlot
    
    /// The hostname or IP address of the node that owns the requested hash slot.
    var endpoint: String
    
    /// The port number of the node that owns the requested hash slot.
    var port: Int

    @usableFromInline
    var nodeID: ValkeyNodeID {
        ValkeyNodeID(endpoint: self.endpoint, port: self.port)
    }
}

extension RESPToken {
    static let movedPrefix = "MOVED "

    /// Attempts to parse a RESP error token as a Valkey MOVED error.
    ///
    /// This method extracts the hash slot, endpoint, and port information from a RESP error
    /// token if it represents a Valkey MOVED error. MOVED errors are returned by Valkey cluster 
    /// nodes when a client attempts to access a key that belongs to a different node.
    ///
    /// The error format is expected to be: `"MOVED <slot> <endpoint>:<port>"`
    ///
    /// - Returns: A `ValkeyMovedError` if the token represents a valid MOVED error, or `nil` otherwise.
    @usableFromInline
    func parseMovedError() -> ValkeyMovedError? {
        let byteBuffer: ByteBuffer? = switch self.value {
        case .bulkError(let byteBuffer),
             .simpleError(let byteBuffer):
            byteBuffer

        case .simpleString,
             .bulkString,
             .verbatimString,
             .number,
             .double,
             .boolean,
             .bigNumber,
             .array,
             .attribute,
             .map,
             .set,
             .push,
             .null:
            nil
        }

        guard var byteBuffer else {
            return nil
        }
        let errorMessage = byteBuffer.readString(length: byteBuffer.readableBytes)!
        guard errorMessage.hasPrefix(Self.movedPrefix) else {
            return nil
        }

        let msg = errorMessage.dropFirst(Self.movedPrefix.count)
        guard let spaceAfterSlotIndex = msg.firstIndex(where: { $0 == " " }) else {
            return nil
        }

        let hashSlice = msg[msg.startIndex..<spaceAfterSlotIndex]
        guard let hashInt = UInt16(hashSlice), let slot = HashSlot(rawValue: hashInt) else {
            return nil
        }

        let firstEndpointIndex = msg.index(after: spaceAfterSlotIndex)

        guard let colonIndex = msg[spaceAfterSlotIndex...].firstIndex(where: { $0 == ":" }) else {
            return nil
        }

        let firstPortIndex = msg.index(after: colonIndex)

        let endpoint = msg[firstEndpointIndex..<colonIndex]
        guard let port = Int(msg[firstPortIndex...]) else {
            return nil
        }

        return ValkeyMovedError(slot: slot, endpoint: String(endpoint), port: port)
    }
}

