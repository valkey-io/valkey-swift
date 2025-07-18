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

@available(valkeySwift 1.0, *)
extension ValkeyConnection {
    /// Subscribe to list of channels and run closure with subscription
    ///
    /// When the closure is exited the channels are automatically unsubscribed from. It is
    /// possible to have multiple subscriptions running on the same connection and unsubscribe
    /// commands will only be sent to Valkey when there are no subscriptions active for that
    /// channel
    ///
    /// - Parameters:
    ///   - channels: list of channels to subscribe to
    ///   - isolation: Actor isolation
    ///   - process: Closure that is called with subscription async sequence
    /// - Returns: Return value of closure
    @inlinable
    public func subscribe<Value>(
        to channels: String...,
        isolation: isolated (any Actor)? = #isolation,
        process: (ValkeySubscription) async throws -> sending Value
    ) async throws -> sending Value {
        try await self.subscribe(to: channels, process: process)
    }

    @inlinable
    /// Subscribe to list of channels and run closure with subscription
    ///
    /// When the closure is exited the channels are automatically unsubscribed from. It is
    /// possible to have multiple subscriptions running on the same connection and unsubscribe
    /// commands will only be sent to Valkey when there are no subscriptions active for that
    /// channel
    ///
    /// - Parameters:
    ///   - channels: list of channels to subscribe to
    ///   - isolation: Actor isolation
    ///   - process: Closure that is called with subscription async sequence
    /// - Returns: Return value of closure
    public func subscribe<Value>(
        to channels: [String],
        isolation: isolated (any Actor)? = #isolation,
        process: (ValkeySubscription) async throws -> sending Value
    ) async throws -> sending Value {
        try await self.subscribe(
            command: SUBSCRIBE(channels: channels),
            filters: channels.map { .channel($0) },
            isolation: isolation,
            process: process
        )
    }

    /// Subscribe to list of channel patterns and run closure with subscription
    ///
    /// When the closure is exited the patterns are automatically unsubscribed from. It is
    /// possible to have multiple subscriptions running on the same connection and unsubscribe
    /// commands will only be sent to Valkey when there are no subscriptions active for that
    /// pattern
    ///
    /// - Parameters:
    ///   - patterns: list of channel patterns to subscribe to
    ///   - isolation: Actor isolation
    ///   - process: Closure that is called with subscription async sequence
    /// - Returns: Return value of closure
    @inlinable
    public func psubscribe<Value>(
        to patterns: String...,
        isolation: isolated (any Actor)? = #isolation,
        process: (ValkeySubscription) async throws -> sending Value
    ) async throws -> sending Value {
        try await self.psubscribe(to: patterns, process: process)
    }

    /// Subscribe to list of pattern matching channels and run closure with subscription
    ///
    /// When the closure is exited the patterns are automatically unsubscribed from. It is
    /// possible to have multiple subscriptions running on the same connection and unsubscribe
    /// commands will only be sent to Valkey when there are no subscriptions active for that
    /// pattern
    ///
    /// - Parameters:
    ///   - patterns: list of channel patterns to subscribe to
    ///   - isolation: Actor isolation
    ///   - process: Closure that is called with subscription async sequence
    /// - Returns: Return value of closure
    @inlinable
    public func psubscribe<Value>(
        to patterns: [String],
        isolation: isolated (any Actor)? = #isolation,
        process: (ValkeySubscription) async throws -> sending Value
    ) async throws -> sending Value {
        try await self.subscribe(
            command: PSUBSCRIBE(patterns: patterns),
            filters: patterns.map { .pattern($0) },
            isolation: isolation,
            process: process
        )
    }

    /// Subscribe to list of shard channels and run closure with subscription
    ///
    /// When the closure is exited the shard channels are automatically unsubscribed from. It is
    /// possible to have multiple subscriptions running on the same connection and unsubscribe
    /// commands will only be sent to Valkey when there are no subscriptions active for that
    /// pattern
    ///
    /// - Parameters:
    ///   - shardchannels: list of shard channels to subscribe to
    ///   - isolation: Actor isolation
    ///   - process: Closure that is called with subscription async sequence
    /// - Returns: Return value of closure
    @inlinable
    public func ssubscribe<Value>(
        to shardchannels: String...,
        isolation: isolated (any Actor)? = #isolation,
        process: (ValkeySubscription) async throws -> sending Value
    ) async throws -> sending Value {
        try await self.ssubscribe(to: shardchannels, process: process)
    }

    /// Subscribe to list of shard channels and run closure with subscription
    ///
    /// When the closure is exited the shard channels are automatically unsubscribed from. It is
    /// possible to have multiple subscriptions running on the same connection and unsubscribe
    /// commands will only be sent to Valkey when there are no subscriptions active for that
    /// pattern
    ///
    /// - Parameters:
    ///   - shardchannels: list of shard channels to subscribe to
    ///   - isolation: Actor isolation
    ///   - process: Closure that is called with subscription async sequence
    /// - Returns: Return value of closure
    @inlinable
    public func ssubscribe<Value>(
        to shardchannels: [String],
        isolation: isolated (any Actor)? = #isolation,
        process: (ValkeySubscription) async throws -> sending Value
    ) async throws -> sending Value {
        try await self.subscribe(
            command: SSUBSCRIBE(shardchannels: shardchannels),
            filters: shardchannels.map { .shardChannel($0) },
            isolation: isolation,
            process: process
        )
    }

    /// Subscribe to key invalidation channel required for client-side caching
    ///
    /// See https://valkey.io/topics/client-side-caching/ for more details
    ///
    /// When the closure is exited the channel is automatically unsubscribed from. It is
    /// possible to have multiple subscriptions running on the same connection and unsubscribe
    /// commands will only be sent to Valkey when there are no subscriptions active for that
    /// channel
    ///
    /// - Parameters:
    ///   - isolation: Actor isolation
    ///   - process: Closure that is called with async sequence of key invalidations
    /// - Returns: Return value of closure
    @inlinable
    public func subscribeKeyInvalidations<Value>(
        isolation: isolated (any Actor)? = #isolation,
        process: (AsyncMapSequence<ValkeySubscription, ValkeyKey>) async throws -> sending Value
    ) async throws -> sending Value {
        try await self.subscribe(to: [ValkeySubscriptions.invalidateChannel], isolation: isolation) { subscription in
            let keys = subscription.map { ValkeyKey($0.message) }
            return try await process(keys)
        }
    }

    @inlinable
    func subscribe<Value>(
        command: some ValkeyCommand,
        filters: [ValkeySubscriptionFilter],
        isolation: isolated (any Actor)? = #isolation,
        process: (ValkeySubscription) async throws -> sending Value
    ) async throws -> sending Value {
        let (id, stream) = try await subscribe(command: command, filters: filters)
        let value: Value
        do {
            value = try await process(stream)
            try Task.checkCancellation()
        } catch {
            _ = try? await unsubscribe(id: id)
            throw error
        }
        _ = try await unsubscribe(id: id)
        return value
    }

    @usableFromInline
    func subscribe(
        command: some ValkeyCommand,
        filters: [ValkeySubscriptionFilter]
    ) async throws -> (Int, ValkeySubscription) {
        let requestID = Self.requestIDGenerator.next()
        let (stream, streamContinuation) = ValkeySubscription.makeStream()
        return try await withTaskCancellationHandler {
            if Task.isCancelled {
                throw ValkeyClientError(.cancelled)
            }
            let subscriptionID: Int = try await withCheckedThrowingContinuation { continuation in
                self.channelHandler.subscribe(
                    command: command,
                    streamContinuation: streamContinuation,
                    filters: filters,
                    promise: .swift(continuation),
                    requestID: requestID
                )
            }
            return (subscriptionID, stream)
        } onCancel: {
            self.cancel(requestID: requestID)
        }
    }

    @usableFromInline
    func unsubscribe(id: Int) async throws {
        let requestID = Self.requestIDGenerator.next()
        try await withTaskCancellationHandler {
            if Task.isCancelled {
                throw ValkeyClientError(.cancelled)
            }
            try await withCheckedThrowingContinuation { continuation in
                self.channelHandler.unsubscribe(id: id, promise: .swift(continuation), requestID: requestID)
            }
        } onCancel: {
            self.cancel(requestID: requestID)
        }
    }

    /// DEBUG function to check if the internal subscription state machine is empty
    package func isSubscriptionsEmpty() -> Bool {
        self.channelHandler.subscriptions.isEmpty
    }
}
