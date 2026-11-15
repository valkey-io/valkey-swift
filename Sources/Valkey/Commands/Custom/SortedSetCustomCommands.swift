//
// This source file is part of the valkey-swift project
// Copyright (c) 2025-2026 the valkey-swift project authors
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

    public init(_ token: RESPToken) throws(RESPDecodeError) {
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

        public init(_ token: RESPToken) throws(RESPDecodeError) {
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

            public init(_ token: RESPToken) throws(RESPDecodeError) {
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
                    let value = try RESPBulkString(respElement.key)
                    let score = try Double(respElement.value)
                    array.append(.init(value: value, score: score))
                }
                return array
            }
        }
        /// Cursor to use in next call to ZSCAN
        public let cursor: Int
        /// Sorted set members
        public let members: Members

        public init(_ token: RESPToken) throws(RESPDecodeError) {
            (self.cursor, self.members) = try token.decodeArrayElements()
        }
    }
}

extension ZRANDMEMBER {
    /// Custom response type for ZRANDMEMBER command that handles all possible return scenarios
    public struct Response: RESPTokenDecodable, Sendable {
        /// The raw RESP token containing the response
        public let token: RESPToken

        public init(_ token: RESPToken) throws(RESPDecodeError) {
            self.token = token
        }

        /// Get single random member when ZRANDMEMBER was called without COUNT
        /// - Returns: Random member as RESPBulkString, or nil if key doesn't exist
        /// - Throws: RESPDecodeError if response format is unexpected
        public func singleMember() throws -> RESPBulkString? {
            try RESPBulkString?(token)
        }

        /// Get multiple random members when ZRANDMEMBER was called with COUNT but without WITHSCORES
        /// - Returns: Array of member names as RESPBulkString, or nil if key doesn't exist
        /// - Throws: RESPDecodeError if response format is unexpected
        @inlinable
        public func multipleMembers() throws -> [RESPBulkString]? {
            try [RESPBulkString]?(token)
        }

        /// Get multiple random member-score pairs when ZRANDMEMBER was called with COUNT and WITHSCORES
        /// - Returns: Array of SortedSetEntry (member-score pairs), or nil if key doesn't exist
        /// - Throws: RESPDecodeError if response format is unexpected
        public func multipleMembersWithScores() throws -> [SortedSetEntry]? {
            switch token.value {
            case .null:
                return nil
            case .array(let array):
                return try array.asMap().map {
                    try SortedSetEntry(value: RESPBulkString($0.key), score: Double($0.value))
                }
            default:
                throw RESPDecodeError.tokenMismatch(expected: [.null, .array], token: token)
            }
        }
    }
}

// MARK: Backwards compatibility

extension ZINCRBY {
    @_disfavoredOverload
    @inlinable public init(_ key: ValkeyKey, increment: Int, member: Member) {
        self.key = key
        self.increment = Double(increment)
        self.member = member
    }
}

extension ZINTER {
    @_disfavoredOverload
    @inlinable public init(keys: [ValkeyKey], weights: [Int] = [], aggregate: Aggregate? = nil, withscores: Bool = false) {
        self.keys = keys
        self.weights = weights.map { Double($0) }
        self.aggregate = aggregate
        self.withscores = withscores
    }
}

extension ZINTERSTORE {
    @_disfavoredOverload
    @inlinable public init(destination: ValkeyKey, keys: [ValkeyKey], weights: [Int] = [], aggregate: Aggregate? = nil) {
        self.destination = destination
        self.keys = keys
        self.weights = weights.map { Double($0) }
        self.aggregate = aggregate
    }
}

extension ZUNION {
    @_disfavoredOverload
    @inlinable public init(keys: [ValkeyKey], weights: [Int] = [], aggregate: Aggregate? = nil, withscores: Bool = false) {
        self.keys = keys
        self.weights = weights.map { Double($0) }
        self.aggregate = aggregate
        self.withscores = withscores
    }
}

extension ZUNIONSTORE {
    @_disfavoredOverload
    @inlinable public init(destination: ValkeyKey, keys: [ValkeyKey], weights: [Int] = [], aggregate: Aggregate? = nil) {
        self.destination = destination
        self.keys = keys
        self.weights = weights.map { Double($0) }
        self.aggregate = aggregate
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyClientProtocol {
    /// Increments the score of a member in a sorted set.
    ///
    /// - Documentation: [ZINCRBY](https://valkey.io/commands/zincrby)
    /// - Available: 1.2.0
    /// - Complexity: O(log(N)) where N is the number of elements in the sorted set.
    /// - Returns: The new score of `member`
    @inlinable
    @discardableResult
    @_disfavoredOverload
    public func zincrby<Member: RESPStringRenderable>(_ key: ValkeyKey, increment: Int, member: Member) async throws(ValkeyClientError) -> Double {
        try await execute(ZINCRBY(key, increment: increment, member: member))
    }

    /// Returns the intersect of multiple sorted sets.
    ///
    /// - Documentation: [ZINTER](https://valkey.io/commands/zinter)
    /// - Available: 6.2.0
    /// - Complexity: O(N*K)+O(M*log(M)) worst case with N being the smallest input sorted set, K being the number of input sorted sets and M being the number of elements in the resulting sorted set.
    /// - Returns: One of the following
    ///     * Result of intersection, containing only the member names. Returned in case `WITHSCORES` was not used.
    ///     * Result of intersection, containing members and their scores. Returned in case `WITHSCORES` was used. In RESP2 this is returned as a flat array
    @inlinable
    @_disfavoredOverload
    public func zinter(
        keys: [ValkeyKey],
        weights: [Int] = [],
        aggregate: ZINTER.Aggregate? = nil,
        withscores: Bool = false
    ) async throws(ValkeyClientError) -> RESPToken.Array {
        try await execute(ZINTER(keys: keys, weights: weights, aggregate: aggregate, withscores: withscores))
    }

    /// Stores the intersect of multiple sorted sets in a key.
    ///
    /// - Documentation: [ZINTERSTORE](https://valkey.io/commands/zinterstore)
    /// - Available: 2.0.0
    /// - Complexity: O(N*K)+O(M*log(M)) worst case with N being the smallest input sorted set, K being the number of input sorted sets and M being the number of elements in the resulting sorted set.
    /// - Returns: Number of elements in the resulting sorted set.
    @inlinable
    @discardableResult
    @_disfavoredOverload
    public func zinterstore(
        destination: ValkeyKey,
        keys: [ValkeyKey],
        weights: [Int] = [],
        aggregate: ZINTERSTORE.Aggregate? = nil
    ) async throws(ValkeyClientError) -> Int {
        try await execute(ZINTERSTORE(destination: destination, keys: keys, weights: weights, aggregate: aggregate))
    }

    /// Returns the union of multiple sorted sets.
    ///
    /// - Documentation: [ZUNION](https://valkey.io/commands/zunion)
    /// - Available: 6.2.0
    /// - Complexity: O(N)+O(M*log(M)) with N being the sum of the sizes of the input sorted sets, and M being the number of elements in the resulting sorted set.
    /// - Returns: One of the following
    ///     * The result of union when 'WITHSCORES' is not used.
    ///     * The result of union when 'WITHSCORES' is used.
    @inlinable
    @_disfavoredOverload
    public func zunion(
        keys: [ValkeyKey],
        weights: [Int] = [],
        aggregate: ZUNION.Aggregate? = nil,
        withscores: Bool = false
    ) async throws(ValkeyClientError) -> RESPToken.Array {
        try await execute(ZUNION(keys: keys, weights: weights, aggregate: aggregate, withscores: withscores))
    }

    /// Stores the union of multiple sorted sets in a key.
    ///
    /// - Documentation: [ZUNIONSTORE](https://valkey.io/commands/zunionstore)
    /// - Available: 2.0.0
    /// - Complexity: O(N)+O(M log(M)) with N being the sum of the sizes of the input sorted sets, and M being the number of elements in the resulting sorted set.
    /// - Returns: The number of elements in the resulting sorted set.
    @inlinable
    @discardableResult
    @_disfavoredOverload
    public func zunionstore(
        destination: ValkeyKey,
        keys: [ValkeyKey],
        weights: [Int] = [],
        aggregate: ZUNIONSTORE.Aggregate? = nil
    ) async throws(ValkeyClientError) -> Int {
        try await execute(ZUNIONSTORE(destination: destination, keys: keys, weights: weights, aggregate: aggregate))
    }
}
