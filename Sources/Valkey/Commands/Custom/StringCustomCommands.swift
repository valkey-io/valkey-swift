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

extension ClosedRange: RESPTokenRepresentable where Bound: RESPTokenRepresentable {
    public init(from token: RESPToken) throws {
        let values = try token.decode(as: [Bound].self)
        guard values.count == 2 else { throw RESPParsingError(code: .unexpectedType, buffer: token.base) }
        self = values[0]...values[1]
    }
}

extension LCS {
    /// - Returns: One of the following:
    ///     * [Bulk string](https:/valkey.io/topics/protocol/#bulk-strings): the longest common subsequence.
    ///     * [Integer](https:/valkey.io/topics/protocol/#integers): the length of the longest common subsequence when _LEN_ is given.
    ///     * [Map](https:/valkey.io/topics/protocol/#maps): a map with the LCS length and all the ranges in both the strings when _IDX_ is given.
    public enum Response: RESPTokenRepresentable, Equatable {
        public struct Match: RESPTokenRepresentable, Equatable {
            public let first: ClosedRange<Int>
            public let second: ClosedRange<Int>

            public init(from token: RESPToken) throws {
                let ranges = try token.decode(as: [RESPToken].self)
                guard ranges.count == 2 else { throw RESPParsingError(code: .unexpectedType, buffer: token.base) }
                self.first = try .init(from: ranges[0])
                self.second = try .init(from: ranges[1])
            }
        }

        case subSequence(String)
        case subSequenceLength(Int)
        case matches(length: Int, matches: [Match])

        public init(from token: RESPToken) throws {
            if let string = try? String(from: token) {
                self = .subSequence(string)
            } else if let length = try? Int(from: token) {
                self = .subSequenceLength(length)
            } else if let map = try? [String: RESPToken](from: token) {
                guard let matches = map["matches"], let length = map["len"] else {
                    throw RESPParsingError(code: .unexpectedType, buffer: token.base)
                }
                self = .matches(length: try Int(from: length), matches: try [Match](from: matches))
            } else {
                throw RESPParsingError(code: .unexpectedType, buffer: token.base)
            }
        }
    }
}
