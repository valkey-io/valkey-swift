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
        let values = try token.converting(to: [Bound].self)
        guard values.count == 2 else { throw RESPParsingError(code: .unexpectedType, buffer: token.base) }
        self = values[0]...values[1]
    }
}

// MARK: String command return values

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
                let ranges = try token.converting(to: [RESPToken].self)
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

// MARK: List command return values

extension LPOP {
    /// - Returns: One of the following:
    ///     * [Null](https:/valkey.io/topics/protocol/#nulls): if the key does not exist.
    ///     * [Bulk string](https:/valkey.io/topics/protocol/#bulk-strings): when called without the _count_ argument, the value of the first element.
    ///     * [Array](https:/valkey.io/topics/protocol/#arrays): when called with the _count_ argument, a list of popped elements.
    public typealias Response = [String]?
}

extension LPOS {
    /// - Returns: Any of the following:
    ///     * [Null](https:/valkey.io/topics/protocol/#nulls): if there is no matching element.
    ///     * [Integer](https:/valkey.io/topics/protocol/#integers): an integer representing the matching element.
    ///     * [Array](https:/valkey.io/topics/protocol/#arrays): If the COUNT option is given, an array of integers representing the matching elements (or an empty array if there are no matches).
    public typealias Response = [Int]?
}

extension RPOP {
    /// - Returns: One of the following:
    ///     * [Null](https:/valkey.io/topics/protocol/#nulls): if the key does not exist.
    ///     * [Bulk string](https:/valkey.io/topics/protocol/#bulk-strings): when called without the _count_ argument, the value of the last element.
    ///     * [Array](https:/valkey.io/topics/protocol/#arrays): when called with the _count_ argument, a list of popped elements.
    public typealias Response = [String]?
}
