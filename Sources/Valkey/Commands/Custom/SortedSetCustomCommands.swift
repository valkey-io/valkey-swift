//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift project
//
// Copyright (c) 2025 the valkey-swift authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See valkey-swift/CONTRIBUTORS.txt for the list of valkey-swift authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Sorted set entry
public struct SortedSetEntry: RESPTokenDecodable, Sendable {
    public let value: RESPToken
    public let score: Double

    public init(fromRESP token: RESPToken) throws {
        switch token.value {
        case .array(let array):
            (self.value, self.score) = try array.decodeElements()
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
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
                throw RESPParsingError(code: .unexpectedType, buffer: token.base)
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
