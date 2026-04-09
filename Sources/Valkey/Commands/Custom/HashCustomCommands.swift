//
// This source file is part of the valkey-swift project
// Copyright (c) 2025-2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore

// MARK: Custom responses

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

// MARK: Additional API

extension HEXPIRETIME.Fields: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Field...) {
        self.numfields = elements.count
        self.fields = elements
    }
}

extension HGETEX.Fields: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Field...) {
        self.numfields = elements.count
        self.fields = elements
    }
}

extension HPERSIST.Fields: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Field...) {
        self.numfields = elements.count
        self.fields = elements
    }
}

extension HPEXPIRE.Fields: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Field...) {
        self.numfields = elements.count
        self.fields = elements
    }
}

extension HPEXPIREAT.Fields: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Field...) {
        self.numfields = elements.count
        self.fields = elements
    }
}

extension HPEXPIRETIME.Fields: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Field...) {
        self.numfields = elements.count
        self.fields = elements
    }
}

extension HPTTL.Fields: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Field...) {
        self.numfields = elements.count
        self.fields = elements
    }
}

extension HSETEX.Fields: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: HSETEX.FieldsData...) {
        self.numfields = elements.count
        self.data = elements
    }
}

extension HTTL.Fields: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Field...) {
        self.numfields = elements.count
        self.fields = elements
    }
}

// MARK: Backwards compatibility

@available(*, deprecated, message: "Use alternative APIs that take [Field]")
public struct HashFields<Field: RESPStringRenderable>: RESPRenderable, Sendable, Hashable {
    public var numfields: Int
    public var fields: [Field]

    @inlinable
    public init(numfields: Int, fields: [Field]) {
        self.numfields = numfields
        self.fields = fields
    }

    @inlinable
    public var respEntries: Int {
        numfields.respEntries + fields.map { RESPRenderableBulkString($0) }.respEntries
    }

    @inlinable
    public func encode(into commandEncoder: inout ValkeyCommandEncoder) {
        numfields.encode(into: &commandEncoder)
        fields.map { RESPRenderableBulkString($0) }.encode(into: &commandEncoder)
    }
}

extension HEXPIRE {
    @available(*, deprecated, message: "Fields has been deprecated in favor of Array<Field>")
    public typealias Fields = HashFields<Field>
    @available(*, deprecated, message: "Use init with `field: [Field]` parameter")
    @inlinable public init(_ key: ValkeyKey, seconds: Int, condition: Condition? = nil, fields: Fields) {
        self.key = key
        self.seconds = seconds
        self.condition = condition
        self.fields = fields.fields
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyClientProtocol {
    /// Set expiry time on hash fields.
    ///
    /// - Documentation: [HEXPIRE](https://valkey.io/commands/hexpire)
    /// - Available: 9.0.0
    /// - Complexity: O(N) where N is the number of specified fields.
    /// - Returns: List of integer codes indicating the result of setting expiry on each specified field, in the same order as the fields are requested.
    @inlinable
    @discardableResult
    @available(*, deprecated, message: "Use version with `field: [Field]` parameter")
    public func hexpire<Field: RESPStringRenderable>(
        _ key: ValkeyKey,
        seconds: Int,
        condition: HEXPIRE<Field>.Condition? = nil,
        fields: HEXPIRE<Field>.Fields
    ) async throws(ValkeyClientError) -> RESPToken.Array {
        try await execute(HEXPIRE(key, seconds: seconds, condition: condition, fields: fields))
    }
}

extension HEXPIREAT {
    @available(*, deprecated, message: "Fields has been deprecated in favor of Array<Field>")
    public typealias Fields = HashFields<Field>
    @inlinable
    @available(*, deprecated, message: "Use init with `field: [Field]` parameter")
    public init(_ key: ValkeyKey, unixTimeSeconds: Int, condition: Condition? = nil, fields: Fields) {
        self.key = key
        self.unixTimeSeconds = unixTimeSeconds
        self.condition = condition
        self.fields = fields.fields
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyClientProtocol {
    /// Set expiry time on hash fields.
    ///
    /// - Documentation: [HEXPIREAT](https://valkey.io/commands/hexpireat)
    /// - Available: 9.0.0
    /// - Complexity: O(N) where N is the number of specified fields.
    /// - Returns: List of integer codes indicating the result of setting expiry on each specified field, in the same order as the fields are requested.
    @inlinable
    @discardableResult
    @available(*, deprecated, message: "Use version with `field: [Field]` parameter")
    public func hexpireat<Field: RESPStringRenderable>(
        _ key: ValkeyKey,
        unixTimeSeconds: Int,
        condition: HEXPIREAT<Field>.Condition? = nil,
        fields: HEXPIREAT<Field>.Fields
    ) async throws(ValkeyClientError) -> RESPToken.Array {
        try await execute(HEXPIREAT(key, unixTimeSeconds: unixTimeSeconds, condition: condition, fields: fields))
    }
}
