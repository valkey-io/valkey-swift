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
public struct HashEntry: RESPTokenDecodable, Sendable {
    public let field: RESPBulkString
    public let value: RESPBulkString

    init(field: RESPBulkString, value: RESPBulkString) {
        self.field = field
        self.value = value
    }

    public init(fromRESP token: RESPToken) throws {
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

            public init(fromRESP token: RESPToken) throws {
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
                    let field = try RESPBulkString(fromRESP: respElement.key)
                    let value = try RESPBulkString(fromRESP: respElement.value)
                    array.append(.init(field: field, value: value))
                }
                return array
            }
        }
        /// Cursor to use in next call to HSCAN
        public let cursor: Int
        /// Sorted set members
        public let members: Members

        public init(fromRESP token: RESPToken) throws {
            (self.cursor, self.members) = try token.decodeArrayElements()
        }
    }
}

extension HRANDFIELD {
    /// Custom response type for HRANDFIELD command that handles all possible return scenarios
    public struct Response: RESPTokenDecodable, Sendable {
        /// The raw RESP token containing the response
        public let token: RESPToken

        public init(fromRESP token: RESPToken) throws {
            self.token = token
        }

        /// Get single random field when HRANDFIELD was called without COUNT
        /// - Returns: Random field name as RESPBulkString, or nil if key doesn't exist
        /// - Throws: RESPDecodeError if response format is unexpected
        public func singleField() throws -> RESPBulkString? {
            // Handle .null as it is expected when the key doesn't exist
            if token.value == .null {
                return nil
            }
            return try RESPBulkString(fromRESP: token)
        }

        /// Get multiple random fields when HRANDFIELD was called with COUNT but without WITHVALUES
        /// - Returns: Array of field names as RESPBulkString, or empty array if key doesn't exist
        /// - Throws: RESPDecodeError if response format is unexpected
        @inlinable
        public func multipleFields() throws -> [RESPBulkString]? {
            try [RESPBulkString]?(fromRESP: token)
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
                    return try [HashEntry]?(fromRESP: token)
                default:
                    // Flat array format - handle manually
                    return try _decodeFlatArrayFormat(array)
                }
            default:
                throw RESPDecodeError.tokenMismatch(expected: [.null, .array], token: token)
            }
        }

        /// Helper method to decode flat array format
        /// - Parameter array: RESP array containing alternating field-value pairs
        /// - Returns: Array of HashEntry objects
        /// - Throws: RESPDecodeError if format is invalid
        private func _decodeFlatArrayFormat(_ array: RESPToken.Array) throws -> [HashEntry] {
            guard array.count % 2 == 0 else {
                throw RESPDecodeError(.invalidArraySize, token: token)
            }

            var entries: [HashEntry] = []
            entries.reserveCapacity(array.count / 2)

            // Iterate over pairs
            var iterator = array.makeIterator()
            while let field = iterator.next(), let value = iterator.next() {
                let fieldBuffer = try RESPBulkString(fromRESP: field)
                let valueBuffer = try RESPBulkString(fromRESP: value)
                entries.append(HashEntry(field: fieldBuffer, value: valueBuffer))
            }

            return entries
        }
    }
}
