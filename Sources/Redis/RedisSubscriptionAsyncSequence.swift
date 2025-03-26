//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-redis open source project
//
// Copyright (c) 2023 Apple Inc. and the swift-redis project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-redis project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import RESP

struct RedisSubscriptionAsyncSequence<Base: AsyncSequence>: AsyncSequence where Base.Element == RESPToken {
    typealias Element = Base.Element
    typealias AsyncIterator = Base.AsyncIterator
    let baseIterator: Base.AsyncIterator

    func makeAsyncIterator() -> Base.AsyncIterator {
        self.baseIterator
    }
}

@available(*, unavailable)
extension RedisSubscriptionAsyncSequence: Sendable {
}
