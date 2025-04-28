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

/// Type that can be rendered as a single bulk string
public protocol RESPStringRenderable: Sendable {
    func encode(into commandEncoder: inout RESPCommandEncoder)
}

extension String: RESPStringRenderable {}

extension ByteBuffer: RESPStringRenderable {
    public func encode(into commandEncoder: inout RESPCommandEncoder) {
        commandEncoder.encodeBulkString(self.readableBytesView)
    }
}

/// Internal type used to render RESPStringRenderable conforming type
@usableFromInline
struct RESPBulkString<Value: RESPStringRenderable>: RESPRenderable {
    public var respEntries: Int { 1 }

    @usableFromInline
    let value: Value

    @usableFromInline
    init(_ value: Value) {
        self.value = value
    }

    @usableFromInline
    func encode(into commandEncoder: inout RESPCommandEncoder) {
        self.value.encode(into: &commandEncoder)
    }
}
