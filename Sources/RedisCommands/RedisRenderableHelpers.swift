//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-redis open source project
//
// Copyright (c) 2023 the swift-redis project authors
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

public struct RedisPureToken: RESPRenderable {
    @usableFromInline
    let token: String?
    @inlinable
    public init(_ token: String, _ value: Bool) {
        if value {
            self.token = token
        } else {
            self.token = nil
        }
    }
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
        self.token.writeToRESPBuffer(&buffer)
    }
}

public struct RESPWithToken<Value: RESPRenderable>: RESPRenderable {
    @usableFromInline
    let value: Value?
    @usableFromInline
    let token: String

    @inlinable
    public init(_ token: String, _ value: Value?) {
        self.value = value
        self.token = token
    }
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
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

public struct RESPArrayWithCount<Element: RESPRenderable>: RESPRenderable {
    @usableFromInline
    let array: [Element]

    @inlinable
    public init(_ array: [Element]) {
        self.array = array
    }
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
        _ = array.count.writeToRESPBuffer(&buffer)
        let count = array.writeToRESPBuffer(&buffer)
        return count + 1
    }
}
