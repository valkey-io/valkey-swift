//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 Apple Inc. and the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of valkey-swift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore

/// Type representing a Valkey Key
public struct ValkeyKey: Sendable, Equatable, Hashable {
    @usableFromInline
    enum _Storage: Sendable {
        case string(String)
        case buffer(ByteBuffer)
    }
    @usableFromInline
    let _storage: _Storage

    @inlinable
    public init(_ string: String) {
        self._storage = .string(string)
    }

    @inlinable
    public init(_ buffer: ByteBuffer) {
        self._storage = .buffer(buffer)
    }

    @inlinable
    public var string: String {
        switch self._storage {
        case .string(let string): string
        case .buffer(let buffer): String(buffer: buffer)
        }
    }

    @inlinable
    public var buffer: ByteBuffer {
        switch self._storage {
        case .string(let string): ByteBuffer(string: string)
        case .buffer(let buffer): buffer
        }
    }

    static public func == (_ lhs: Self, _ rhs: Self) -> Bool {
        lhs.buffer == rhs.buffer
    }

    @inlinable
    public func hash(into hasher: inout Hasher) {
        switch self._storage {
        case .string(let string): string.hash(into: &hasher)
        case .buffer(let buffer): buffer.hash(into: &hasher)
        }
    }
}

extension ValkeyKey: RESPTokenDecodable {
    public init(fromRESP token: RESPToken) throws {
        switch token.value {
        case .simpleString(let buffer), .bulkString(let buffer):
            self._storage = .buffer(buffer)
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
}

extension ValkeyKey: CustomStringConvertible {
    public var description: String { self.string }
}

extension ValkeyKey: RESPRenderable {
    @inlinable
    public var respEntries: Int { 1 }

    @inlinable
    public func encode(into commandEncoder: inout ValkeyCommandEncoder) {
        switch self._storage {
        case .string(let string):
            string.encode(into: &commandEncoder)
        case .buffer(let buffer):
            buffer.encode(into: &commandEncoder)
        }
    }
}

extension ValkeyKey: RESPStringRenderable {}

extension ValkeyKey: ExpressibleByStringLiteral {
    @inlinable
    public init(stringLiteral string: String) {
        self.init(string)
    }
}
