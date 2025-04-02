//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey open source project
//
// Copyright (c) 2025 the swift-valkey project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-valkey project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore

/// Type representing a RESPKey
public struct RESPKey: RawRepresentable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension RESPKey: RESPTokenRepresentable {
    public init(from token: RESPToken) throws {
        switch token.value {
        case .simpleString(let buffer), .bulkString(let buffer):
            self.rawValue = String(buffer: buffer)
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
}

extension RESPKey: CustomStringConvertible {
    public var description: String { rawValue.description }
}

extension RESPKey: RESPRenderable {
    @inlinable
    public func encode(into commandEncoder: inout RESPCommandEncoder) -> Int {
        self.rawValue.encode(into: &commandEncoder)
    }
}

extension RESPKey: ExpressibleByStringLiteral {
    @inlinable
    public init(stringLiteral string: String) {
        self.init(rawValue: string)
    }
}
