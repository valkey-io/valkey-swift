//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey open source project
//
// Copyright (c) 2025 Apple Inc. and the swift-valkey project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-valkey project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore

public struct RESPCommandEncoder {
    @usableFromInline
    var buffer: ByteBuffer

    @inlinable
    package init() {
        self.buffer = .init()
    }

    @inlinable
    mutating func encodeIdentifier(_ identifier: RESPTypeIdentifier) {
        self.buffer.writeInteger(identifier.rawValue)
    }

    @inlinable
    mutating func encodeBulkString(_ string: String) {
        encodeIdentifier(.bulkString)

        buffer.writeString(String(string.utf8.count))
        buffer.writeStaticString("\r\n")
        buffer.writeString(string)
        buffer.writeStaticString("\r\n")
    }

    @inlinable
    var writerIndex: Int {
        buffer.writerIndex
    }

    @inlinable
    mutating func moveWriterIndex(to index: Int) {
        buffer.moveWriterIndex(to: index)
    }

    @inlinable
    package mutating func reset() {
        self.buffer.clear()
    }
}
