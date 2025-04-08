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

@usableFromInline
package struct RESPPureToken: RESPRenderable {
    @usableFromInline
    let token: String?
    @inlinable
    package init(_ token: String, _ value: Bool) {
        if value {
            self.token = token
        } else {
            self.token = nil
        }
    }
    @inlinable
    package var respEntries: Int {
        self.token != nil ? 1 : 0
    }
    @inlinable
    package func encode(into commandEncoder: inout RESPCommandEncoder) {
        self.token.encode(into: &commandEncoder)
    }
}

@usableFromInline
package struct RESPWithToken<Value: RESPRenderable>: RESPRenderable {
    @usableFromInline
    let value: Value?
    @usableFromInline
    let token: String

    @inlinable
    package init(_ token: String, _ value: Value?) {
        self.value = value
        self.token = token
    }
    @inlinable
    package var respEntries: Int {
        guard let value = self.value, value.respEntries > 0 else { return 0 }
        return value.respEntries + 1
    }
    @inlinable
    package func encode(into commandEncoder: inout RESPCommandEncoder) {
        guard let value, value.respEntries > 0 else {
            return
        }

        self.token.encode(into: &commandEncoder)
        value.encode(into: &commandEncoder)
    }
}

@usableFromInline
package struct RESPArrayWithCount<Element: RESPRenderable>: RESPRenderable {
    @usableFromInline
    let array: [Element]

    @inlinable
    package init(_ array: [Element]) {
        self.array = array
    }
    @inlinable
    package var respEntries: Int {
        return self.array.respEntries + 1
    }
    @inlinable
    package func encode(into commandEncoder: inout RESPCommandEncoder) {
        self.array.count.encode(into: &commandEncoder)
        self.array.encode(into: &commandEncoder)
    }
}
