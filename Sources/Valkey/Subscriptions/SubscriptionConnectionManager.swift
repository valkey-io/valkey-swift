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
    }
    let stateMachine: Mutex<StateMachine>
    let requestStream: AsyncStream<Request>
    let requestStreamContinuation: AsyncStream<Request>.Continuation

    init() {
        (self.requestStream, self.requestStreamContinuation) = AsyncStream.makeStream()
        self.stateMachine = .init(.init())
    }

    func run(client: ValkeyClient) async {
        await withDiscardingTaskGroup { group in
            for await event in requestStream {
                switch event {
                case .get(let id, let continuation):
                    self.stateMachine.withLock { stateMachine in
                        switch stateMachine.get(id: id, continuation: continuation) {
                        case .startAcquire:
                            group.addTask {
                                await self.acquire(client: client)
                            }
                        case .doNothing:
                            break
                        }

                    }
                case .release(let id):
                    self.stateMachine.withLock { stateMachine in
                        switch stateMachine.releaseConnection(id: id) {
                        case .releaseConnection(let connection):
                            client.node.connectionPool.releaseConnection(connection)
                        case .doNothing:
                            break
                        }
                    }
                    break
                case .cancel(let id):
                    self.stateMachine.withLock { stateMachine in
                        switch stateMachine.cancel(id: id) {
                        case .cancel(let cont):
                            cont.resume(throwing: CancellationError())
                        case .releaseConnection(let connection):
                            client.node.connectionPool.releaseConnection(connection)
                        case .doNothing:
                            break
                        }
                    }
                }
            }
        }
    }

    @usableFromInline
    func withConnection(_ operation: (ValkeyConnection) async throws -> Void) async throws {
        let id = Int.random(in: .min ... .max)

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
        try await operation(connection)
    }

    private func acquire(client: ValkeyClient) async {
        let result: Result<ValkeyConnection, Error>
        do {
            result = .success(try await client.node.connectionPool.leaseConnection())
        } catch {
            result = .failure(error)
        }
        self.stateMachine.withLock { stateMachine in
            switch stateMachine.acquired(connectionResult: result) {
            case .yield(let continuations):
                for cont in continuations {
                    cont.resume(with: result)
                }
            case .doNothing:
                break
            }
        }
    }

    struct StateMachine {
        enum State {
            case uninitialized
            case acquiring([Int: CheckedContinuation<ValkeyConnection, Error>])
            case using(ValkeyConnection, Set<Int>)
        }
        var state: State

        init() {
            self.state = .uninitialized
        }

        enum GetAction {
            case startAcquire
            case doNothing
        }

        mutating func get(id: Int, continuation: CheckedContinuation<ValkeyConnection, Error>) -> GetAction {
            switch self.state {
            case .uninitialized:
                self.state = .acquiring([id: continuation])
                return .startAcquire
            case .acquiring(var map):
                map[id] = continuation
                self.state = .acquiring(map)
                return .doNothing
            case .using(let connection, var ids):
                ids.insert(id)
                self.state = .using(connection, ids)
                return .doNothing
            }
        }

        enum CancelAction {
            case cancel(CheckedContinuation<ValkeyConnection, Error>)
            case releaseConnection(ValkeyConnection)
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
            case .using(let connection, var ids):
                ids.remove(id)
                if ids.isEmpty {
                    self.state = .uninitialized
                    return .releaseConnection(connection)
                } else {
                    self.state = .using(connection, ids)
                    return .doNothing
                }
            }
        }

        enum AcquiredAction {
            case yield([CheckedContinuation<ValkeyConnection, Error>])
            case doNothing
        }

        mutating func acquired(connectionResult: Result<ValkeyConnection, Error>) -> AcquiredAction {
            switch self.state {
            case .uninitialized:
                return .doNothing
            case .acquiring(let map):
                let continuations = map.values
                switch connectionResult {
                case .success(let connection):
                    self.state = .using(connection, .init(map.keys))
                case .failure:
                    self.state = .uninitialized
                }
                return .yield(.init(continuations))
            case .using:
                fatalError()
            }
        }

        enum ReleaseAction {
            case releaseConnection(ValkeyConnection)
            case doNothing
        }

        mutating func releaseConnection(id: Int) -> ReleaseAction {
            switch self.state {
            case .uninitialized:
                fatalError()
            case .acquiring:
                fatalError()
            case .using(let connection, var ids):
                ids.remove(id)
                if ids.isEmpty {
                    self.state = .uninitialized
                    return .releaseConnection(connection)
                } else {
                    self.state = .using(connection, ids)
                    return .doNothing
                }
            }
        }
    }
}
