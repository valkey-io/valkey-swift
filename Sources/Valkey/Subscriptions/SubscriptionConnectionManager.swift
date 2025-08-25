//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift project
//
// Copyright (c) 2025 the valkey-swift authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See valkey-swift/CONTRIBUTORS.txt for the list of valkey-swift authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Synchronization

/// Stores a reference to a single connection to be used by client for subscriptions
///
/// It ensures only ever one version of the connection is initialized, even if it requested
/// twice during initialization. Once it is available the object includes a reference count
/// so we can clean it up once nobody references it.
@available(valkeySwift 1.0, *)
@usableFromInline
package struct SubscriptionConnectionManager: ~Copyable, Sendable {
    @usableFromInline
    enum Action {
        case use(ValkeyConnection)
        case acquire
    }

    @usableFromInline
    enum State {
        case uninitialized
        case acquiring([CheckedContinuation<Action, any Error>])
        case available(ValkeyConnection, Int)
    }
    @usableFromInline
    let state: Mutex<State>

    init() {
        self.state = .init(.uninitialized)
    }

    @usableFromInline
    package func acquire(
        isolation: isolated (any Actor)? = #isolation,
        _ operation: () async throws -> ValkeyConnection
    ) async throws -> ValkeyConnection {
        let action: Action = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Action, any Error>) in
            self.state.withLock { state in
                switch state {
                case .uninitialized:
                    state = .acquiring([])
                    cont.resume(returning: .acquire)
                case .acquiring(var continuations):
                    continuations.append(cont)
                    state = .acquiring(continuations)
                case .available(let connection, let count):
                    state = .available(connection, count + 1)
                    cont.resume(returning: .use(connection))
                }
            }
        }
        switch action {
        case .acquire:
            do {
                let connection = try await operation()
                return self.state.withLock { state in
                    guard case .acquiring(let continuations) = state else {
                        preconditionFailure("State should still be acquiring")
                    }
                    for cont in continuations {
                        cont.resume(returning: .use(connection))
                    }
                    state = .available(connection, continuations.count + 1)
                    return connection
                }
            } catch is CancellationError {
                self.state.withLock { state in
                    guard case .acquiring(var continuations) = state else {
                        preconditionFailure("Can't have state set to none, while acquiring connection")
                    }
                    if let lastContinuation = continuations.popLast() {
                        state = .acquiring(continuations)
                        lastContinuation.resume(returning: .acquire)
                    } else {
                        state = .uninitialized
                    }
                }
                throw CancellationError()
            } catch {
                return try self.state.withLock { state in
                    guard case .acquiring(let continuations) = state else {
                        preconditionFailure("Can't have state set to none, while acquiring connection")
                    }
                    for cont in continuations {
                        cont.resume(throwing: error)
                    }
                    state = .uninitialized
                    throw error
                }
            }
        case .use(let connection):
            return connection
        }
    }

    @usableFromInline
    package func release(connection: ValkeyConnection, _ operation: (ValkeyConnection) -> Void) {
        self.state.withLock { state in
            switch state {
            case .uninitialized, .acquiring:
                break
            case .available(let storedConnection, let count):
                guard storedConnection.id == connection.id else { return }
                assert(count > 0, "Cannot have a count of active references to connection less than one")
                if count == 1 {
                    state = .uninitialized
                    operation(connection)
                } else {
                    state = .available(connection, count - 1)
                }
            }
        }
    }

    @inlinable
    package func withConnection<Returning>(
        isolation: isolated (any Actor)? = #isolation,
        _ operation: (ValkeyConnection) async throws -> sending Returning,
        acquire acquireOperation: () async throws -> ValkeyConnection,
        release releaseOperation: (ValkeyConnection) -> Void
    ) async throws -> sending Returning {
        let value = try await self.acquire(acquireOperation)
        defer {
            self.release(connection: value, releaseOperation)
        }
        return try await operation(value)
    }
}
