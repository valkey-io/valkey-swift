//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 Apple Inc. and the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of valkey-swift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore

public struct RESPTokenDecoder: NIOSingleStepByteToMessageDecoder {
    public typealias InboundOut = RESPToken

    public init() {}

    public mutating func decode(buffer: inout ByteBuffer) throws -> RESPToken? {
        try RESPToken(consuming: &buffer)
    }

    public mutating func decodeLast(buffer: inout ByteBuffer, seenEOF _: Bool) throws -> RESPToken? {
        try self.decode(buffer: &buffer)
    }
}
