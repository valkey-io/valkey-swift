//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore

/// A message received from a subscription.
public struct ValkeySubscriptionMessage: Sendable, Equatable {
    /// The messages channel.
    public let channel: String
    /// The bulk string of the message.
    public let message: RESPBulkString

    package init(channel: String, message: ByteBuffer) {
        self.channel = channel
        self.message = RESPBulkString(message)
    }

    /// helper function used by tests
    package init(channel: String, message: String) {
        self.channel = channel
        self.message = RESPBulkString(ByteBuffer(string: message))
    }
}

/// A sequence of messages from Valkey subscription.
@available(valkeySwift 1.0, *)
public struct ValkeySubscription: AsyncSequence, Sendable {
    /// The type that the sequence produces.
    public typealias Element = ValkeySubscriptionMessage

    typealias BaseAsyncSequence = AsyncThrowingStream<ValkeySubscriptionMessage, any Error>
    typealias Continuation = BaseAsyncSequence.Continuation

    let base: BaseAsyncSequence

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
