//
// This source file is part of the valkey-swift project
// Copyright (c) 2025-2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import NIOCore

/// List entry
@_documentation(visibility: internal)
public struct ListEntry: RESPTokenDecodable, Sendable {
    public let key: ValkeyKey
    public let value: RESPBulkString

    public init(_ token: RESPToken) throws(RESPDecodeError) {
        (self.key, self.value) = try token.decodeArrayElements()
    }
}

extension LMOVE {
    public typealias Response = RESPBulkString?
}

extension LMPOP {
    /// - Returns: One of the following
    ///     * [Null]: If no element could be popped.
    ///     * [Array]: List key from which elements were popped.
    public struct OptionalResponse: RESPTokenDecodable, Sendable {
        public let key: ValkeyKey
        public let values: RESPToken.Array

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

extension BLMPOP {
    /// - Returns: One of the following
    ///     * [Null]: If no element could be popped.
    ///     * [Array]: List key from which elements were popped.
    public typealias Response = LMPOP.Response
}

extension BLPOP {
    /// - Response: One of the following
    ///     * [Null]: No element could be popped and timeout expired
    ///     * [Array]: The key from which the element was popped and the value of the popped element
    public typealias Response = ListEntry?
}

extension BRPOP {
    /// - Response: One of the following
    ///     * [Null]: No element could be popped and the timeout expired.
    ///     * [Array]: The key from which the element was popped and the value of the popped element
    public typealias Response = ListEntry?
}
