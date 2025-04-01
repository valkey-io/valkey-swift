//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-redis open source project
//
// Copyright (c) 2025 the swift-redis project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-redis project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore

/// Type that can be rendered into a RESP buffer
public protocol RESPRenderable {
    func encode(into commandEncoder: inout RedisCommandEncoder) -> Int
}

extension Optional: RESPRenderable where Wrapped: RESPRenderable {
    @inlinable
    public func encode(into commandEncoder: inout RedisCommandEncoder) -> Int {
        switch self {
        case .some(let wrapped):
            return wrapped.encode(into: &commandEncoder)
        case .none:
            return 0
        }
    }
}

extension Array: RESPRenderable where Element: RESPRenderable {
    @inlinable
    public func encode(into commandEncoder: inout RedisCommandEncoder) -> Int {
        var count = 0
        for element in self {
            count += element.encode(into: &commandEncoder)
        }
        return count
    }
}

extension String: RESPRenderable {
    @inlinable
    public func encode(into commandEncoder: inout RedisCommandEncoder) -> Int {
        commandEncoder.encodeBulkString(self)
        return 1
    }
}

extension Int: RESPRenderable {
    @inlinable
    public func encode(into commandEncoder: inout RedisCommandEncoder) -> Int {
        commandEncoder.encodeBulkString(String(self))
        return 1
    }
}

extension Double: RESPRenderable {
    @inlinable
    public func encode(into commandEncoder: inout RedisCommandEncoder) -> Int {
        commandEncoder.encodeBulkString(String(self))
        return 1
    }
}
