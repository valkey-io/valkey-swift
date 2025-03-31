//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-redis open source project
//
// Copyright (c) 2025 Apple Inc. and the swift-redis project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-redis project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore

@usableFromInline
package struct RedisPureToken: RESPRenderable {
    @usableFromInline
    let token: String?
    @inlinable
    package init(_ token: String, _ value: Bool) {
        if value {
            self.token = token
        } else {
            self.token = nil
        }
    }
    @inlinable
    package func encode(into commandEncoder: inout RedisCommandEncoder) -> Int {
        self.token.encode(into: &commandEncoder)
    }
}

@usableFromInline
package struct RESPWithToken<Value: RESPRenderable>: RESPRenderable {
    @usableFromInline
    let value: Value?
    @usableFromInline
    let token: String

    @inlinable
    package init(_ token: String, _ value: Value?) {
        self.value = value
        self.token = token
    }
    @inlinable
    package func encode(into commandEncoder: inout RedisCommandEncoder) -> Int {
        if let value {
            let writerIndex = commandEncoder.writerIndex
            _ = self.token.encode(into: &commandEncoder)
            let count = value.encode(into: &commandEncoder)
            if count == 0 {
                commandEncoder.moveWriterIndex(to: writerIndex)
                return 0
            }
            return count + 1
        } else {
            return 0
        }
    }
}

@usableFromInline
package struct RESPArrayWithCount<Element: RESPRenderable>: RESPRenderable {
    @usableFromInline
    let array: [Element]

    @inlinable
    package init(_ array: [Element]) {
        self.array = array
    }
    @inlinable
    package func encode(into commandEncoder: inout RedisCommandEncoder) -> Int {
        _ = array.count.encode(into: &commandEncoder)
        let count = array.encode(into: &commandEncoder)
        return count + 1
    }
}
