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

    public func createSubCommand(for indices: [Int]) -> MGET {
        MGET(keys: indices.map { self.keys[$0] })
    }

    /// Combines per-slot MGET results into a single ``RESPToken/Array``.
    ///
    /// Each element in the returned array corresponds to the key at the same
    /// position in the original `MGET`. Null tokens represent absent keys.
    public static func combineResults(
        originalKeyCount: Int,
        slotResults: [(indices: [Int], result: Result<RESPToken, ValkeyClientError>)]
    ) throws(ValkeyClientError) -> RESPToken.Array {
        // Pre-fill every position with a RESP3 null token (`_\r\n`).
        // Positions are overwritten with actual values as sub-results arrive.
        var tokenBases = [ByteBuffer](repeating: RESPToken.nullToken.base, count: originalKeyCount)

        for (indices, result) in slotResults {
            let token = try result.get()
            let resultArray: RESPToken.Array
            do {
                resultArray = try RESPToken.Array(token)
            } catch {
                throw ValkeyClientError(.respDecodeError, error: error)
            }

            var resultIterator = resultArray.makeIterator()
            for originalIndex in indices {
                guard let element = resultIterator.next() else { break }
                tokenBases[originalIndex] = element.base
            }
        }

        // Build wire-format RESP3 array: `*N\r\n` followed by each element's bytes.
        var buffer = ByteBuffer()
        buffer.writeString("*\(originalKeyCount)\r\n")
        for base in tokenBases {
            buffer.writeImmutableBuffer(base)
        }

        let arrayToken = RESPToken(validated: buffer)
        do {
            return try RESPToken.Array(arrayToken)
        } catch {
            throw ValkeyClientError(.respDecodeError, error: error)
        }
    }
}
