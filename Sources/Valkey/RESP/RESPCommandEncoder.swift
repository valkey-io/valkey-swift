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

public struct RESPCommandEncoder {
    @usableFromInline
    var buffer: ByteBuffer

    @inlinable
    init() {
        self.buffer = .init()
    }

    @inlinable
    mutating func encodeIdentifier(_ identifier: RESPTypeIdentifier) {
        self.buffer.writeInteger(identifier.rawValue)
    }

    @inlinable
    package mutating func encodeArray<each Arg: RESPRenderable>(_ command: repeat each Arg) {
        encodeIdentifier(.array)

        let arrayCountIndex = buffer.writerIndex
        // temporarily write 0 here, we will update this once everything else is written
        buffer.writeString("0")
        buffer.writeStaticString("\r\n")
        var count = 0
        for arg in repeat each command {
            count += arg.encode(into: &self)
        }
        if count > 9 {
            // I'm being lazy here and not supporting more than 99 arguments
            precondition(count < 100)
            // We need to rebuild ByteBuffer with space for double digit count
            // skip past count + \r\n
            let sliceStart = arrayCountIndex + 3
            var slice = buffer.getSlice(at: sliceStart, length: buffer.writerIndex - sliceStart)!
            buffer.moveWriterIndex(to: arrayCountIndex)
            buffer.writeString(String(count))
            buffer.writeStaticString("\r\n")
            buffer.writeBuffer(&slice)
        } else {
            buffer.setString(String(count), at: arrayCountIndex)
        }
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
}
