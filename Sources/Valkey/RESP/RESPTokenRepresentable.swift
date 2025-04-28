//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey open source project
//
// Copyright (c) 2025 Apple Inc. and the swift-valkey project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-valkey project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore

/// Type that can represented by a RESP3Token
public protocol RESPTokenRepresentable {
    init(from: RESPToken) throws
}

extension RESPToken: RESPTokenRepresentable {
    /// Convert RESP3Token to a value
    /// - Parameter type: Type to convert to
    /// - Throws: ValkeyClientError.unexpectedType
    /// - Returns: Value
    @inlinable
    public func decode<Value: RESPTokenRepresentable>(as type: Value.Type = Value.self) throws -> Value {
        try Value(from: self)
    }

    @inlinable
    public init(from token: RESPToken) throws {
        self = token
    }

    /// Convert RESP3Token Array to a tuple of values
    /// - Parameter as: Tuple of types to convert to
    /// - Throws: RESPDecodeError
    /// - Returns: Tuple of decoded values
    @inlinable
    public func decodeArrayElements<each Value: RESPTokenRepresentable>(
        as: (repeat (each Value)).Type = (repeat (each Value)).self
    ) throws -> (repeat each Value) {
        switch self.value {
        case .array(let array):
            try array.decodeElements()
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: self.base)
        }
    }
}

extension Array where Element == RESPToken {
    /// Convert RESP3Token Array to a value array
    /// - Parameter type: Type to convert to
    /// - Throws: ValkeyClientError.unexpectedType
    /// - Returns: Array of Value
    @inlinable
    public func decode<Value: RESPTokenRepresentable>(as type: [Value].Type = [Value].self) throws -> [Value] {
        try self.map { try $0.decode() }
    }
}

extension ByteBuffer: RESPTokenRepresentable {
    @inlinable
    public init(from token: RESPToken) throws {
        switch token.value {
        case .simpleString(let buffer),
             .bulkString(let buffer),
             .verbatimString(let buffer),
             .bigNumber(let buffer),
             .simpleError(let buffer),
             .blobError(let buffer):
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

extension String: RESPTokenRepresentable {
    @inlinable
    public init(from token: RESPToken) throws {
        switch token.value {
        case .simpleString(let buffer),
             .bulkString(let buffer),
             .verbatimString(let buffer),
             .bigNumber(let buffer),
             .simpleError(let buffer),
             .blobError(let buffer):
            let buffer = try ByteBuffer(from: token)
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

extension Int64: RESPTokenRepresentable {
    public init(from token: RESPToken) throws {
        switch token.value {
        case .number(let value):
            self = value

        case .bulkString,
             .simpleString,
             .blobError,
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

extension Int: RESPTokenRepresentable {
    @inlinable
    public init(from token: RESPToken) throws {
        switch token.value {
        case .number(let value):
            guard let value = Int(exactly: value) else {
                throw RESPParsingError(code: .unexpectedType, buffer: token.base)
            }
            self = value

        case .bulkString,
             .simpleString,
             .blobError,
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

extension Double: RESPTokenRepresentable {
    @inlinable
    public init(from token: RESPToken) throws {
        switch token.value {
        case .double(let value):
            self = value
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
}

extension Bool: RESPTokenRepresentable {
    @inlinable
    public init(from token: RESPToken) throws {
        switch token.value {
        case .boolean(let value):
            self = value
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
}

extension Optional: RESPTokenRepresentable where Wrapped: RESPTokenRepresentable {
    @inlinable
    public init(from token: RESPToken) throws {
        switch token.value {
        case .null:
            self = nil
        default:
            self = try Wrapped(from: token)
        }
    }
}

extension Array: RESPTokenRepresentable where Element: RESPTokenRepresentable {
    @inlinable
    public init(from token: RESPToken) throws {
        switch token.value {
        case .array(let respArray), .push(let respArray):
            var array: [Element] = []
            for respElement in respArray {
                let element = try Element(from: respElement)
                array.append(element)
            }
            self = array
        default:
            let value = try Element(from: token)
            self = [value]
        }
    }
}

extension Set: RESPTokenRepresentable where Element: RESPTokenRepresentable {
    @inlinable
    public init(from token: RESPToken) throws {
        switch token.value {
        case .set(let respSet):
            var set: Set<Element> = .init()
            for respElement in respSet {
                let element = try Element(from: respElement)
                set.insert(element)
            }
            self = set
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
}

extension Dictionary: RESPTokenRepresentable where Value: RESPTokenRepresentable, Key: RESPTokenRepresentable {
    @inlinable
    public init(from token: RESPToken) throws {
        switch token.value {
        case .map(let respMap), .attribute(let respMap):
            var array: [(Key, Value)] = []
            for respElement in respMap {
                let key = try Key(from: respElement.key)
                let value = try Value(from: respElement.value)
                array.append((key, value))
            }
            self = .init(array) { first, _ in first }
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
}

extension ClosedRange: RESPTokenRepresentable where Bound: RESPTokenRepresentable {
    public init(from token: RESPToken) throws {
        let (min, max) = try token.decodeArrayElements(as: (Bound, Bound).self)
        self = min...max
    }
}

extension RESPToken.Array: RESPTokenRepresentable {
    @inlinable
    public init(from token: RESPToken) throws {
        switch token.value {
        case .array(let respArray), .push(let respArray):
            self = respArray
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }

    /// Convert RESP3Token Array to a value array
    /// - Parameter type: Type to convert to
    /// - Throws: ValkeyClientError.unexpectedType
    /// - Returns: Array of Value
    @inlinable
    public func decode<Value: RESPTokenRepresentable>(as type: [Value].Type = [Value].self) throws -> [Value] {
        try self.map { try $0.decode() }
    }

    /// Convert RESP3Token Array to a tuple of values
    /// - Parameter as: Tuple of types to convert to
    /// - Throws: RESPDecodeError
    /// - Returns: Tuple of decoded values
    @inlinable
    public func decodeElements<each Value: RESPTokenRepresentable>(
        as: (repeat (each Value)).Type = (repeat (each Value)).self
    ) throws -> (repeat each Value) {
        func decodeOptionalRESPToken<T: RESPTokenRepresentable>(_ token: RESPToken?, as: T.Type) throws -> T {
            switch token {
            case .some(let value):
                return try T(from: value)
            case .none:
                // TODO: Fixup error when we have a decoding error
                throw RESPParsingError(code: .unexpectedType, buffer: token?.base ?? .init())
            }
        }
        var iterator = self.makeIterator()
        return try (repeat decodeOptionalRESPToken(iterator.next(), as: (each Value).self))
    }
}

extension RESPToken.Map: RESPTokenRepresentable {
    @inlinable
    public init(from token: RESPToken) throws {
        switch token.value {
        case .map(let respArray):
            self = respArray
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }

    /// Convert RESP3Token Map to a Dictionary with String keys
    /// - Parameter type: Type to convert to
    /// - Throws: ValkeyClientError.unexpectedType
    /// - Returns: String value dictionary
    @inlinable
    public func decode<Value: RESPTokenRepresentable>(as type: [String: Value].Type = [String: Value].self) throws -> [String: Value] {
        var array: [(String, Value)] = []
        for respElement in self {
            let key = try String(from: respElement.key)
            let value = try Value(from: respElement.value)
            array.append((key, value))
        }
        return .init(array) { first, _ in first }
    }
}
