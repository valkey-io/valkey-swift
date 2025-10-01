//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore

@available(valkeySwift 1.0, *)
extension ValkeyConnection {
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
        try await self._subscribe(
            command: SSUBSCRIBE(shardchannels: shardchannels),
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
        try await self.subscribe(to: [ValkeySubscriptions.invalidateChannel]) { subscription in
            let keys = subscription.map { ValkeyKey($0.message) }
            return try await process(keys)
        }
    }

    /// Execute subscribe command and run closure using related ``ValkeySubscription``
    /// AsyncSequence
    ///
    /// This should not be called directly, used the related commands
    /// ``ValkeyConnection/subscribe(to:isolation:process:)`` or
    /// ``ValkeyConnection/psubscribe(to:isolation:process:)``
    @inlinable
    public func _subscribe<Value>(
        command: some ValkeySubscribeCommand,
        isolation: isolated (any Actor)? = #isolation,
        process: (ValkeySubscription) async throws -> sending Value
    ) async throws -> sending Value {
        let (id, stream) = try await subscribe(command: command, filters: command.filters)
        let value: Value
        do {
            value = try await process(stream)
            try Task.checkCancellation()
        } catch {
            // call unsubscribe in unstructured Task to avoid it being cancelled
            _ = await Task {
                try await unsubscribe(id: id)
            }.result
            throw error
        }
        // call unsubscribe in unstructured Task to avoid it being cancelled
        _ = try await Task {
            try await unsubscribe(id: id)
        }.value
        return value
    }

    @usableFromInline
    func subscribe(
        command: some ValkeyCommand,
        filters: [ValkeySubscriptionFilter]
    ) async throws -> (Int, ValkeySubscription) {
        let requestID = Self.requestIDGenerator.next()
        let (stream, streamContinuation) = ValkeySubscription.makeStream()
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
    }

    @usableFromInline
    func unsubscribe(id: Int) async throws {
        let requestID = Self.requestIDGenerator.next()
        try await withCheckedThrowingContinuation { continuation in
            self.channelHandler.unsubscribe(id: id, promise: .swift(continuation), requestID: requestID)
        }
    }

    /// DEBUG function to check if the internal subscription state machine is empty
    package func isSubscriptionsEmpty() -> Bool {
        self.channelHandler.subscriptions.isEmpty
    }
}
