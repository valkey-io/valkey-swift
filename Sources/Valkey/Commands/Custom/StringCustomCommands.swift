//
// This source file is part of the valkey-swift project
// Copyright (c) 2025-2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore

extension LCS {
    /// - Returns: One of the following:
    ///     * [Bulk string](https:/valkey.io/topics/protocol/#bulk-strings): the longest common subsequence.
    ///     * [Integer](https:/valkey.io/topics/protocol/#integers): the length of the longest common subsequence when _LEN_ is given.
    ///     * [Map](https:/valkey.io/topics/protocol/#maps): a map with the LCS length and all the ranges in both the strings when _IDX_ is given.
    public struct Response: RESPTokenDecodable, Equatable, Sendable {
        public struct Match: RESPTokenDecodable, Equatable, Sendable {
            public let first: ClosedRange<Int>
            public let second: ClosedRange<Int>

            public init(_ token: RESPToken) throws(RESPDecodeError) {
                (self.first, self.second) = try token.decodeArrayElements()
            }
        }

        public struct Matches: RESPTokenDecodable, Sendable {
            public let matches: [Match]
            public let length: Int64

            public init(_ token: RESPToken) throws(RESPDecodeError) {
                (self.matches, self.length) = try token.decodeMapValues("matches", "len")
            }
        }

        let token: RESPToken

        public init(_ token: RESPToken) throws(RESPDecodeError) {
            self.token = token
        }

        ///  Return longest common sub-sequence
        ///
        ///  This should only be called if you didn't ask for the length or indices
        /// - Throws: RESPDecodeError
        /// - Returns: sub-sequence string
        public func longestMatch() throws -> String {
            try String(self.token)
        }

        ///  Return length of longest common sub-sequence
        ///
        ///  This should only be called if you asked for the length of the subsequence
        /// - Throws: RESPDecodeError
        /// - Returns: Length of sub-sequence string
        public func longestMatchLength() throws -> Int {
            try Int(self.token)
        }

        ///  Return length and range in each string of each match
        ///
        ///  This should only be called if you asked for the length of the subsequence
        /// - Throws: RESPDecodeError
        /// - Returns: Length of sub-sequence string
        public func matches() throws -> Matches {
            try Matches(self.token)
        }
    }
}

// MARK: Backwards compatibilty

extension LCS {
    @available(*, deprecated, renamed: "LCS.init(key1:key2:output:minMatchLen:withmatchlen:)")
    @inlinable
    public init(
        key1: ValkeyKey,
        key2: ValkeyKey,
        len: Bool = false,
        idx: Bool = false,
        minMatchLen: Int? = nil,
        withmatchlen: Bool = false
    ) {
        self.key1 = key1
        self.key2 = key2
        self.output =
            switch (len, idx) {
            case (true, false): .len
            case (false, true): .idx
            case (false, false): nil
            case (true, true):
                preconditionFailure("Cannot set both len and idx in LCS")
            }
        self.minMatchLen = minMatchLen
        self.withmatchlen = withmatchlen
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyClientProtocol {

    /// Finds the longest common substring.
    ///
    /// - Documentation: [LCS](https://valkey.io/commands/lcs)
    /// - Available: 7.0.0
    /// - Complexity: O(N*M) where N and M are the lengths of s1 and s2, respectively
    /// - Returns: One of the following
    ///     * The longest common subsequence.
    ///     * The length of the longest common subsequence when 'LEN' is given.
    ///     * Array with the LCS length and all the ranges in both the strings when 'IDX' is given. In RESP2 this is returned as a flat array
    @inlinable
    @available(*, deprecated, renamed: "ValkeyClientProtocol.lcs(key1:key2:output:minMatchLen:withmatchlen:)")
    public func lcs(
        key1: ValkeyKey,
        key2: ValkeyKey,
        len: Bool = false,
        idx: Bool = false,
        minMatchLen: Int? = nil,
        withmatchlen: Bool = false
    ) async throws(ValkeyClientError) -> LCS.Response {
        try await execute(LCS(key1: key1, key2: key2, len: len, idx: idx, minMatchLen: minMatchLen, withmatchlen: withmatchlen))
    }
}
