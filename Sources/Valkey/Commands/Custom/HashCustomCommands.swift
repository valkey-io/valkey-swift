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
    public struct Response: RESPTokenDecodable, Sendable {
        /// The raw RESP token containing the response
        public let token: RESPToken

        public init(fromRESP token: RESPToken) throws {
            self.token = token
        }

        /// Get single random field when HRANDFIELD was called without COUNT
        /// - Returns: Random field name as ByteBuffer, or nil if key doesn't exist
        /// - Throws: RESPDecodeError if response format is unexpected
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
                // RESP2 Response
                return try _decodeArrayAsHashEntries(array)
            case .map(let map):
                // RESP3 Response
                return try _decodeMapAsHashEntries(map)
            default:
                throw RESPDecodeError.tokenMismatch(expected: [.null, .array, .map], token: token)
            }
        }

        /// Helper method to decode RESP array as hash entries
        /// - Parameter array: RESP array to decode
        /// - Returns: Array of HashEntry objects
        /// - Throws: RESPDecodeError if format is invalid
        private func _decodeArrayAsHashEntries(_ array: RESPToken.Array) throws -> [HashEntry] {
            guard array.count > 0 else {
                return []
            }

            // Get first element to determine format using iterator
            var iterator = array.makeIterator()
            guard let firstElement = iterator.next() else {
                return []
            }

            switch firstElement.value {
            case .array:
                // Format: [[field1, value1], [field2, value2], ...]
                return try _decodeNestedArrayFormat(array)
            default:
                // Format: [field1, value1, field2, value2, ...] (flat array)
                return try _decodeFlatArrayFormat(array)
            }
        }

        /// Helper method to decode nested array format
        /// - Parameter array: RESP array containing nested arrays
        /// - Returns: Array of HashEntry objects
        /// - Throws: RESPDecodeError if format is invalid
        private func _decodeNestedArrayFormat(_ array: RESPToken.Array) throws -> [HashEntry] {
            var entries: [HashEntry] = []
            entries.reserveCapacity(array.count)

            for element in array {
                guard case .array(let pairArray) = element.value else {
                    throw RESPDecodeError.tokenMismatch(expected: [.array], token: element)
                }

                guard pairArray.count == 2 else {
                    throw RESPDecodeError(.invalidArraySize, token: element)
                }

                // Use decodeElements to extract field and value directly from nested array
                let (field, value): (ByteBuffer, ByteBuffer) = try pairArray.decodeElements()
                entries.append(HashEntry(field: field, value: value))
            }

            return entries
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

            // Iterate over pairs directly using enumerated
            var iterator = array.makeIterator()
            while let field = iterator.next(), let value = iterator.next() {
                let fieldBuffer = try ByteBuffer(fromRESP: field)
                let valueBuffer = try ByteBuffer(fromRESP: value)
                entries.append(HashEntry(field: fieldBuffer, value: valueBuffer))
            }

            return entries
        }

        /// Helper method to decode RESP map as hash entries
        /// - Parameter map: RESP map to decode
        /// - Returns: Array of HashEntry objects
        /// - Throws: RESPDecodeError if format is invalid
        private func _decodeMapAsHashEntries(_ map: RESPToken.Map) throws -> [HashEntry] {
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
