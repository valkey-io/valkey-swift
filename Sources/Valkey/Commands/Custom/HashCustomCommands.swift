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

// MARK: Backwards compatibility

@available(*, deprecated, message: "Fields has been deprecated in favor of Array<Field>")
@_documentation(visibility: internal)
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
    @available(*, deprecated, message: "Use init with `fields: [Field]` parameter")
    @inlinable public init(_ key: ValkeyKey, seconds: Int, condition: Condition? = nil, fields: Fields) {
        self.key = key
        self.seconds = seconds
        self.condition = condition
        self.fields = fields.fields
    }
}

extension HEXPIREAT {
    @available(*, deprecated, message: "Fields has been deprecated in favor of Array<Field>")
    public typealias Fields = HashFields<Field>
    @inlinable
    @available(*, deprecated, message: "Use init with `fields: [Field]` parameter")
    public init(_ key: ValkeyKey, unixTimeSeconds: Int, condition: Condition? = nil, fields: Fields) {
        self.key = key
        self.unixTimeSeconds = unixTimeSeconds
        self.condition = condition
        self.fields = fields.fields
    }
}

extension HEXPIRETIME {
    @available(*, deprecated, message: "Fields has been deprecated in favor of Array<Field>")
    public typealias Fields = HashFields<Field>
    @inlinable
    @available(*, deprecated, message: "Use init with `fields: [Field]` parameter")
    public init(_ key: ValkeyKey, fields: Fields) {
        self.key = key
        self.fields = fields.fields
    }
}

extension HGETEX {
    @available(*, deprecated, message: "Fields has been deprecated in favor of Array<Field>")
    public typealias Fields = HashFields<Field>
    @inlinable
    @available(*, deprecated, message: "Use init with `fields: [Field]` parameter")
    public init(_ key: ValkeyKey, expiration: Expiration? = nil, fields: Fields) {
        self.key = key
        self.expiration = expiration
        self.fields = fields.fields
    }
}

extension HPERSIST {
    @available(*, deprecated, message: "Fields has been deprecated in favor of Array<Field>")
    public typealias Fields = HashFields<Field>
    @inlinable
    @available(*, deprecated, message: "Use init with `fields: [Field]` parameter")
    public init(_ key: ValkeyKey, fields: Fields) {
        self.key = key
        self.fields = fields.fields
    }
}

extension HPEXPIRE {
    @available(*, deprecated, message: "Fields has been deprecated in favor of Array<Field>")
    public typealias Fields = HashFields<Field>
    @available(*, deprecated, message: "Use init with `fields: [Field]` parameter")
    @inlinable public init(_ key: ValkeyKey, milliseconds: Int, condition: Condition? = nil, fields: Fields) {
        self.key = key
        self.milliseconds = milliseconds
        self.condition = condition
        self.fields = fields.fields
    }
}

extension HPEXPIREAT {
    @available(*, deprecated, message: "Fields has been deprecated in favor of Array<Field>")
    public typealias Fields = HashFields<Field>
    @inlinable
    @available(*, deprecated, message: "Use init with `fields: [Field]` parameter")
    public init(_ key: ValkeyKey, unixTimeMilliseconds: Int, condition: Condition? = nil, fields: Fields) {
        self.key = key
        self.unixTimeMilliseconds = unixTimeMilliseconds
        self.condition = condition
        self.fields = fields.fields
    }
}

extension HPEXPIRETIME {
    @available(*, deprecated, message: "Fields has been deprecated in favor of Array<Field>")
    public typealias Fields = HashFields<Field>
    @inlinable
    @available(*, deprecated, message: "Use init with `fields: [Field]` parameter")
    public init(_ key: ValkeyKey, fields: Fields) {
        self.key = key
        self.fields = fields.fields
    }
}

extension HPTTL {
    @available(*, deprecated, message: "Fields has been deprecated in favor of Array<Field>")
    public typealias Fields = HashFields<Field>
    @inlinable
    @available(*, deprecated, message: "Use init with `fields: [Field]` parameter")
    public init(_ key: ValkeyKey, fields: Fields) {
        self.key = key
        self.fields = fields.fields
    }
}

extension HSETEX {
    public struct Fields: RESPRenderable, Sendable, Hashable {
        public var numfields: Int
        public var data: [FieldsData]

        @inlinable
        public init(numfields: Int, data: [FieldsData]) {
            self.numfields = numfields
            self.data = data
        }

        @inlinable
        public var respEntries: Int {
            numfields.respEntries + data.respEntries
        }

        @inlinable
        public func encode(into commandEncoder: inout ValkeyCommandEncoder) {
            numfields.encode(into: &commandEncoder)
            data.encode(into: &commandEncoder)
        }
    }

    @available(*, deprecated, renamed: "fieldsData")
    var fields: Fields {
        get { .init(numfields: self.fieldsData.count, data: self.fieldsData) }
        set { self.fieldsData = newValue.data }
    }

    @available(*, deprecated, renamed: "hsetex(_:fieldsCondition:expiration:fieldsData:)")
    @inlinable
    public init(_ key: ValkeyKey, fieldsCondition: FieldsCondition? = nil, expiration: Expiration? = nil, fields: Fields) {
        self.key = key
        self.fieldsCondition = fieldsCondition
        self.expiration = expiration
        self.fieldsData = fields.data
    }
}

extension HTTL {
    @available(*, deprecated, message: "Fields has been deprecated in favor of Array<Field>")
    public typealias Fields = HashFields<Field>
    @inlinable
    @available(*, deprecated, message: "Use init with `fields: [Field]` parameter")
    public init(_ key: ValkeyKey, fields: Fields) {
        self.key = key
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
    @available(*, deprecated, message: "Use version with `fields: [Field]` parameter")
    public func hexpire<Field: RESPStringRenderable>(
        _ key: ValkeyKey,
        seconds: Int,
        condition: HEXPIRE<Field>.Condition? = nil,
        fields: HEXPIRE<Field>.Fields
    ) async throws(ValkeyClientError) -> RESPToken.Array {
        try await execute(HEXPIRE(key, seconds: seconds, condition: condition, fields: fields))
    }
    /// Set expiry time on hash fields.
    ///
    /// - Documentation: [HEXPIREAT](https://valkey.io/commands/hexpireat)
    /// - Available: 9.0.0
    /// - Complexity: O(N) where N is the number of specified fields.
    /// - Returns: List of integer codes indicating the result of setting expiry on each specified field, in the same order as the fields are requested.
    @inlinable
    @discardableResult
    @available(*, deprecated, message: "Use version with `fields: [Field]` parameter")
    public func hexpireat<Field: RESPStringRenderable>(
        _ key: ValkeyKey,
        unixTimeSeconds: Int,
        condition: HEXPIREAT<Field>.Condition? = nil,
        fields: HEXPIREAT<Field>.Fields
    ) async throws(ValkeyClientError) -> RESPToken.Array {
        try await execute(HEXPIREAT(key, unixTimeSeconds: unixTimeSeconds, condition: condition, fields: fields))
    }

    /// Returns Unix timestamps in seconds since the epoch at which the given key's field(s) will expire
    ///
    /// - Documentation: [HEXPIRETIME](https://valkey.io/commands/hexpiretime)
    /// - Available: 9.0.0
    /// - Complexity: O(N) where N is the number of specified fields.
    /// - Returns: List of values associated with the result of getting the absolute expiry timestamp of the specific fields, in the same order as they are requested.
    @inlinable
    @available(*, deprecated, message: "Use version with `fields: [Field]` parameter")
    public func hexpiretime<Field: RESPStringRenderable>(
        _ key: ValkeyKey,
        fields: HEXPIRETIME<Field>.Fields
    ) async throws(ValkeyClientError) -> RESPToken.Array {
        try await execute(HEXPIRETIME(key, fields: fields))
    }

    /// Get the value of one or more fields of a given hash key, and optionally set their expiration time or time-to-live (TTL).
    ///
    /// - Documentation: [HGETEX](https://valkey.io/commands/hgetex)
    /// - Available: 9.0.0
    /// - Complexity: O(N) where N is the number of specified fields.
    /// - Returns: List of values associated with the given fields, in the same order as they are requested.
    @inlinable
    @discardableResult
    @available(*, deprecated, message: "Use version with `fields: [Field]` parameter")
    public func hgetex<Field: RESPStringRenderable>(
        _ key: ValkeyKey,
        expiration: HGETEX<Field>.Expiration? = nil,
        fields: HGETEX<Field>.Fields
    ) async throws(ValkeyClientError) -> RESPToken.Array {
        try await execute(HGETEX(key, expiration: expiration, fields: fields))
    }

    /// Remove the existing expiration on a hash key's field(s).
    ///
    /// - Documentation: [HPERSIST](https://valkey.io/commands/hpersist)
    /// - Available: 9.0.0
    /// - Complexity: O(N) where N is the number of specified fields.
    /// - Returns: List of integer codes indicating the result of setting expiry on each specified field, in the same order as the fields are requested.
    @inlinable
    @discardableResult
    @available(*, deprecated, message: "Use version with `fields: [Field]` parameter")
    public func hpersist<Field: RESPStringRenderable>(
        _ key: ValkeyKey,
        fields: HPERSIST<Field>.Fields
    ) async throws(ValkeyClientError) -> RESPToken.Array {
        try await execute(HPERSIST(key, fields: fields))
    }

    /// Set expiry time on hash object.
    ///
    /// - Documentation: [HPEXPIRE](https://valkey.io/commands/hpexpire)
    /// - Available: 9.0.0
    /// - Complexity: O(N) where N is the number of specified fields.
    /// - Returns: List of integer codes indicating the result of setting expiry on each specified field, in the same order as the fields are requested.
    @inlinable
    @discardableResult
    @available(*, deprecated, message: "Use version with `fields: [Field]` parameter")
    public func hpexpire<Field: RESPStringRenderable>(
        _ key: ValkeyKey,
        milliseconds: Int,
        condition: HPEXPIRE<Field>.Condition? = nil,
        fields: HPEXPIRE<Field>.Fields
    ) async throws(ValkeyClientError) -> RESPToken.Array {
        try await execute(HPEXPIRE(key, milliseconds: milliseconds, condition: condition, fields: fields))
    }

    /// Set expiration time on hash field.
    ///
    /// - Documentation: [HPEXPIREAT](https://valkey.io/commands/hpexpireat)
    /// - Available: 9.0.0
    /// - Complexity: O(N) where N is the number of specified fields.
    /// - Returns: List of integer codes indicating the result of setting expiry on each specified field, in the same order as the fields are requested.
    @inlinable
    @discardableResult
    @available(*, deprecated, message: "Use version with `fields: [Field]` parameter")
    public func hpexpireat<Field: RESPStringRenderable>(
        _ key: ValkeyKey,
        unixTimeMilliseconds: Int,
        condition: HPEXPIREAT<Field>.Condition? = nil,
        fields: HPEXPIREAT<Field>.Fields
    ) async throws(ValkeyClientError) -> RESPToken.Array {
        try await execute(HPEXPIREAT(key, unixTimeMilliseconds: unixTimeMilliseconds, condition: condition, fields: fields))
    }

    /// Returns the Unix timestamp in milliseconds since Unix epoch at which the given key's field(s) will expire
    ///
    /// - Documentation: [HPEXPIRETIME](https://valkey.io/commands/hpexpiretime)
    /// - Available: 9.0.0
    /// - Complexity: O(N) where N is the number of specified fields.
    /// - Returns: List of values associated with the result of getting the absolute expiry timestamp of the specific fields, in the same order as they are requested.
    @inlinable
    @available(*, deprecated, message: "Use version with `fields: [Field]` parameter")
    public func hpexpiretime<Field: RESPStringRenderable>(
        _ key: ValkeyKey,
        fields: HPEXPIRETIME<Field>.Fields
    ) async throws(ValkeyClientError) -> RESPToken.Array {
        try await execute(HPEXPIRETIME(key, fields: fields))
    }

    /// Returns the remaining time to live in milliseconds of a hash key's field(s) that have an associated expiration.
    ///
    /// - Documentation: [HPTTL](https://valkey.io/commands/hpttl)
    /// - Available: 9.0.0
    /// - Complexity: O(N) where N is the number of specified fields.
    /// - Returns: List of values associated with the result of getting the remaining time-to-live of the specific fields, in the same order as they are requested.
    @inlinable
    @available(*, deprecated, message: "Use version with `fields: [Field]` parameter")
    public func hpttl<Field: RESPStringRenderable>(_ key: ValkeyKey, fields: HPTTL<Field>.Fields) async throws(ValkeyClientError) -> RESPToken.Array {
        try await execute(HPTTL(key, fields: fields))
    }

    /// Set the value of one or more fields of a given hash key, and optionally set their expiration time.
    ///
    /// - Documentation: [HSETEX](https://valkey.io/commands/hsetex)
    /// - Available: 9.0.0
    /// - Complexity: O(N) where N is the number of specified fields.
    /// - Returns: One of the following
    ///     * 0: None of the provided fields value and or expiration time was set.
    ///     * 1: All the fields value and or expiration time was set.
    @inlinable
    @discardableResult
    @available(*, deprecated, renamed: "hsetex(_:fieldsCondition:expiration:fieldsData:)")
    public func hsetex<Field: RESPStringRenderable, Value: RESPStringRenderable>(
        _ key: ValkeyKey,
        fieldsCondition: HSETEX<Field, Value>.FieldsCondition? = nil,
        expiration: HSETEX<Field, Value>.Expiration? = nil,
        fields: HSETEX<Field, Value>.Fields
    ) async throws(ValkeyClientError) -> Int {
        try await execute(HSETEX(key, fieldsCondition: fieldsCondition, expiration: expiration, fields: fields))
    }

    /// Returns the remaining time to live (in seconds) of a hash key's field(s) that have an associated expiration.
    ///
    /// - Documentation: [HTTL](https://valkey.io/commands/httl)
    /// - Available: 9.0.0
    /// - Complexity: O(N) where N is the number of specified fields.
    /// - Returns: List of values associated with the result of getting the remaining time-to-live of the specific fields, in the same order as they are requested.
    @inlinable
    @available(*, deprecated, message: "Use version with `fields: [Field]` parameter")
    public func httl<Field: RESPStringRenderable>(_ key: ValkeyKey, fields: HTTL<Field>.Fields) async throws(ValkeyClientError) -> RESPToken.Array {
        try await execute(HTTL(key, fields: fields))
    }
}
