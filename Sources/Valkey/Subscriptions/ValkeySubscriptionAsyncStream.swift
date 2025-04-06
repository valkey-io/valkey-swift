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

/// Sequence of messages from Valkey subscription
public struct ValkeySubscriptionAsyncStream: AsyncSequence, Sendable {
    public typealias Element = ValkeySubscriptionMessage

    typealias BaseAsyncSequence = AsyncThrowingStream<ValkeySubscriptionMessage, Error>
    typealias Continuation = BaseAsyncSequence.Continuation

    let base: BaseAsyncSequence

    static func makeStream() -> (Self, Self.Continuation) {
        let (stream, continuation) = BaseAsyncSequence.makeStream()
        return (.init(base: stream), continuation)
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: self.base.makeAsyncIterator())
    }

    public struct AsyncIterator: AsyncIteratorProtocol {
        var base: BaseAsyncSequence.AsyncIterator

        public mutating func next() async throws -> Element? {
            try await self.base.next()
        }
    }
}
