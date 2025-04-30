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

extension LCS {
    /// - Returns: One of the following:
    ///     * [Bulk string](https:/valkey.io/topics/protocol/#bulk-strings): the longest common subsequence.
    ///     * [Integer](https:/valkey.io/topics/protocol/#integers): the length of the longest common subsequence when _LEN_ is given.
    ///     * [Map](https:/valkey.io/topics/protocol/#maps): a map with the LCS length and all the ranges in both the strings when _IDX_ is given.
    public enum Response: RESPTokenDecodable, Equatable {
        public struct Match: RESPTokenDecodable, Equatable {
            public let first: ClosedRange<Int>
            public let second: ClosedRange<Int>

            public init(fromRESP token: RESPToken) throws {
                (self.first, self.second) = try token.decodeArrayElements()
            }
        }

        case subSequence(String)
        case subSequenceLength(Int)
        case matches(length: Int, matches: [Match])

        public init(fromRESP token: RESPToken) throws {
            switch token.value {
            case .bulkString(let buffer):
                self = .subSequence(String(buffer: buffer))
            case .number(let number):
                self = .subSequenceLength(numericCast(number))
            case .map(let map):
                var matches: [Match]?
                var length: Int64?
                for entry in map {
                    switch try String(fromRESP: entry.key) {
                    case "len": length = try .init(fromRESP: entry.value)
                    case "matches": matches = try .init(fromRESP: entry.value)
                    default: break
                    }
                }
                guard let matches else { throw RESPParsingError(code: .unexpectedType, buffer: token.base) }
                guard let length else { throw RESPParsingError(code: .unexpectedType, buffer: token.base) }
                self = .matches(length: numericCast(length), matches: matches)
            default:
                throw RESPParsingError(code: .unexpectedType, buffer: token.base)
            }
        }
    }
}
