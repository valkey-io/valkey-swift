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

public struct ValkeySubscriptionMessage: Sendable, Equatable {
    public let channel: String
    public let message: String

    package init(channel: String, message: String) {
        self.channel = channel
        self.message = message
    }
}

extension ValkeyConnection {
    public func subscribe(to channels: String...) async throws -> ValkeySubscriptionAsyncStream {
        try await self.subscribe(to: channels)
    }

    public func subscribe(to channels: [String]) async throws -> ValkeySubscriptionAsyncStream {
        let command = SUBSCRIBE(channel: channels)
        return try await subscribe(command: command, filter: .channels(Set(channels)))
    }

    public func psubscribe(to pattern: String...) async throws -> ValkeySubscriptionAsyncStream {
        try await self.psubscribe(to: pattern)
    }

    public func psubscribe(to pattern: [String]) async throws -> ValkeySubscriptionAsyncStream {
        let command = PSUBSCRIBE(pattern: pattern)
        return try await subscribe(command: command, filter: .patterns(Set(pattern)))
    }

    func subscribe(command: some RESPCommand, filter: ValkeySubscriptionFilter) async throws -> ValkeySubscriptionAsyncStream {
        let (stream, streamContinuation) = ValkeySubscriptionAsyncStream.makeStream()
        if self.channel.eventLoop.inEventLoop {
            let subscriptionID = self.channelHandler.value.addSubscription(
                continuation: streamContinuation,
                filter: filter
            )
            _ = try await self._send(command: command)
                .flatMapErrorThrowing { error in
                    self.channelHandler.value.subscriptions.removeSubscription(id: subscriptionID)
                    throw error
                }
                .get()
        } else {
            _ = try await self.channel.eventLoop.flatSubmit {
                let subscriptionID = self.channelHandler.value.addSubscription(
                    continuation: streamContinuation,
                    filter: filter
                )
                return self._send(command: command)
                    .flatMapErrorThrowing { error in
                        self.channelHandler.value.subscriptions.removeSubscription(id: subscriptionID)
                        throw error
                    }
            }.get()
        }
        return stream
    }

    // Function used internally by subscribe
    @inlinable
    func _send<Command: RESPCommand>(command: Command) -> EventLoopFuture<RESPToken> {
        self.channel.eventLoop.assertInEventLoop()
        var encoder = RESPCommandEncoder()
        command.encode(into: &encoder)
        let buffer = encoder.buffer

        let promise = channel.eventLoop.makePromise(of: RESPToken.self)
        self.channelHandler.value.write(request: ValkeyRequest.single(buffer: buffer, promise: .nio(promise)))
        return promise.futureResult
    }
}
