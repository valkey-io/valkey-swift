//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore

/// Sorted set entry
@_documentation(visibility: internal)
public struct SortedSetEntry: RESPTokenDecodable, Sendable {
    public let value: RESPBulkString
    public let score: Double

    init(value: RESPBulkString, score: Double) {
        self.value = value
        self.score = score
    }

    public init(fromRESP token: RESPToken) throws {
        switch token.value {
        case .array(let array):
            (self.value, self.score) = try array.decodeElements()
        default:
            throw RESPDecodeError.tokenMismatch(expected: [.array], token: token)
        }
    }
}

extension BZMPOP {
    /// - Returns: One of the following
    ///     * [Null]: Timeout reached and no elements were popped.
    ///     * [Array]: The keyname and the popped members.
    public typealias Response = ZMPOP.Response
}
extension BZPOPMAX {
    /// - Returns: One of the following
    ///     * [Null]: Timeout reached and no elements were popped.
    ///     * [Array]: The keyname, popped member, and its score.
    public typealias Response = [SortedSetEntry]?
}

extension BZPOPMIN {
    /// - Returns: One of the following
    ///     * [Null]: Timeout reached and no elements were popped.
    ///     * [Array]: The keyname, popped member, and its score.
    public typealias Response = [SortedSetEntry]?
}

extension ZMPOP {
    /// - Returns: One of the following
    ///     * [Null]: No element could be popped.
    ///     * [Array]: Name of the key that elements were popped.
    public struct OptionalResponse: RESPTokenDecodable, Sendable {
        public let key: ValkeyKey
        public let values: [SortedSetEntry]

        public init(fromRESP token: RESPToken) throws {
            switch token.value {
            case .array(let array):
                (self.key, self.values) = try array.decodeElements()
            default:
                throw RESPDecodeError.tokenMismatch(expected: [.array], token: token)
            }
        }
    }
    public typealias Response = OptionalResponse?
}

extension ZPOPMAX {
    /// - Returns: One of the following
    ///     * [Array]: List of popped elements and scores when 'COUNT' isn't specified.
    ///     * [Array]: List of popped elements and scores when 'COUNT' is specified.
    public typealias Response = [SortedSetEntry]
}

extension ZPOPMIN {
    /// - Returns: One of the following
    ///     * [Array]: List of popped elements and scores when 'COUNT' isn't specified.
    ///     * [Array]: List of popped elements and scores when 'COUNT' is specified.
    public typealias Response = [SortedSetEntry]
}

extension ZSCAN {
    public struct Response: RESPTokenDecodable, Sendable {
        public struct Members: RESPTokenDecodable, Sendable {
            /// List of members and possibly scores.
            public let elements: RESPToken.Array

            public init(fromRESP token: RESPToken) throws {
                self.elements = try token.decode(as: RESPToken.Array.self)
            }

            /// if ZSCAN was called with the `NOSCORES` parameter use this
            /// function to get an array of members
            public func withoutScores() throws -> [RESPBulkString] {
                try self.elements.decode(as: [RESPBulkString].self)
            }

            /// if ZSCAN was called without the `NOSCORES` parameter use this
            /// function to get an array of members and scores
            public func withScores() throws -> [SortedSetEntry] {
                var array: [SortedSetEntry] = []
                for respElement in try self.elements.asMap() {
                    let value = try RESPBulkString(fromRESP: respElement.key)
                    let score = try Double(fromRESP: respElement.value)
                    array.append(.init(value: value, score: score))
                }
                return array
            }
        }
        /// Cursor to use in next call to ZSCAN
        public let cursor: Int
        /// Sorted set members
        public let members: Members

        public init(fromRESP token: RESPToken) throws {
            (self.cursor, self.members) = try token.decodeArrayElements()
        }
    }
}
