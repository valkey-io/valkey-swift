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

/// Stores a reference to a single instance of a type that is initialized asynchronously
///
/// It ensures only ever one version of the object is initialized, even if it requested
/// twice during initialization. Once it is available the object includes a reference count
/// so we can clean it up once nobody references it.
@available(valkeySwift 1.0, *)
@usableFromInline
struct AsyncInitializedReferencedObject<Value: Sendable & Identifiable>: ~Copyable, Sendable {
    @usableFromInline
    enum Action {
        case use(Value)
        case acquire
    }

    @usableFromInline
    enum State {
        case uninitialized
        case acquiring([CheckedContinuation<Action, any Error>])
        case available(Value, Int)
    }
    @usableFromInline
    let state: Mutex<State>

    init() {
        self.state = .init(.uninitialized)
    }

    @inlinable
    func acquire(isolation: isolated (any Actor)? = #isolation, _ operation: () async throws -> Value) async throws -> Value {
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

    @inlinable
    func release(id: Value.ID, _ operation: (Value) -> Void) {
        self.state.withLock { state in
            switch state {
            case .uninitialized, .acquiring:
                break
            case .available(let connection, let count):
                guard connection.id == id else { return }
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
    func withValue<Returning>(
        isolation: isolated (any Actor)? = #isolation,
        _ operation: (Value) async throws -> sending Returning,
        acquire acquireOperation: () async throws -> Value,
        release releaseOperation: (Value) -> Void
    ) async throws -> sending Returning {
        let value = try await self.acquire(acquireOperation)
        defer {
            self.release(id: value.id, releaseOperation)
        }
        return try await operation(value)
    }

    @usableFromInline
    func reset() {
        self.state.withLock { $0 = .uninitialized }
    }
}
