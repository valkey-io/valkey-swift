//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import NIOCore

/// List entry
@_documentation(visibility: internal)
public struct ListEntry: RESPTokenDecodable, Sendable {
    public let key: ValkeyKey
    public let value: ByteBuffer

    public init(fromRESP token: RESPToken) throws {
        (self.key, self.value) = try token.decodeArrayElements()
    }
}

extension LMOVE {
    public typealias Response = ByteBuffer?
}

extension LMPOP {
    /// - Returns: One of the following
    ///     * [Null]: If no element could be popped.
    ///     * [Array]: List key from which elements were popped.
    public struct OptionalResponse: RESPTokenDecodable, Sendable {
        public let key: ValkeyKey
        public let values: RESPToken.Array

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

/// Custom response type for LPOP and RPOP commands
/// Handles the different return types based on whether count parameter is provided
@_documentation(visibility: internal)
public struct ListPopResponse: RESPTokenDecodable, Sendable, Hashable {
    /// Single element when count was not provided, nil when key doesn't exist or when multiple elements
    private let _element: ByteBuffer?
    /// Multiple elements when count was provided, nil when key doesn't exist or single element
    private let _elements: [ByteBuffer]?

    /// Returns true if no elements were returned (key doesn't exist)
    public var isEmpty: Bool {
        _element == nil && _elements == nil
    }

    /// Gets the single element when count was not provided
    /// - Returns: ByteBuffer if a single element was returned, nil otherwise
    public func element() -> ByteBuffer? {
        _element
    }

    /// Gets the multiple elements when count was provided
    /// - Returns: Array of ByteBuffer if multiple elements were returned, nil otherwise
    public func elements() -> [ByteBuffer]? {
        _elements
    }

    public init(fromRESP token: RESPToken) throws {
        switch token.value {
        case .null:
            self._element = nil
            self._elements = nil
        case .bulkString(let buffer):
            self._element = buffer
            self._elements = nil
        case .array(let array):
            self._element = nil
            let decodedElements = try array.decode(as: [ByteBuffer].self)
            self._elements = decodedElements
        default:
            throw RESPDecodeError.tokenMismatch(expected: [.null, .bulkString, .array], token: token)
        }
    }
}
