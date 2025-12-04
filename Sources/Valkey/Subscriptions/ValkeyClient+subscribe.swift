//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
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
        let node = self.node
        let id = node.subscriptionConnectionIDGenerator.next()

        let connection = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<ValkeyConnection, Error>) in
                node.leaseSubscriptionConnection(id: id, request: cont)
            }
        } onCancel: {
            node.cancelSubscriptionConnection(id: id)
        }

        defer {
            node.releaseSubscriptionConnection(id: id)
        }
        return try await operation(connection)
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
                let keys = subscription.map { ValkeyKey(fromBulkString: $0.message) }
                return try await process(keys, id)
            }
        }
    }

    /// Execute subscribe command and run closure using related ``ValkeySubscription``
    /// AsyncSequence
    ///
    /// This should not be called directly, used the related commands
    /// ``ValkeyClient/subscribe(to:isolation:process:)`` or
    /// ``ValkeyClient/psubscribe(to:isolation:process:)``
    @inlinable
    public func _subscribe<Value>(
        command: some ValkeySubscribeCommand,
        isolation: isolated (any Actor)? = #isolation,
        process: (ValkeySubscription) async throws -> sending Value
    ) async throws -> sending Value {
        try await self.withSubscriptionConnection { connection in
            try await connection._subscribe(command: command, isolation: isolation, process: process)
        }
    }
}
