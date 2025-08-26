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

import Logging
import Synchronization
import _ValkeyConnectionPool

/// Stores a reference to a single connection to be used by client for subscriptions
///
/// It ensures only ever one version of the connection is initialized, even if it requested
/// twice during initialization. Once it is available the object includes a reference count
/// so we can clean it up once nobody references it.
@available(valkeySwift 1.0, *)
@usableFromInline
final class SubscriptionConnectionManager: Sendable {
    enum Request {
        case get(Int, CheckedContinuation<ValkeyConnection, Error>)
        case release(Int)
        case cancel(Int)
        case close
    }
    let stateMachine: Mutex<StateMachine<ValkeyConnection, CheckedContinuation<ValkeyConnection, Error>>>
    let connectionIDGenerator: ConnectionIDGenerator
    let logger: Logger
    let requestStream: AsyncStream<Request>
    let requestStreamContinuation: AsyncStream<Request>.Continuation

    init(logger: Logger) {
        self.logger = logger
        (self.requestStream, self.requestStreamContinuation) = AsyncStream.makeStream()
        self.stateMachine = .init(.init())
        self.connectionIDGenerator = .init()
    }

    func run(client: ValkeyClient) async {
        await self.run(
            acquire: { try await client.node.connectionPool.leaseConnection() },
            release: { client.node.connectionPool.releaseConnection($0) }
        )
    }

    func run(acquire: @escaping @Sendable () async throws -> ValkeyConnection, release: @escaping @Sendable (ValkeyConnection) -> Void) async {
        await withDiscardingTaskGroup { group in
            for await event in requestStream {
                switch event {
                case .get(let id, let continuation):
                    self.logger.trace("Get subscription connection", metadata: ["valkey_subscription_connection_id": .stringConvertible(id)])
                    self.stateMachine.withLock { stateMachine in
                        switch stateMachine.get(id: id, request: continuation) {
                        case .startAcquire:
                            group.addTask {
                                await self.runAcquire(acquire: acquire, release: release)
                            }
                        case .completeRequest(let connection):
                            continuation.resume(returning: connection)
                        case .doNothing:
                            break
                        }

                    }
                case .release(let id):
                    self.logger.trace("Release subscription connection", metadata: ["valkey_subscription_connection_id": .stringConvertible(id)])
                    self.stateMachine.withLock { stateMachine in
                        switch stateMachine.release(id: id) {
                        case .release(let connection):
                            release(connection)
                            self.logger.trace("Released connection for subscriptions")
                        case .doNothing:
                            break
                        }
                    }
                    break
                case .cancel(let id):
                    self.logger.trace("Cancel subscription connection", metadata: ["valkey_subscription_connection_id": .stringConvertible(id)])
                    self.stateMachine.withLock { stateMachine in
                        switch stateMachine.cancel(id: id) {
                        case .cancel(let cont):
                            cont.resume(throwing: CancellationError())
                        case .release(let connection):
                            release(connection)
                            self.logger.trace("Released connection for subscriptions")
                        case .doNothing:
                            break
                        }
                    }
                case .close:
                    return
                }
            }
        }
    }

    /// Run operation with the valkey subscription connection
    ///
    /// - Parameter operation: Closure to run with subscription connection
    @usableFromInline
    func withConnection<Value>(_ operation: (ValkeyConnection) async throws -> Value) async throws -> Value {
        let id = self.connectionIDGenerator.next()

        let connection = try await withTaskCancellationHandler {
            if Task.isCancelled {
                throw CancellationError()
            }
            return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<ValkeyConnection, Error>) in
                self.requestStreamContinuation.yield(.get(id, cont))
            }
        } onCancel: {
            self.requestStreamContinuation.yield(.cancel(id))
        }

        defer {
            self.requestStreamContinuation.yield(.release(id))
        }
        return try await operation(connection)
    }

    func shutdown() {
        self.requestStreamContinuation.yield(.close)
    }

    private func runAcquire(
        acquire: @escaping @Sendable () async throws -> ValkeyConnection,
        release: @escaping @Sendable (ValkeyConnection) -> Void
    ) async {
        let result: Result<ValkeyConnection, Error>
        do {
            let connection = try await acquire()
            result = .success(connection)
            self.logger.trace("Acquired connection for subscriptions")
        } catch {
            result = .failure(error)
        }
        self.stateMachine.withLock { stateMachine in
            switch stateMachine.acquired(result: result) {
            case .yield(let continuations):
                for cont in continuations {
                    cont.resume(with: result)
                }
            case .release(let connection):
                release(connection)
            case .doNothing:
                break
            }
        }
    }

    struct StateMachine<Value, Request> {
        enum State {
            case uninitialized
            case acquiring([Int: Request])
            case acquired(Value, Set<Int>)
        }
        var state: State

        init() {
            self.state = .uninitialized
        }

        enum GetAction {
            case startAcquire
            case doNothing
            case completeRequest(Value)
        }

        mutating func get(id: Int, request: Request) -> GetAction {
            switch self.state {
            case .uninitialized:
                self.state = .acquiring([id: request])
                return .startAcquire
            case .acquiring(var map):
                map[id] = request
                self.state = .acquiring(map)
                return .doNothing
            case .acquired(let connection, var ids):
                ids.insert(id)
                self.state = .acquired(connection, ids)
                return .completeRequest(connection)
            }
        }

        enum CancelAction {
            case cancel(Request)
            case release(Value)
            case doNothing
        }

        mutating func cancel(id: Int) -> CancelAction {
            switch self.state {
            case .uninitialized:
                return .doNothing
            case .acquiring(var map):
                guard let continuation = map.removeValue(forKey: id) else {
                    return .doNothing
                }
                if map.isEmpty {
                    self.state = .uninitialized
                } else {
                    self.state = .acquiring(map)
                }
                return .cancel(continuation)
            case .acquired(let connection, var ids):
                ids.remove(id)
                if ids.isEmpty {
                    self.state = .uninitialized
                    return .release(connection)
                } else {
                    self.state = .acquired(connection, ids)
                    return .doNothing
                }
            }
        }

        enum AcquiredAction {
            case yield([Request])
            case release(Value)
            case doNothing
        }

        mutating func acquired(result: Result<Value, Error>) -> AcquiredAction {
            switch self.state {
            case .uninitialized:
                switch result {
                case .success(let value):
                    return .release(value)
                case .failure:
                    return .doNothing
                }
            case .acquiring(let map):
                let continuations = map.values
                switch result {
                case .success(let connection):
                    self.state = .acquired(connection, .init(map.keys))
                case .failure:
                    self.state = .uninitialized
                }
                return .yield(.init(continuations))
            case .acquired:
                fatalError()
            }
        }

        enum ReleaseAction {
            case release(Value)
            case doNothing
        }

        mutating func release(id: Int) -> ReleaseAction {
            switch self.state {
            case .uninitialized:
                fatalError()
            case .acquiring:
                fatalError()
            case .acquired(let connection, var ids):
                ids.remove(id)
                if ids.isEmpty {
                    self.state = .uninitialized
                    return .release(connection)
                } else {
                    self.state = .acquired(connection, ids)
                    return .doNothing
                }
            }
        }
    }
}
