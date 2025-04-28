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

/// Type that can be rendered into a RESP buffer
public protocol RESPRenderable: Sendable {
    var respEntries: Int { get }

    func encode(into commandEncoder: inout RESPCommandEncoder)
}

extension Optional: RESPRenderable where Wrapped: RESPRenderable {

    @inlinable
    public var respEntries: Int {
        switch self {
        case .none:
            return 0
        case .some(let value):
            return value.respEntries
        }
    }

    @inlinable
    public func encode(into commandEncoder: inout RESPCommandEncoder) {
        switch self {
        case .some(let wrapped):
            return wrapped.encode(into: &commandEncoder)
        case .none:
            return
        }
    }
}

extension String: RESPRenderable {
    public var respEntries: Int { 1 }

    @inlinable
    public func encode(into commandEncoder: inout RESPCommandEncoder) {
        commandEncoder.encodeBulkString(self)
    }
}

extension Array: RESPRenderable where Element: RESPRenderable {
    @inlinable
    public var respEntries: Int {
        self.reduce(0) { $0 + $1.respEntries }
    }

    @inlinable
    public func encode(into commandEncoder: inout RESPCommandEncoder) {
        for element in self {
            element.encode(into: &commandEncoder)
        }
    }
}

extension Int: RESPRenderable {

    @inlinable
    public var respEntries: Int { 1 }

    @inlinable
    public func encode(into commandEncoder: inout RESPCommandEncoder) {
        commandEncoder.encodeBulkString(String(self))
    }
}

extension Double: RESPRenderable {

    @inlinable
    public var respEntries: Int { 1 }

    @inlinable
    public func encode(into commandEncoder: inout RESPCommandEncoder) {
        commandEncoder.encodeBulkString(String(self))
    }
}
