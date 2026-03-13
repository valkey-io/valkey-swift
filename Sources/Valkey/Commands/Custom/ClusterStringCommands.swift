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

    public func subCommand(for indices: [Int]) -> MGET {
        MGET(keys: indices.map { self.keys[$0] })
    }

    /// Assembles per-slot MGET results into a single ``RESPToken/Array``.
    ///
    /// Each element in the returned array corresponds to the key at the same
    /// position in the original `MGET`. Null tokens represent absent keys.
    public static func assemble(
        originalKeyCount: Int,
        slotResults: [(indices: [Int], result: Result<RESPToken.Array, ValkeyClientError>)]
    ) throws(ValkeyClientError) -> RESPToken.Array {
        // Pre-fill every position with a RESP3 null token (`_\r\n`).
        // Positions are overwritten with actual values as sub-results arrive.
        var tokenBases = [ByteBuffer](repeating: RESPToken.nullToken.base, count: originalKeyCount)

        for (indices, result) in slotResults {
            let resultArray = try result.get()
            var resultIterator = resultArray.makeIterator()
            for originalIndex in indices {
                guard let token = resultIterator.next() else { break }
                tokenBases[originalIndex] = token.base
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

// MARK: - MSET

@available(valkeySwift 1.0, *)
extension MSET: ValkeyClusterMultiKeyCommand {

    public func subCommand(for indices: [Int]) -> MSET<Value> {
        MSET(data: indices.map { self.data[$0] })
    }

    /// Checks that every per-slot MSET succeeded and returns the last OK token.
    ///
    /// - Important: Cross-slot `MSET` is **not atomic**. Keys on different nodes
    ///   may be written at different times. If any node fails, an error is thrown
    ///   but keys already written to other nodes are **not** rolled back.
    public static func assemble(
        originalKeyCount: Int,
        slotResults: [(indices: [Int], result: Result<RESPToken, ValkeyClientError>)]
    ) throws(ValkeyClientError) -> RESPToken {
        var lastToken: RESPToken?
        for (_, result) in slotResults {
            lastToken = try result.get()
        }
        guard let token = lastToken else {
            // No sub-commands were run (empty data). Synthesise an OK response.
            var okBuffer = ByteBuffer()
            okBuffer.writeStaticString("+OK\r\n")
            return RESPToken(validated: okBuffer)
        }
        return token
    }
}
