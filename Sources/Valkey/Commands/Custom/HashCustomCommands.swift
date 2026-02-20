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
public struct HashEntry: RESPTokenDecodable, Sendable {
    public let field: RESPBulkString
    public let value: RESPBulkString

    init(field: RESPBulkString, value: RESPBulkString) {
        self.field = field
        self.value = value
    }

    public init(_ token: RESPToken) throws(RESPDecodeError) {
        switch token.value {
        case .array(let array):
            (self.field, self.value) = try array.decodeElements()
        default:
            throw RESPDecodeError.tokenMismatch(expected: [.array], token: token)
        }
    }
}

extension HSCAN {
    public struct Response: RESPTokenDecodable, Sendable {
        public struct Members: RESPTokenDecodable, Sendable {
            /// List of members and possibly scores.
            public let elements: RESPToken.Array

            public init(_ token: RESPToken) throws(RESPDecodeError) {
                self.elements = try token.decode(as: RESPToken.Array.self)
            }

            /// if HSCAN was called with the `NOVALUES` parameter use this
            /// function to get an array of fields
            public func withoutValues() throws -> [RESPBulkString] {
                try self.elements.decode(as: [RESPBulkString].self)
            }

            /// if HSCAN was called without the `NOVALUES` parameter use this
            /// function to get an array of fields and values
            public func withValues() throws -> [HashEntry] {
                var array: [HashEntry] = []
                for respElement in try self.elements.asMap() {
                    let field = try RESPBulkString(respElement.key)
                    let value = try RESPBulkString(respElement.value)
                    array.append(.init(field: field, value: value))
                }
                return array
            }
        }
        /// Cursor to use in next call to HSCAN
        public let cursor: Int
        /// Sorted set members
        public let members: Members

        public init(_ token: RESPToken) throws(RESPDecodeError) {
            (self.cursor, self.members) = try token.decodeArrayElements()
        }
    }
}

extension HRANDFIELD {
    public typealias Response = OptionalResponse?

    /// Custom response type for HRANDFIELD command that handles all possible return scenarios
    public struct OptionalResponse: RESPTokenDecodable, Sendable {
        /// The raw RESP token containing the response
        public let token: RESPToken

        public init(_ token: RESPToken) throws(RESPDecodeError) {
            self.token = token
        }

        /// Get single random field when HRANDFIELD was called without COUNT
        /// - Returns: Random field name as RESPBulkString, or nil if key doesn't exist
        /// - Throws: RESPDecodeError if response format is unexpected
        public func singleField() throws -> RESPBulkString? {
            try RESPBulkString?(token)
        }

        /// Get multiple random fields when HRANDFIELD was called with COUNT but without WITHVALUES
        /// - Returns: Array of field names as RESPBulkString, or empty array if key doesn't exist
        /// - Throws: RESPDecodeError if response format is unexpected
        @inlinable
        public func multipleFields() throws -> [RESPBulkString]? {
            try [RESPBulkString]?(token)
        }

        /// Get multiple random field-value pairs when HRANDFIELD was called with COUNT and WITHVALUES
        /// - Returns: Array of HashEntry (field-value pairs), or nil if key doesn't exist
        /// - Throws: RESPDecodeError if response format is unexpected
        public func multipleFieldsWithValues() throws -> [HashEntry]? {
            switch token.value {
            case .null:
                return nil
            case .array(let array):
                guard array.count > 0 else {
                    return []
                }

                // Check first element to determine format
                var iterator = array.makeIterator()
                guard let firstElement = iterator.next() else {
                    return []
                }
                switch firstElement.value {
                case .array:
                    // Array of arrays format - can use HashEntry decode
                    return try [HashEntry]?(token)
                default:
                    // Flat array format
                    return try array.asMap().map {
                        try HashEntry(field: RESPBulkString($0.key), value: RESPBulkString($0.value))
                    }
                }
            default:
                throw RESPDecodeError.tokenMismatch(expected: [.null, .array], token: token)
            }
        }
    }
}
