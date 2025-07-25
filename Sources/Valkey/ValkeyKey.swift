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

/// A type that represnts a Valkey Key.
public struct ValkeyKey: Sendable, Equatable, Hashable {
    @usableFromInline
    enum _Storage: Sendable {
        case string(String)
        case buffer(ByteBuffer)
    }
    @usableFromInline
    let _storage: _Storage

    /// Initialize ValkeyKey with String
    /// - Parameter string: string
    @inlinable
    public init(_ string: String) {
        self._storage = .string(string)
    }

    /// Initialize ValkeyKey with ByteBuffer
    /// - Parameter buffer: ByteBuffer
    @inlinable
    public init(_ buffer: ByteBuffer) {
        self._storage = .buffer(buffer)
    }

    @inlinable
    static public func == (_ lhs: Self, _ rhs: Self) -> Bool {
        switch (lhs._storage, rhs._storage) {
        case (.string(let lhs), .string(let rhs)):
            lhs == rhs
        case (.buffer(let lhs), .buffer(let rhs)):
            lhs == rhs
        case (.string(let lhs), .buffer(let rhs)):
            lhs.utf8.elementsEqual(rhs.readableBytesView)
        case (.buffer(let lhs), .string(let rhs)):
            rhs.utf8.elementsEqual(lhs.readableBytesView)
        }
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
    @inlinable
    public init(fromRESP token: RESPToken) throws {
        switch token.value {
        case .simpleString(let buffer), .bulkString(let buffer):
            self._storage = .buffer(buffer)
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
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

extension ValkeyKey: CustomStringConvertible {
    public var description: String {
        switch self._storage {
        case .string(let string): string
        case .buffer(let buffer): String(buffer: buffer)
        }
    }
}

extension ValkeyKey: ExpressibleByStringLiteral {
    @inlinable
    public init(stringLiteral string: String) {
        self.init(string)
    }
}

extension String {
    ///  Initialize String from ValkeyKey
    /// - Parameter valkeyKey: key
    @inlinable
    public init(valkeyKey: ValkeyKey) {
        switch valkeyKey._storage {
        case .string(let string): self = string
        case .buffer(let buffer): self = String(buffer: buffer)
        }
    }
}

extension ByteBuffer {
    ///  Initialize ByteBuffer from ValkeyKey
    /// - Parameter valkeyKey: key
    @inlinable
    public init(valkeyKey: ValkeyKey) {
        switch valkeyKey._storage {
        case .string(let string): self = ByteBuffer(string: string)
        case .buffer(let buffer): self = buffer
        }
    }
}
