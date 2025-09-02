//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import Synchronization

@available(valkeySwift 1.0, *)
@usableFromInline
struct IDGenerator: ~Copyable, Sendable {
    private let atomic: Atomic<Int>

    public init() {
        self.atomic = .init(0)
    }

    @usableFromInline
    func next() -> Int {
        self.atomic.wrappingAdd(1, ordering: .relaxed).newValue
    }
}
