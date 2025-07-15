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
extension ValkeyClient {
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
        process: (ValkeySubscription) async throws -> sending Value
    ) async throws -> Value {
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
        process: (ValkeySubscription) async throws -> sending Value
    ) async throws -> Value {
        try await self.subscribe(
            command: SUBSCRIBE(channel: channels),
            filters: channels.map { .channel($0) },
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
        process: (ValkeySubscription) async throws -> sending Value
    ) async throws -> Value {
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
        process: (ValkeySubscription) async throws -> sending Value
    ) async throws -> Value {
        try await self.subscribe(
            command: PSUBSCRIBE(pattern: patterns),
            filters: patterns.map { .pattern($0) },
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
    ///   - shardchannel: list of shard channels to subscribe to
    ///   - isolation: Actor isolation
    ///   - process: Closure that is called with subscription async sequence
    /// - Returns: Return value of closure
    @inlinable
    public func ssubscribe<Value>(
        to shardchannel: String...,
        process: (ValkeySubscription) async throws -> sending Value
    ) async throws -> Value {
        try await self.ssubscribe(to: shardchannel, process: process)
    }

    /// Subscribe to list of shard channels and run closure with subscription
    ///
    /// When the closure is exited the shard channels are automatically unsubscribed from. It is
    /// possible to have multiple subscriptions running on the same connection and unsubscribe
    /// commands will only be sent to Valkey when there are no subscriptions active for that
    /// pattern
    ///
    /// - Parameters:
    ///   - shardchannel: list of shard channels to subscribe to
    ///   - isolation: Actor isolation
    ///   - process: Closure that is called with subscription async sequence
    /// - Returns: Return value of closure
    @inlinable
    public func ssubscribe<Value>(
        to shardchannel: [String],
        process: (ValkeySubscription) async throws -> sending Value
    ) async throws -> Value {
        try await self.subscribe(
            command: SSUBSCRIBE(shardchannel: shardchannel),
            filters: shardchannel.map { .shardChannel($0) },
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
    ///   - process: Closure that is called with async sequence of key invalidations
    /// - Returns: Return value of closure
    @inlinable
    public func subscribeKeyInvalidations<Value>(
        process: (AsyncMapSequence<ValkeySubscription, ValkeyKey>) async throws -> sending Value
    ) async throws -> Value {
        try await self.subscribe(to: [ValkeySubscriptions.invalidateChannel]) { subscription in
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
    ) async throws -> Value {
        try await withThrowingTaskGroup(of: Void.self, isolation: isolation) { group in
            let (stream, cont) = ValkeySubscription.makeStream()
            group.addTask {
                while true {
                    do {
                        try Task.checkCancellation()
                        return try await self.withConnection { connection in
                            try await connection.subscribe(command: command, filters: filters) { subscription in
                                for try await message in subscription {
                                    cont.yield(message)
                                }
                            }
                            cont.finish()
                        }
                    } catch let error as ValkeyClientError {
                        switch error.errorCode {
                        case .connectionClosed, .connectionClosedDueToCancellation, .connectionClosing:
                            break
                        default:
                            cont.finish(throwing: error)
                            return
                        }
                    } catch {
                        cont.finish(throwing: error)
                        return
                    }
                }
            }
            let value = try await process(stream)
            group.cancelAll()
            return value
        }
    }
}
