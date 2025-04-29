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

/// Sorted set entry
public struct SortedSetEntry: RESPTokenDecodable {
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
    /// - Returns: One of the following:
    ///     * [Null](https:/valkey.io/topics/protocol/#nulls): when no element could be popped.
    ///     * [Array](https:/valkey.io/topics/protocol/#arrays): A two-element array with the first element being the name of the key from which elements were popped, and the second element is an array of the popped elements. Every entry in the elements array is also an array that contains the member and its score.
    public typealias Response = ZMPOP.Response
}
extension BZPOPMAX {
    /// - Returns: One of the following:
    ///     * [Null](https:/valkey.io/topics/protocol/#nulls): when no element could be popped and the _timeout_ expired.
    ///     * [Array](https:/valkey.io/topics/protocol/#arrays): the keyname, popped member, and its score.
    public typealias Response = [SortedSetEntry]?
}

extension BZPOPMIN {
    /// - Returns: One of the following:
    ///     * [Null](https:/valkey.io/topics/protocol/#nulls): when no element could be popped and the _timeout_ expired.
    ///     * [Array](https:/valkey.io/topics/protocol/#arrays): the keyname, popped member, and its score.
    public typealias Response = [SortedSetEntry]?
}

extension ZMPOP {
    /// - Returns: One of the following:
    ///     * [Null](https:/valkey.io/topics/protocol/#nulls): when no element could be popped.
    ///     * [Array](https:/valkey.io/topics/protocol/#arrays): A two-element array with the first element being the name of the key from which elements were popped, and the second element is an array of the popped elements. Every entry in the elements array is also an array that contains the member and its score.
    public struct OptionalResponse: RESPTokenDecodable {
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
    /// - Returns: * [Array](https:/valkey.io/topics/protocol/#arrays): a list of popped elements and scores.
    public typealias Response = [SortedSetEntry]
}

extension ZPOPMIN {
    /// - Returns: * [Array](https:/valkey.io/topics/protocol/#arrays): a list of popped elements and scores.
    public typealias Response = [SortedSetEntry]
}
