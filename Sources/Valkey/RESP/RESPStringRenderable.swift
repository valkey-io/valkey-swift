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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Type that can be rendered as a single bulk string
public protocol RESPStringRenderable: Sendable {
    func encode(into commandEncoder: inout ValkeyCommandEncoder)
}

extension String: RESPStringRenderable {}

extension ByteBuffer: RESPStringRenderable {
    public func encode(into commandEncoder: inout ValkeyCommandEncoder) {
        commandEncoder.encodeBulkString(self.readableBytesView)
    }
}

extension RESPStringRenderable where Self: Collection<UInt8> {
    public func encode(into commandEncoder: inout ValkeyCommandEncoder) {
        commandEncoder.encodeBulkString(self)
    }
}

extension [UInt8]: RESPStringRenderable {}
extension ArraySlice<UInt8>: RESPStringRenderable {}
extension ReversedCollection: RESPStringRenderable where Base.Element == UInt8 {}
extension Slice: RESPStringRenderable where Base.Element == UInt8 {}
extension Data: RESPStringRenderable {}

/// Internal type used to render RESPStringRenderable conforming type.
///
/// Unforunately we cannot conform RESPStringRenderable to RESPRenderable if we want
/// Collections to conform to RESPStringRenderable, as there is already a conformance
/// to Collection when all the elements conform to RESPRenderable.
@usableFromInline
struct RESPBulkString<Value: RESPStringRenderable>: RESPRenderable {
    @usableFromInline
    var respEntries: Int { 1 }

    @usableFromInline
    let value: Value

    @inlinable
    init(_ value: Value) {
        self.value = value
    }

    @inlinable
    func encode(into commandEncoder: inout ValkeyCommandEncoder) {
        self.value.encode(into: &commandEncoder)
    }
}
