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

/// A message received from a subscription.
public struct ValkeySubscriptionMessage: Sendable, Equatable {
    /// The messages channel.
    public let channel: String
    /// The byte buffer of the message.
    public let message: ByteBuffer

    package init(channel: String, message: ByteBuffer) {
        self.channel = channel
        self.message = message
    }

    /// helper function used by tests
    package init(channel: String, message: String) {
        self.channel = channel
        self.message = ByteBuffer(string: message)
    }
}

/// Sequence of messages from Valkey subscription.
public struct ValkeySubscription: AsyncSequence, Sendable {
    /// The type that the sequence produces.
    public typealias Element = ValkeySubscriptionMessage

    @usableFromInline
    typealias BaseAsyncSequence = AsyncThrowingStream<ValkeySubscriptionMessage, Error>
    @usableFromInline
    typealias Continuation = BaseAsyncSequence.Continuation

    let base: BaseAsyncSequence

    @usableFromInline
    static func makeStream() -> (Self, Self.Continuation) {
        let (stream, continuation) = BaseAsyncSequence.makeStream()
        return (.init(base: stream), continuation)
    }

    /// Creates a sequence of subscription messages.
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: self.base.makeAsyncIterator())
    }

    /// An iterator that provides subscription messages.
    public struct AsyncIterator: AsyncIteratorProtocol {
        var base: BaseAsyncSequence.AsyncIterator

        public mutating func next() async throws -> Element? {
            try await self.base.next()
        }
    }
}
