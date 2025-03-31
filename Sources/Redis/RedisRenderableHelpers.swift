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
import RESP

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
    package func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
        self.token.writeToRESPBuffer(&buffer)
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
    package func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
        if let value {
            let writerIndex = buffer.writerIndex
            _ = self.token.writeToRESPBuffer(&buffer)
            let count = value.writeToRESPBuffer(&buffer)
            if count == 0 {
                buffer.moveWriterIndex(to: writerIndex)
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
    package func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
        _ = array.count.writeToRESPBuffer(&buffer)
        let count = array.writeToRESPBuffer(&buffer)
        return count + 1
    }
}
