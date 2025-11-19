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
    public let field: ByteBuffer
    public let value: ByteBuffer

    init(field: ByteBuffer, value: ByteBuffer) {
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
            public func withoutValues() throws -> [ByteBuffer] {
                try self.elements.decode(as: [ByteBuffer].self)
            }

            /// if HSCAN was called without the `NOVALUES` parameter use this
            /// function to get an array of fields and values
            public func withValues() throws -> [HashEntry] {
                var array: [HashEntry] = []
                for respElement in try self.elements.asMap() {
                    let field = try ByteBuffer(fromRESP: respElement.key)
                    let value = try ByteBuffer(fromRESP: respElement.value)
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
    @_documentation(visibility: internal)
    public struct Response: RESPTokenDecodable, Sendable {
        /// The raw RESP token containing the response
        public let token: RESPToken

        @inlinable
        public init(fromRESP token: RESPToken) throws {
            self.token = token
        }

        /// Get single random field when HRANDFIELD was called without COUNT
        /// - Returns: Random field name as ByteBuffer, or nil if key doesn't exist
        /// - Throws: RESPDecodeError if response format is unexpected
        @inlinable
        public func singleField() throws -> ByteBuffer? {
            switch token.value {
            case .null:
                return nil
            case .bulkString(let buffer):
                return buffer
            default:
                throw RESPDecodeError.tokenMismatch(expected: [.null, .bulkString], token: token)
            }
        }

        /// Get multiple random fields when HRANDFIELD was called with COUNT but without WITHVALUES
        /// - Returns: Array of field names as ByteBuffer, or empty array if key doesn't exist
        /// - Throws: RESPDecodeError if response format is unexpected
        @inlinable
        public func multipleFields() throws -> [ByteBuffer] {
            switch token.value {
            case .null:
                return []
            case .array(let array):
                return try array.decode(as: [ByteBuffer].self)
            default:
                throw RESPDecodeError.tokenMismatch(expected: [.null, .array], token: token)
            }
        }

        /// Get multiple random field-value pairs when HRANDFIELD was called with COUNT and WITHVALUES
        /// - Returns: Array of HashEntry (field-value pairs), or empty array if key doesn't exist
        /// - Throws: RESPDecodeError if response format is unexpected
        public func multipleFieldsWithValues() throws -> [HashEntry] {
            switch token.value {
            case .null:
                return []
            case .array(let array):
                return try _decodeArrayAsHashEntries(array)
            case .map(let map):
                return try _decodeMapAsHashEntries(map)
            default:
                throw RESPDecodeError.tokenMismatch(expected: [.null, .array, .map], token: token)
            }
        }

        /// Helper method to decode RESP array as hash entries
        /// - Parameter array: RESP array to decode
        /// - Returns: Array of HashEntry objects
        /// - Throws: RESPDecodeError if format is invalid
        internal func _decodeArrayAsHashEntries(_ array: RESPToken.Array) throws -> [HashEntry] {
            // Convert to Swift array for easier access
            let elements = Array(array)

            guard !elements.isEmpty else {
                return []
            }

            switch elements[0].value {
            case .array:
                // Format: [[field1, value1], [field2, value2], ...]
                return try _decodeNestedArrayFormat(elements)
            default:
                // Format: [field1, value1, field2, value2, ...] (flat array)
                return try _decodeFlatArrayFormat(elements)
            }
        }

        /// Helper method to decode nested array format
        /// - Parameter elements: Swift array of RESP tokens containing nested arrays
        /// - Returns: Array of HashEntry objects
        /// - Throws: RESPDecodeError if format is invalid
        internal func _decodeNestedArrayFormat(_ elements: [RESPToken]) throws -> [HashEntry] {
            var entries: [HashEntry] = []
            entries.reserveCapacity(elements.count)

            for element in elements {
                guard case .array(let pairArray) = element.value else {
                    throw RESPDecodeError.tokenMismatch(expected: [.array], token: element)
                }

                let pairElements = Array(pairArray)
                guard pairElements.count == 2 else {
                    throw RESPDecodeError(.invalidArraySize, token: element)
                }

                let field = try ByteBuffer(fromRESP: pairElements[0])
                let value = try ByteBuffer(fromRESP: pairElements[1])
                entries.append(HashEntry(field: field, value: value))
            }

            return entries
        }

        /// Helper method to decode flat array format
        /// - Parameter elements: Swift array of RESP tokens containing alternating field-value pairs
        /// - Returns: Array of HashEntry objects
        /// - Throws: RESPDecodeError if format is invalid
        internal func _decodeFlatArrayFormat(_ elements: [RESPToken]) throws -> [HashEntry] {
            guard elements.count % 2 == 0 else {
                throw RESPDecodeError(.invalidArraySize, token: token)
            }

            var entries: [HashEntry] = []
            entries.reserveCapacity(elements.count / 2)

            for i in stride(from: 0, to: elements.count, by: 2) {
                let field = try ByteBuffer(fromRESP: elements[i])
                let value = try ByteBuffer(fromRESP: elements[i + 1])
                entries.append(HashEntry(field: field, value: value))
            }

            return entries
        }

        /// Helper method to decode RESP map as hash entries
        /// - Parameter map: RESP map to decode
        /// - Returns: Array of HashEntry objects
        /// - Throws: RESPDecodeError if format is invalid
        internal func _decodeMapAsHashEntries(_ map: RESPToken.Map) throws -> [HashEntry] {
            var entries: [HashEntry] = []
            entries.reserveCapacity(map.count)

            for pair in map {
                let field = try ByteBuffer(fromRESP: pair.key)
                let value = try ByteBuffer(fromRESP: pair.value)
                entries.append(HashEntry(field: field, value: value))
            }

            return entries
        }

    }
}
