//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore

package struct RESPTokenDecoder: NIOSingleStepByteToMessageDecoder {
    package typealias InboundOut = RESPToken

    package init() {}

    package mutating func decode(buffer: inout ByteBuffer) throws -> RESPToken? {
        try RESPToken(consuming: &buffer)
    }

    package mutating func decodeLast(buffer: inout ByteBuffer, seenEOF _: Bool) throws -> RESPToken? {
        try self.decode(buffer: &buffer)
    }
}
