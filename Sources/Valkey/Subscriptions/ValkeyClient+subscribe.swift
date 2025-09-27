//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import Logging
import NIOCore
import Synchronization

@available(valkeySwift 1.0, *)
extension ValkeyClient {
    /// Run operation with the valkey subscription connection
    ///
    /// - Parameters:
    ///   - isolation: Actor isolation
    ///   - operation: Closure to run with subscription connection
    @inlinable
    func withSubscriptionConnection<Value>(
        isolation: isolated (any Actor)? = #isolation,
        _ operation: (ValkeyConnection) async throws -> sending Value
    ) async throws -> sending Value {
        let id = self.subscriptionConnectionIDGenerator.next()

        let connection = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<ValkeyConnection, Error>) in
                self.leaseSubscriptionConnection(id: id, request: cont)
            }
        } onCancel: {
            self.cancelSubscriptionConnection(id: id)
        }
        self.logger.trace("Got subscription connection", metadata: ["valkey_subscription_connection_id": .stringConvertible(id)])

        defer {
            self.releaseSubscriptionConnection(id: id)
        }
        return try await operation(connection)
    }

    /// Subscribe to list of channels and run closure with subscription
    ///
    /// When the closure is exited the channels are automatically unsubscribed from.
    ///
    /// When running subscribe from `ValkeyClient` a single connection is used for
    /// all subscriptions.
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
        process: sending (ValkeyClientSubscription) async throws -> sending Value
    ) async throws -> sending Value {
        try await self.subscribe(to: channels, process: process)
    }

    @inlinable
    /// Subscribe to list of channels and run closure with subscription
    ///
    /// When the closure is exited the channels are automatically unsubscribed from.
    ///
    /// When running subscribe from `ValkeyClient` a single connection is used for
    /// all subscriptions.
    ///
    /// - Parameters:
    ///   - channels: list of channels to subscribe to
    ///   - isolation: Actor isolation
    ///   - process: Closure that is called with subscription async sequence
    /// - Returns: Return value of closure
    public func subscribe<Value>(
        to channels: [String],
        isolation: isolated (any Actor)? = #isolation,
        process: sending (ValkeyClientSubscription) async throws -> sending Value
    ) async throws -> sending Value {
        try await self.subscribe(
            command: SUBSCRIBE(channels: channels),
            filters: channels.map { .channel($0) },
            process: process
        )
    }

    /// Subscribe to list of channel patterns and run closure with subscription
    ///
    /// When the closure is exited the patterns are automatically unsubscribed from.
    ///
    /// When running subscribe from `ValkeyClient` a single connection is used for
    /// all subscriptions.
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
        process: sending (ValkeyClientSubscription) async throws -> sending Value
    ) async throws -> sending Value {
        try await self.psubscribe(to: patterns, process: process)
    }

    /// Subscribe to list of pattern matching channels and run closure with subscription
    ///
    /// When the closure is exited the patterns are automatically unsubscribed from.
    ///
    /// When running subscribe from `ValkeyClient` a single connection is used for
    /// all subscriptions.
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
        process: sending (ValkeyClientSubscription) async throws -> sending Value
    ) async throws -> sending Value {
        try await self.subscribe(
            command: PSUBSCRIBE(patterns: patterns),
            filters: patterns.map { .pattern($0) },
            process: process
        )
    }

    /// Subscribe to key invalidation channel required for client-side caching
    ///
    /// See https://valkey.io/topics/client-side-caching/ for more details. The `process`
    /// closure is provided with a stream of ValkeyKeys that have been invalidated and also
    /// the client id of the subscription connection to redirect client tracking messages to.
    ///
    /// When the closure is exited the channel is automatically unsubscribed from.
    ///
    /// When running subscribe from `ValkeyClient` a single connection is used for
    /// all subscriptions.
    ///
    /// - Parameters:
    ///   - isolation: Actor isolation
    ///   - process: Closure that is called with async sequence of key invalidations and the client id
    ///         of the connection the subscription is running on.
    /// - Returns: Return value of closure
    @inlinable
    public func subscribeKeyInvalidations<Value>(
        isolation: isolated (any Actor)? = #isolation,
        process: (AsyncMapSequence<ValkeySubscription, ValkeyKey>, Int) async throws -> sending Value
    ) async throws -> sending Value {
        try await withSubscriptionConnection { connection in
            let id = try await connection.clientId()
            return try await connection.subscribe(to: [ValkeySubscriptions.invalidateChannel]) { subscription in
                let keys = subscription.map { ValkeyKey($0.message) }
                return try await process(keys, id)
            }
        }
    }

    @inlinable
    func subscribe<Value>(
        command: some ValkeyCommand,
        filters: [ValkeySubscriptionFilter],
        isolation: isolated (any Actor)? = #isolation,
        process: sending (ValkeyClientSubscription) async throws -> sending Value
    ) async throws -> sending Value {
        try await withThrowingTaskGroup(of: Void.self, isolation: isolation) { group in
            let (stream, streamContinuation) = ValkeyClientSubscription.makeStream()
            group.addTask {
                defer { streamContinuation.finish() }
                while true {
                    try Task.checkCancellation()
                    do {
                        return try await self.withSubscriptionConnection { connection in
                            try await connection.subscribe(command: command, filters: filters) { subscription in
                                try await withCheckedThrowingContinuation { cont in
                                    streamContinuation.yield(.init(subscription: subscription, continuation: cont))
                                }
                            }
                        }
                    } catch let error as ValkeyClientError {
                        // if connection closes for some reason don't exit loop so it opens a new connection
                        switch error.errorCode {
                        case .connectionClosed, .connectionClosedDueToCancellation, .connectionClosing:
                            break
                        default:
                            throw error
                        }
                    }
                    break
                }
            }
            let value = try await process(stream)
            group.cancelAll()
            return value
        }
    }
}
