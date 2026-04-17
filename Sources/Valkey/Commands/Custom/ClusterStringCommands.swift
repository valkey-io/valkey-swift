//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import NIOCore

// MARK: - MGET

@available(valkeySwift 1.0, *)
extension MGET: ValkeyClusterMultiKeyCommand {

    package func createSubCommand(for indices: [Int]) -> MGET {
        MGET(keys: indices.map { self.keys[$0] })
    }

    /// Combines per-slot MGET results into a single ``RESPToken/Array``.
    ///
    /// Each element in the returned array corresponds to the key at the same
    /// position in the original `MGET`. Null tokens represent absent keys.
    package static func combineResults(
        originalKeyCount: Int,
        slotResults: [(indices: [Int], result: RESPToken)]
    ) throws(RESPDecodeError) -> RESPToken.Array {
        // Pre-fill every position with a RESP3 null token (`_\r\n`).
        // Positions are overwritten with actual values as sub-results arrive.
        var tokenBases = [ByteBuffer](repeating: RESPToken.nullToken.base, count: originalKeyCount)

        for (indices, result) in slotResults {
            let resultArray = try RESPToken.Array(result)

            var resultIterator = resultArray.makeIterator()
            for originalIndex in indices {
                guard let element = resultIterator.next() else {
                    throw RESPDecodeError(
                        .invalidArraySize,
                        token: result,
                        message: "Mismatch between key count: \(indices.count) and response count: \(resultArray.count) for indices: \(indices)"
                    )
                }
                tokenBases[originalIndex] = element.base
            }
        }

        // Build wire-format RESP3 array: `*N\r\n` followed by each element's bytes.
        let header = "*\(originalKeyCount)\r\n"
        let totalSize = header.utf8.count + tokenBases.reduce(0) { $0 + $1.readableBytes }
        var buffer = ByteBuffer()
        buffer.reserveCapacity(totalSize)
        buffer.writeString(header)
        for base in tokenBases {
            buffer.writeImmutableBuffer(base)
        }

        return try RESPToken.Array(RESPToken(validated: buffer))
    }
}

// MARK: - ValkeyClusterClient + MGET

@available(valkeySwift 1.0, *)
extension ValkeyClusterClient {

    /// Returns the string values of one or more keys, transparently
    /// routing sub-commands across cluster nodes for keys in different hash slots.
    ///
    /// - Documentation: [MGET](https://valkey.io/commands/mget)
    /// - Complexity: O(N) where N is the number of keys to retrieve.
    /// - Parameter keys: The keys whose values to retrieve.
    /// - Returns: A ``RESPToken/Array`` with values in the same order as `keys`.
    ///   Null tokens represent absent keys.
    /// - Throws: ``ValkeyClientError`` if any node fails.
    public func mget(keys: [ValkeyKey]) async throws(ValkeyClientError) -> RESPToken.Array {
        try await executeMultiKeyCommand(MGET(keys: keys))
    }
}
