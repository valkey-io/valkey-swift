//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of valkey-swift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore

/// Type that can decoded from a RESPToken
public protocol RESPTokenDecodable {
    init(fromRESP: RESPToken) throws
}

extension RESPToken: RESPTokenDecodable {
    /// Convert RESPToken to a value
    /// - Parameter type: Type to convert to
    /// - Throws: ValkeyClientError.unexpectedType
    /// - Returns: Value
    @inlinable
    public func decode<Value: RESPTokenDecodable>(as type: Value.Type = Value.self) throws -> Value {
        try Value(fromRESP: self)
    }

    /// Convert RESP3Token to a Result containing the type to convert to or any error found while converting
    ///
    /// This function also checks for RESP error types and returns them if found
    ///
    /// - Parameter type: Type to convert to
    /// - Returns: Result containing either the Value or an error
    @usableFromInline
    func decodeResult<Value: RESPTokenDecodable>(as type: Value.Type = Value.self) -> Result<Value, Error> {
        switch self.identifier {
        case .simpleError, .bulkError:
            return .failure(ValkeyClientError(.commandError, message: self.errorString.map { Swift.String(buffer: $0) }))
        default:
            do {
                return try .success(Value(fromRESP: self))
            } catch {
                return .failure(error)
            }
        }
    }

    @inlinable
    public init(fromRESP token: RESPToken) throws {
        self = token
    }

    /// Convert RESPToken Array to a tuple of values
    /// - Parameter as: Tuple of types to convert to
    /// - Throws: RESPDecodeError
    /// - Returns: Tuple of decoded values
    @inlinable
    public func decodeArrayElements<each Value: RESPTokenDecodable>(
        as: (repeat (each Value)).Type = (repeat (each Value)).self
    ) throws -> (repeat each Value) {
        switch self.value {
        case .array(let array), .set(let array):
            try array.decodeElements()
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: self.base)
        }
    }
}

extension Array where Element == RESPToken {
    /// Convert RESPToken Array to a value array
    /// - Parameter type: Type to convert to
    /// - Throws: ValkeyClientError.unexpectedType
    /// - Returns: Array of Value
    @inlinable
    public func decode<Value: RESPTokenDecodable>(as type: [Value].Type = [Value].self) throws -> [Value] {
        try self.map { try $0.decode() }
    }
}

extension ByteBuffer: RESPTokenDecodable {
    @inlinable
    public init(fromRESP token: RESPToken) throws {
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
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
}

extension String: RESPTokenDecodable {
    @inlinable
    public init(fromRESP token: RESPToken) throws {
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
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
}

extension Int64: RESPTokenDecodable {
    public init(fromRESP token: RESPToken) throws {
        switch token.value {
        case .number(let value):
            self = value

        case .bulkString(let buffer):
            guard let value = Int64(String(buffer: buffer)) else {
                throw RESPParsingError(code: .canNotParseInteger, buffer: token.base)
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
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
}

extension Int: RESPTokenDecodable {
    @inlinable
    public init(fromRESP token: RESPToken) throws {
        switch token.value {
        case .number(let value):
            guard let value = Int(exactly: value) else {
                throw RESPParsingError(code: .unexpectedType, buffer: token.base)
            }
            self = value

        case .bulkString(let buffer):
            guard let value = Int(String(buffer: buffer)) else {
                throw RESPParsingError(code: .canNotParseInteger, buffer: token.base)
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
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
}

extension Double: RESPTokenDecodable {
    @inlinable
    public init(fromRESP token: RESPToken) throws {
        switch token.value {
        case .double(let value):
            self = value

        case .number(let value):
            guard let double = Double(exactly: value) else {
                throw RESPParsingError(code: .unexpectedType, buffer: token.base)
            }
            self = double

        case .bulkString(let buffer):
            guard let value = Double(String(buffer: buffer)) else {
                throw RESPParsingError(code: .canNotParseDouble, buffer: token.base)
            }
            self = value

        default:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
}

extension Bool: RESPTokenDecodable {
    @inlinable
    public init(fromRESP token: RESPToken) throws {
        switch token.value {
        case .boolean(let value):
            self = value
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
}

extension Optional: RESPTokenDecodable where Wrapped: RESPTokenDecodable {
    @inlinable
    public init(fromRESP token: RESPToken) throws {
        switch token.value {
        case .null:
            self = nil
        default:
            self = try Wrapped(fromRESP: token)
        }
    }
}

extension Array: RESPTokenDecodable where Element: RESPTokenDecodable {
    @inlinable
    public init(fromRESP token: RESPToken) throws {
        switch token.value {
        case .array(let respArray), .set(let respArray), .push(let respArray):
            do {
                var array: [Element] = []
                for respElement in respArray {
                    let element = try Element(fromRESP: respElement)
                    array.append(element)
                }
                self = array
            } catch let error as RESPParsingError where error.code == .unexpectedType {
                // if decoding array failed it is possible `Element` is represented by an array and we have a single array
                // that represents one element of `Element` instead of Array<Element>. We should attempt to decode this as a single element
                let value = try Element(fromRESP: token)
                self = [value]
            }
        case .null:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        default:
            let value = try Element(fromRESP: token)
            self = [value]
        }
    }
}

extension Set: RESPTokenDecodable where Element: RESPTokenDecodable {
    @inlinable
    public init(fromRESP token: RESPToken) throws {
        switch token.value {
        case .set(let respSet):
            var set: Set<Element> = .init()
            for respElement in respSet {
                let element = try Element(fromRESP: respElement)
                set.insert(element)
            }
            self = set
        case .null:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        default:
            let value = try Element(fromRESP: token)
            self = [value]
        }
    }
}

extension Dictionary: RESPTokenDecodable where Value: RESPTokenDecodable, Key: RESPTokenDecodable {
    @inlinable
    public init(fromRESP token: RESPToken) throws {
        switch token.value {
        case .map(let respMap), .attribute(let respMap):
            var array: [(Key, Value)] = []
            for respElement in respMap {
                let key = try Key(fromRESP: respElement.key)
                let value = try Value(fromRESP: respElement.value)
                array.append((key, value))
            }
            self = .init(array) { first, _ in first }
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
}

extension ClosedRange: RESPTokenDecodable where Bound: RESPTokenDecodable {
    public init(fromRESP token: RESPToken) throws {
        let (min, max) = try token.decodeArrayElements(as: (Bound, Bound).self)
        self = min...max
    }
}

extension RESPToken.Array: RESPTokenDecodable {
    @inlinable
    public init(fromRESP token: RESPToken) throws {
        switch token.value {
        case .array(let respArray), .set(let respArray), .push(let respArray):
            self = respArray
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }

    /// Convert RESPToken Array to a value array
    /// - Parameter type: Type to convert to
    /// - Throws: ValkeyClientError.unexpectedType
    /// - Returns: Array of Value
    @inlinable
    public func decode<Value: RESPTokenDecodable>(as type: [Value].Type = [Value].self) throws -> [Value] {
        try self.map { try $0.decode() }
    }

    /// Convert RESPToken Array to a tuple of values
    /// - Parameter as: Tuple of types to convert to
    /// - Throws: RESPDecodeError
    /// - Returns: Tuple of decoded values
    @inlinable
    public func decodeElements<each Value: RESPTokenDecodable>(
        as: (repeat (each Value)).Type = (repeat (each Value)).self
    ) throws -> (repeat each Value) {
        func decodeOptionalRESPToken<T: RESPTokenDecodable>(_ token: RESPToken?, as: T.Type) throws -> T {
            switch token {
            case .some(let value):
                return try T(fromRESP: value)
            case .none:
                // TODO: Fixup error when we have a decoding error
                throw RESPParsingError(code: .unexpectedType, buffer: token?.base ?? .init())
            }
        }
        var iterator = self.makeIterator()
        return try (repeat decodeOptionalRESPToken(iterator.next(), as: (each Value).self))
    }

    /// Convert RESP3Token Array to a tuple of values
    /// - Parameter as: Tuple of types to convert to
    /// - Throws: RESPDecodeError
    /// - Returns: Tuple of decoded values
    @inlinable
    public func decodeElementResults<each Value: RESPTokenDecodable>(
        as: (repeat (each Value)).Type = (repeat (each Value)).self
    ) -> (repeat Result<(each Value), Error>) {
        func decodeOptionalRESPToken<T: RESPTokenDecodable>(_ token: RESPToken?, as: T.Type) -> Result<T, Error> {
            switch token {
            case .some(let value):
                return value.decodeResult(as: T.self)
            case .none:
                // TODO: Fixup error when we have a decoding error
                return .failure(RESPParsingError(code: .unexpectedType, buffer: token?.base ?? .init()))
            }
        }
        var iterator = self.makeIterator()
        return (repeat decodeOptionalRESPToken(iterator.next(), as: (each Value).self))
    }
}

extension RESPToken.Map: RESPTokenDecodable {
    @inlinable
    public init(fromRESP token: RESPToken) throws {
        switch token.value {
        case .map(let respArray):
            self = respArray
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }

    /// Convert RESPToken Map to a Dictionary with String keys
    /// - Parameter type: Type to convert to
    /// - Throws: ValkeyClientError.unexpectedType
    /// - Returns: String value dictionary
    @inlinable
    public func decode<Value: RESPTokenDecodable>(as type: [String: Value].Type = [String: Value].self) throws -> [String: Value] {
        var array: [(String, Value)] = []
        for respElement in self {
            let key = try String(fromRESP: respElement.key)
            let value = try Value(fromRESP: respElement.value)
            array.append((key, value))
        }
        return .init(array) { first, _ in first }
    }
}
