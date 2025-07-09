//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore

public struct ValkeyCommandEncoder {
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
    mutating func encodeBulkString(_ string: Substring) {
        encodeIdentifier(.bulkString)

        buffer.writeString(String(string.utf8.count))
        buffer.writeStaticString("\r\n")
        buffer.writeSubstring(string)
        buffer.writeStaticString("\r\n")
    }

    @inlinable
    mutating func encodeBulkString<Bytes: Collection>(_ string: Bytes) where Bytes.Element == UInt8 {
        encodeIdentifier(.bulkString)

        buffer.writeString(String(string.count))
        buffer.writeStaticString("\r\n")
        buffer.writeBytes(string)
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
