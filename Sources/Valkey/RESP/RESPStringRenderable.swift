//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of valkey-swift project authors
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

/// A type that can be rendered as a single bulk string.
public protocol RESPStringRenderable: Sendable, Hashable {
    func encode(into commandEncoder: inout ValkeyCommandEncoder)
}

extension String: RESPStringRenderable {}

extension Substring: RESPStringRenderable {}

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
extension Data: RESPStringRenderable {}

/// Internal type used to render RESPStringRenderable conforming type.
///
/// Unfortunately we cannot conform RESPStringRenderable to RESPRenderable if we want
/// Collections to conform to RESPStringRenderable, as there is already a conformance
/// to Collection when all the elements conform to RESPRenderable.
@usableFromInline
package struct RESPBulkString<Value: RESPStringRenderable>: RESPRenderable {
    @usableFromInline
    package var respEntries: Int { 1 }

    @usableFromInline
    let value: Value

    @inlinable
    package init(_ value: Value) {
        self.value = value
    }

    @inlinable
    package func encode(into commandEncoder: inout ValkeyCommandEncoder) {
        self.value.encode(into: &commandEncoder)
    }
}
