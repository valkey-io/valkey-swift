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
import Synchronization

@available(valkeySwift 1.0, *)
extension ValkeyClient {
    @usableFromInline
    actor SubscriptionConnection {
        enum State {
            case noConnection
            case acquiringConnection([CheckedContinuation<ValkeyConnection, any Error>])
            case connectionOpen(ValkeyConnection, Int)
        }
        var state: State

        init() {
            self.state = .noConnection
        }

        @usableFromInline
        func acquire(_ operation: () async throws -> ValkeyConnection) async throws -> ValkeyConnection {
            switch self.state {
            case .noConnection:
                state = .acquiringConnection([])
                do {
                    let connection = try await operation()
                    guard case .acquiringConnection(let continuations) = state else {
                        preconditionFailure("State should still be acquiring")
                    }
                    for cont in continuations {
                        cont.resume(returning: connection)
                    }
                    state = .connectionOpen(connection, continuations.count + 1)
                    return connection
                } catch {
                    guard case .acquiringConnection(let continuations) = state else {
                        preconditionFailure("Can't have state set to none, while acquiring connection")
                    }
                    for cont in continuations {
                        cont.resume(throwing: error)
                    }
                    state = .noConnection
                    throw error
                }
            case .acquiringConnection(var continuations):
                return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<ValkeyConnection, any Error>) in
                    continuations.append(cont)
                    self.state = .acquiringConnection(continuations)
                }
            case .connectionOpen(let connection, let count):
                state = .connectionOpen(connection, count + 1)
                return connection
            }
        }

        @usableFromInline
        func release(id: ValkeyConnection.ID, _ operation: (ValkeyConnection) -> Void) {
            switch self.state {
            case .noConnection, .acquiringConnection:
                break
            case .connectionOpen(let connection, let count):
                guard connection.id == id else { return }
                assert(count > 0, "Cannot have a count of active references to connection less than one")
                if count == 1 {
                    state = .noConnection
                    operation(connection)
                } else {
                    state = .connectionOpen(connection, count - 1)
                }
            }
        }

        @usableFromInline
        func connectionClosed() {
            self.state = .noConnection
        }
    }

    @inlinable
    func withSubscriptionConnection<Value>(
        isolation: isolated (any Actor)? = #isolation,
        operation: (ValkeyConnection) async throws -> sending Value
    ) async throws -> sending Value {
        let connection = try await self.subscriptionConnection.acquire { try await self.node.leaseConnection() }
        do {
            let value = try await operation(connection)
            await self.subscriptionConnection.release(id: connection.id) { self.node.releaseConnection($0) }
            return value
        } catch {
            await self.subscriptionConnection.release(id: connection.id) { self.node.releaseConnection($0) }
            throw error
        }

    }

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
        isolation: isolated (any Actor)? = #isolation,
        process: (ValkeySubscription) async throws -> sending Value
    ) async throws -> Value {
        try await self.subscribe(
            command: SUBSCRIBE(channels: channels),
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
        isolation: isolated (any Actor)? = #isolation,
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
        isolation: isolated (any Actor)? = #isolation,
        process: (ValkeySubscription) async throws -> sending Value
    ) async throws -> Value {
        try await self.subscribe(
            command: PSUBSCRIBE(patterns: patterns),
            filters: patterns.map { .pattern($0) },
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
                        return try await self.withSubscriptionConnection { connection in
                            try await connection.subscribe(command: command, filters: filters) { subscription in
                                // push messages on connection subscription to client subscription
                                for try await message in subscription {
                                    cont.yield(message)
                                }
                            }
                            cont.finish()
                        }
                    } catch let error as ValkeyClientError {
                        // if connection closes for some reason don't exit loop so it opens a new connection
                        switch error.errorCode {
                        case .connectionClosed, .connectionClosedDueToCancellation, .connectionClosing:
                            await self.subscriptionConnection.connectionClosed()
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
