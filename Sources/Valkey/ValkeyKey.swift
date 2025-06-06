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
public struct ValkeyKey: RawRepresentable, Sendable, Equatable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension ValkeyKey: RESPTokenDecodable {
    public init(fromRESP token: RESPToken) throws {
        switch token.value {
        case .simpleString(let buffer), .bulkString(let buffer):
            self.rawValue = String(buffer: buffer)
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
}

extension ValkeyKey: CustomStringConvertible {
    public var description: String { rawValue.description }
}

extension ValkeyKey: RESPRenderable {

    @inlinable
    public var respEntries: Int { 1 }

    @inlinable
    public func encode(into commandEncoder: inout ValkeyCommandEncoder) {
        self.rawValue.encode(into: &commandEncoder)
    }
}

extension ValkeyKey: ExpressibleByStringLiteral {
    @inlinable
    public init(stringLiteral string: String) {
        self.init(rawValue: string)
    }
}
