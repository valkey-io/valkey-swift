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

public struct RESPCommand: Sendable {
    @usableFromInline
    package let buffer: ByteBuffer

    @inlinable
    public init<each Arg: RESPRenderable>(_ command: repeat each Arg) {
        var buffer = ByteBuffer()
        buffer.writeRESP3TypeIdentifier(.array)
        let arrayCountIndex = buffer.writerIndex
        // temporarily write 0 here, we will update this once everything else is written
        buffer.writeString("0")
        buffer.writeStaticString("\r\n")
        var count = 0
        for arg in repeat each command {
            count += arg.writeToRESPBuffer(&buffer)
        }
        if count > 9 {
            // I'm being lazy here and not supporting more than 99 arguments
            precondition(count < 100)
            // We need to rebuild ByteBuffer with space for double digit count
            // skip past count + \r\n
            let sliceStart = arrayCountIndex + 3
            var slice = buffer.getSlice(at: sliceStart, length: buffer.writerIndex - sliceStart)!
            var buffer = ByteBufferAllocator().buffer(capacity: slice.readableBytes + 5)
            buffer.writeRESP3TypeIdentifier(.array)
            buffer.writeString(String(count))
            buffer.writeStaticString("\r\n")
            buffer.writeBuffer(&slice)
            self.buffer = buffer
        } else {
            buffer.setString(String(count), at: arrayCountIndex)
            self.buffer = buffer
        }
    }
}
