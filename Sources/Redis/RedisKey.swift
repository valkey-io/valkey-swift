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
import RESP

/// Type representing a RedisKey
public struct RedisKey: RawRepresentable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension RedisKey: RESPTokenRepresentable {
    public init(from token: RESPToken) throws {
        switch token.value {
        case .simpleString(let buffer), .blobString(let buffer):
            self.rawValue = String(buffer: buffer)
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
}

extension RedisKey: CustomStringConvertible {
    public var description: String { rawValue.description }
}

extension RedisKey: RESPRenderable {
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
        self.rawValue.writeToRESPBuffer(&buffer)
    }
}
