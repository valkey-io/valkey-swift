//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-redis open source project
//
// Copyright (c) 2023 Apple Inc. and the swift-redis project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-redis project authors
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
    /// - Throws: RedisClientError.unexpectedType
    /// - Returns: Value
    public func converting<Value: RESPTokenRepresentable>(to type: Value.Type = Value.self) throws -> Value {
        try Value(from: self)
    }

    public init(from token: RESPToken) throws {
        self = token
    }
}

extension Array where Element == RESPToken {
    /// Convert RESP3Token Array to a value array
    /// - Parameter type: Type to convert to
    /// - Throws: RedisClientError.unexpectedType
    /// - Returns: Array of Value
    public func converting<Value: RESPTokenRepresentable>(to type: [Value].Type = [Value].self) throws -> [Value] {
        try self.map { try $0.converting() }
    }
}

extension ByteBuffer: RESPTokenRepresentable {
    public init(from token: RESPToken) throws {
        switch token.value {
        case .simpleString(let buffer), .bulkString(let buffer), .verbatimString(let buffer), .bigNumber(let buffer):
            self = buffer
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
}

extension String: RESPTokenRepresentable {
    public init(from token: RESPToken) throws {
        let buffer = try ByteBuffer(from: token)
        self.init(buffer: buffer)
    }
}

extension Int: RESPTokenRepresentable {
    public init(from token: RESPToken) throws {
        switch token.value {
        case .number(let value):
            self = numericCast(value)
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
}

extension Double: RESPTokenRepresentable {
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
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
}

extension Set: RESPTokenRepresentable where Element: RESPTokenRepresentable {
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
