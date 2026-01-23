//
// This source file is part of the valkey-swift project
// Copyright (c) 2025-2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore

/// A type that can decode from a response token.
public protocol RESPTokenDecodable {
    /// Initialize from RESPToken
    init(_ token: RESPToken) throws(RESPDecodeError)
}

extension RESPToken: RESPTokenDecodable {
    /// Convert RESPToken to a value
    /// - Parameter type: Type to convert to
    /// - Throws: ValkeyClientError.unexpectedType
    /// - Returns: Value
    @inlinable
    public func decode<Value: RESPTokenDecodable>(as type: Value.Type = Value.self) throws(RESPDecodeError) -> Value {
        try Value(self)
    }

    @inlinable
    public init(_ token: RESPToken) throws(RESPDecodeError) {
        self = token
    }

    /// Decode RESPToken as a tuple of values, if it is an Array
    /// - Parameter as: Tuple of types to convert to
    /// - Throws: RESPDecodeError
    /// - Returns: Tuple of decoded values
    @inlinable
    public func decodeArrayElements<each Value: RESPTokenDecodable>(
        as: (repeat (each Value)).Type = (repeat (each Value)).self
    ) throws(RESPDecodeError) -> (repeat each Value) {
        switch self.value {
        case .array(let array), .set(let array):
            try array.decodeElements()
        default:
            throw RESPDecodeError.tokenMismatch(expected: [.array], token: self)
        }
    }

    /// Decode elements corresponding to dictionary keys in RESPToken if it is either an
    /// array or map
    ///
    /// The number of keys has to be equal to the number of elements in the tuple returned
    ///
    /// - Parameters
    ///   - keys: Array of keys to extract values from map
    ///   - type: Parameter pack of types to convert to
    /// - Throws: RESPDecodeError
    /// - Returns: Parameter pack of decoded values
    @inlinable
    public func decodeMapValues<each Value: RESPTokenDecodable>(
        _ keys: String...,
        as type: (repeat (each Value)).Type = (repeat (each Value)).self
    ) throws(RESPDecodeError) -> (repeat each Value) {
        let map =
            switch self.value {
            case .array(let array):
                try array.asMap()
            case .map(let map):
                map
            default:
                throw RESPDecodeError.tokenMismatch(expected: [.array, .map], token: self)
            }
        return try map.decodeValues(keys)
    }
}

extension ByteBuffer: RESPTokenDecodable {
    @inlinable
    public init(_ token: RESPToken) throws(RESPDecodeError) {
        switch token.value {
        case .simpleString(let buffer),
            .bulkString(let buffer),
            .verbatimString(let buffer),
            .bigNumber(let buffer),
            .simpleError(let buffer),
            .bulkError(let buffer):
            self = buffer

        case .array,
            .number,
            .double,
            .boolean,
            .null,
            .attribute,
            .map,
            .set,
            .push:
            throw RESPDecodeError.tokenMismatch(
                expected: [.simpleString, .bulkString, .verbatimString, .bigNumber, .simpleError, .bulkError],
                token: token
            )
        }
    }
}

extension String: RESPTokenDecodable {
    @inlinable
    public init(_ token: RESPToken) throws(RESPDecodeError) {
        switch token.value {
        case .simpleString(let buffer),
            .bulkString(let buffer),
            .verbatimString(let buffer),
            .bigNumber(let buffer),
            .simpleError(let buffer),
            .bulkError(let buffer):
            self.init(buffer: buffer)

        case .double(let value):
            self = "\(value)"

        case .number(let value):
            self = "\(value)"

        case .boolean(let value):
            self = "\(value)"

        case .array,
            .null,
            .attribute,
            .map,
            .set,
            .push:
            throw RESPDecodeError.tokenMismatch(
                expected: [.simpleString, .bulkString, .verbatimString, .bigNumber, .simpleError, .bulkError, .double, .integer, .boolean],
                token: token
            )
        }
    }
}

extension Int64: RESPTokenDecodable {
    public init(_ token: RESPToken) throws(RESPDecodeError) {
        switch token.value {
        case .number(let value):
            self = value

        case .bulkString(let buffer):
            guard let value = Int64(String(buffer: buffer)) else {
                throw RESPDecodeError(.cannotParseInteger, token: token)
            }
            self = value

        case .simpleString,
            .bulkError,
            .simpleError,
            .verbatimString,
            .double,
            .boolean,
            .array,
            .attribute,
            .bigNumber,
            .push,
            .set,
            .null,
            .map:
            throw RESPDecodeError.tokenMismatch(expected: [.integer, .bulkString], token: token)
        }
    }
}

extension Int: RESPTokenDecodable {
    @inlinable
    public init(_ token: RESPToken) throws(RESPDecodeError) {
        switch token.value {
        case .number(let value):
            guard let value = Int(exactly: value) else {
                throw RESPDecodeError(.cannotParseInteger, token: token)
            }
            self = value

        case .bulkString(let buffer):
            guard let value = Int(String(buffer: buffer)) else {
                throw RESPDecodeError(.cannotParseInteger, token: token)
            }
            self = value

        case .simpleString,
            .bulkError,
            .simpleError,
            .verbatimString,
            .double,
            .boolean,
            .array,
            .attribute,
            .bigNumber,
            .push,
            .set,
            .null,
            .map:
            throw RESPDecodeError.tokenMismatch(expected: [.integer, .bulkString], token: token)
        }
    }
}

extension Double: RESPTokenDecodable {
    @inlinable
    public init(_ token: RESPToken) throws(RESPDecodeError) {
        switch token.value {
        case .double(let value):
            self = value

        case .number(let value):
            guard let double = Double(exactly: value) else {
                throw RESPDecodeError(.cannotParseDouble, token: token)
            }
            self = double

        case .bulkString(let buffer):
            guard let value = Double(String(buffer: buffer)) else {
                throw RESPDecodeError(.cannotParseDouble, token: token)
            }
            self = value

        default:
            throw RESPDecodeError.tokenMismatch(expected: [.double, .integer, .bulkString], token: token)
        }
    }
}

extension Bool: RESPTokenDecodable {
    @inlinable
    public init(_ token: RESPToken) throws(RESPDecodeError) {
        switch token.value {
        case .boolean(let value):
            self = value
        default:
            throw RESPDecodeError.tokenMismatch(expected: [.boolean], token: token)
        }
    }
}

extension Optional: RESPTokenDecodable where Wrapped: RESPTokenDecodable {
    @inlinable
    public init(_ token: RESPToken) throws(RESPDecodeError) {
        switch token.value {
        case .null:
            self = nil
        default:
            self = try Wrapped(token)
        }
    }
}

extension Array: RESPTokenDecodable where Element: RESPTokenDecodable {
    @inlinable
    public init(_ token: RESPToken) throws(RESPDecodeError) {
        self = try .init(token, decodeSingleElementAsArray: true)
    }

    @inlinable
    public init(_ token: RESPToken, decodeSingleElementAsArray: Bool) throws(RESPDecodeError) {
        switch token.value {
        case .array(let respArray), .set(let respArray), .push(let respArray):
            do {
                var array: [Element] = []
                for respElement in respArray {
                    let element = try Element(respElement)
                    array.append(element)
                }
                self = array
            } catch {
                guard decodeSingleElementAsArray else { throw error }
                switch error.errorCode {
                case .tokenMismatch:
                    // if decoding array failed it is possible `Element` is represented by an array and we have a single array
                    // that represents one element of `Element` instead of Array<Element>. We should attempt to decode this as a single element
                    do {
                        let value = try Element(token)
                        self = [value]
                    } catch {
                        throw error
                    }
                default:
                    throw error
                }
            }
        case .null:
            throw RESPDecodeError.tokenMismatch(expected: [.array], token: token)
        default:
            let value = try Element(token)
            self = [value]
        }
    }
}

extension Set: RESPTokenDecodable where Element: RESPTokenDecodable {
    @inlinable
    public init(_ token: RESPToken) throws(RESPDecodeError) {
        switch token.value {
        case .set(let respSet):
            var set: Set<Element> = .init()
            for respElement in respSet {
                let element = try Element(respElement)
                set.insert(element)
            }
            self = set
        case .null:
            throw RESPDecodeError.tokenMismatch(expected: [.set], token: token)
        default:
            let value = try Element(token)
            self = [value]
        }
    }
}

extension Dictionary: RESPTokenDecodable where Value: RESPTokenDecodable, Key: RESPTokenDecodable {
    @inlinable
    public init(_ token: RESPToken) throws(RESPDecodeError) {
        switch token.value {
        case .map(let respMap), .attribute(let respMap):
            self = try respMap.decode(as: Self.self)
        default:
            throw RESPDecodeError.tokenMismatch(expected: [.map], token: token)
        }
    }
}

extension ClosedRange: RESPTokenDecodable where Bound: RESPTokenDecodable {
    public init(_ token: RESPToken) throws(RESPDecodeError) {
        let (min, max) = try token.decodeArrayElements(as: (Bound, Bound).self)
        self = min...max
    }
}

extension RESPToken.Array: RESPTokenDecodable {
    @inlinable
    public init(_ token: RESPToken) throws(RESPDecodeError) {
        switch token.value {
        case .array(let respArray), .set(let respArray), .push(let respArray):
            self = respArray
        default:
            throw RESPDecodeError.tokenMismatch(expected: [.array, .set, .push], token: token)
        }
    }

    /// Convert RESPToken Array to a value array
    /// - Parameter type: Type to convert to
    /// - Throws: ValkeyClientError.unexpectedType
    /// - Returns: Array of Value
    @inlinable
    public func decode<Value: RESPTokenDecodable>(as type: [Value].Type = [Value].self) throws(RESPDecodeError) -> [Value] {
        try self.map { (element) throws(RESPDecodeError) in
            try element.decode()
        }
    }

    /// Convert RESPToken Array to a parameter pack of values
    /// - Parameter type: Parameter pack of types to convert to
    /// - Throws: RESPDecodeError
    /// - Returns: Parameter pack of decoded values
    @inlinable
    public func decodeElements<each Value: RESPTokenDecodable>(
        as type: (repeat (each Value)).Type = (repeat (each Value)).self
    ) throws(RESPDecodeError) -> (repeat each Value) {
        func decodeOptionalRESPToken<T: RESPTokenDecodable>(_ token: RESPToken?, as: T.Type) throws(RESPDecodeError) -> T {
            switch token {
            case .some(let value):
                return try T(value)
            case .none:
                throw RESPDecodeError.invalidArraySize(self, expectedSize: self._parameterPackTypeSize(type))
            }
        }
        var iterator = self.makeIterator()
        return try (repeat decodeOptionalRESPToken(iterator.next(), as: (each Value).self))
    }

    /// Convert RESPToken Array to a parameter pack of `Results`.
    ///
    /// RESP error tokens are converted into Result.failure. This is used by the transaction
    /// code to convert the array response from EXEC into a parameter pack of Results
    ///
    /// - Parameter as: Parameter pack of types to convert to
    /// - Returns: Parameter pack of decoded values as `Results`
    /// - Throws: RESPDecodeError
    @inlinable
    func decodeExecResults<each Value: RESPTokenDecodable>(
        as type: (repeat (each Value)).Type = (repeat (each Value)).self
    ) -> (repeat Result<(each Value), ValkeyClientError>) {
        func decodeOptionalRESPToken<T: RESPTokenDecodable>(_ token: RESPToken?, as: T.Type) -> Result<T, ValkeyClientError> {
            switch token {
            case .some(let value):
                switch value.identifier {
                case .simpleError, .bulkError:
                    return .failure(ValkeyClientError(.commandError, message: value.errorString.map { Swift.String(buffer: $0) }))
                default:
                    do {
                        return try .success(T(value))
                    } catch {
                        return .failure(ValkeyClientError(.respDecodeError, error: error))
                    }
                }
            case .none:
                return .failure(
                    ValkeyClientError(
                        .respDecodeError,
                        error: RESPDecodeError.invalidArraySize(self, expectedSize: self._parameterPackTypeSize(type))
                    )
                )
            }
        }
        var iterator = self.makeIterator()
        return (repeat decodeOptionalRESPToken(iterator.next(), as: (each Value).self))
    }

    /// Decode RESPToken Array consisting of alternating key, value entries
    /// - Parameter as: Array of key value pairs type
    /// - Returns: Array of key value pairs
    @inlinable
    public func decodeKeyValuePairs<Key: RESPTokenDecodable, Value: RESPTokenDecodable>(
        as: [(Key, Value)].Type = [(Key, Value)].self
    ) throws(RESPDecodeError) -> [(Key, Value)] {
        try self.asMap().decode()
    }

    @inlinable
    func _parameterPackTypeSize<each Value>(
        _ type: (repeat (each Value)).Type
    ) -> Int {
        var counter = 0
        func incrementCounter<T>(_ type: T.Type) {
            counter += 1
        }
        repeat incrementCounter((each Value).self)
        return counter
    }
}

extension RESPToken.Map: RESPTokenDecodable {
    @inlinable
    public init(_ token: RESPToken) throws(RESPDecodeError) {
        switch token.value {
        case .map(let respArray):
            self = respArray
        default:
            throw RESPDecodeError.tokenMismatch(expected: [.map, .attribute], token: token)
        }
    }

    /// Convert RESPToken Map to a Dictionary
    /// - Parameter type: Type to convert to
    /// - Throws: ValkeyClientError.unexpectedType
    /// - Returns: String value dictionary
    @inlinable
    public func decode<Key: RESPTokenDecodable & Hashable, Value: RESPTokenDecodable>(
        as type: [Key: Value].Type = [Key: Value].self
    ) throws(RESPDecodeError) -> [Key: Value] {
        let array = try self.decode(as: [(Key, Value)].self)
        return .init(array) { first, _ in first }
    }

    /// Convert RESPToken Map to a Array of Key Value pairs
    /// - Parameter type: Type to convert to
    /// - Throws: ValkeyClientError.unexpectedType
    /// - Returns: String value dictionary
    @inlinable
    public func decode<Key: RESPTokenDecodable, Value: RESPTokenDecodable>(
        as type: [(Key, Value)].Type = [(Key, Value)].self
    ) throws(RESPDecodeError) -> [(Key, Value)] {
        try self.map { (element) throws(RESPDecodeError) in
            try (Key(element.key), Value(element.value))
        }
    }

    /// Convert values from RESPToken Map to a parameter pack of values
    ///
    /// The number of keys has to be equal to the number of elements in the type parameter pack
    ///
    /// - Parameters
    ///   - keys: Array of keys to extract values from map
    ///   - type: Parameter pack of types to convert to
    /// - Throws: RESPDecodeError
    /// - Returns: Parameter pack of decoded values
    @inlinable
    public func decodeValues<each Value: RESPTokenDecodable>(
        _ keys: String...,
        as type: (repeat (each Value)).Type = (repeat (each Value)).self
    ) throws(RESPDecodeError) -> (repeat each Value) {
        try decodeValues(keys)
    }

    @inlinable
    func decodeValues<each Value: RESPTokenDecodable>(
        _ keys: [String],
        as type: (repeat (each Value)).Type = (repeat (each Value)).self
    ) throws(RESPDecodeError) -> (repeat each Value) {
        var encoder = ValkeyCommandEncoder()
        var mapIterator = self.makeIterator()

        func decodeRESPToken<T: RESPTokenDecodable>(named name: String?, map: RESPToken.Map, as: T.Type) throws(RESPDecodeError) -> T {
            guard let name else { preconditionFailure("Invalid number of keys") }
            encoder.reset()
            encoder.encodeBulkString(name)
            var count = keys.count
            while count > 0 {
                var keyValue: (RESPToken, RESPToken)
                // get next element, or if we have hit the end of the list start
                // from the beginning again
                if let next = mapIterator.next() {
                    keyValue = next
                } else {
                    mapIterator = self.makeIterator()
                    keyValue = mapIterator.next()!
                }
                if keyValue.0.base == encoder.buffer {
                    return try T(keyValue.1)
                }
                count -= 1
            }
            do {
                return try T(RESPToken.nullToken)
            } catch {
                throw RESPDecodeError.missingToken(key: name, token: self)
            }
        }
        var keyIterator = keys.makeIterator()
        return try (repeat decodeRESPToken(named: keyIterator.next(), map: self, as: (each Value).self))
    }
}
