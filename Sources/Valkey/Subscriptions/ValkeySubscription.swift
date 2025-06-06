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

/// Message received from subscription
public struct ValkeySubscriptionMessage: Sendable, Equatable {
    public let channel: String
    public let message: String

    package init(channel: String, message: String) {
        self.channel = channel
        self.message = message
    }
}

/// Sequence of messages from Valkey subscription
public struct ValkeySubscription: AsyncSequence, Sendable {
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
