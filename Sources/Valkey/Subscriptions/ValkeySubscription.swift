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
    public typealias Failure = ValkeyClientError

    @usableFromInline
    typealias BaseAsyncSequence = AsyncStream<Result<ValkeySubscriptionMessage, ValkeyClientError>>
    typealias Continuation = BaseAsyncSequence.Continuation

    @usableFromInline
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
        @usableFromInline
        var base: BaseAsyncSequence.AsyncIterator

        #if compiler(>=6.2)
        @concurrent
        @inlinable
        public mutating func next() async throws(ValkeyClientError) -> Element? {
            try await self.base.next()?.get()
        }
        #else
        @inlinable
        public mutating func next() async throws(ValkeyClientError) -> Element? {
            try await self.base.next()?.get()
        }
        #endif

        @inlinable
        public mutating func next(isolation actor: isolated (any Actor)?) async throws(ValkeyClientError) -> ValkeySubscriptionMessage? {
            try await self.base.next(isolation: actor)?.get()
        }
    }
}

/// A sequence of messages from Valkey subscription.
@available(valkeySwift 1.0, *)
public struct ValkeyClientSubscription: AsyncSequence, Sendable {
    /// The type that the sequence produces.
    public typealias Element = ValkeySubscriptionMessage
    public typealias Failure = ValkeyClientError

    @usableFromInline
    let base: ValkeySubscription

    @inlinable
    init(base: ValkeySubscription) {
        self.base = base
    }

    /// Creates a sequence of subscription messages.
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: self.base.makeAsyncIterator())
    }

    /// An iterator that provides subscription messages.
    public struct AsyncIterator: AsyncIteratorProtocol {
        @usableFromInline
        var base: ValkeySubscription.AsyncIterator

        #if compiler(>=6.2)
        @concurrent
        @inlinable
        public mutating func next() async throws(ValkeyClientError) -> Element? {
            try await self.base.next()
        }
        #else
        @inlinable
        public mutating func next() async throws(ValkeyClientError) -> Element? {
            try await self.base.next()
        }
        #endif

        @inlinable
        public mutating func next(isolation actor: isolated (any Actor)?) async throws(ValkeyClientError) -> ValkeySubscriptionMessage? {
            try await self.base.next(isolation: actor)
        }
    }
}
