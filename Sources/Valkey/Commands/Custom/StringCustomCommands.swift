//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
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

            public init(_ token: RESPToken) throws {
                (self.first, self.second) = try token.decodeArrayElements()
            }
        }

        public struct Matches: RESPTokenDecodable, Sendable {
            public let matches: [Match]
            public let length: Int64

            public init(_ token: RESPToken) throws {
                switch token.value {
                case .array(let array):
                    let map = try array.asMap()
                    self = try Matches(map)
                case .map(let map):
                    self = try Matches(map)
                default:
                    throw RESPDecodeError.tokenMismatch(expected: [.map], token: token)
                }
            }

            public init(_ map: RESPToken.Map) throws {
                (self.matches, self.length) = try map.decodeElements("matches", "len")
            }
        }

        let token: RESPToken

        public init(_ token: RESPToken) throws {
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
