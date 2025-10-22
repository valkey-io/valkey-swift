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
