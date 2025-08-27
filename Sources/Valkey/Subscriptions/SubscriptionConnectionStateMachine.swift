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

@available(valkeySwift 1.0, *)
extension ValkeyClient {
    /// Run operation with the valkey subscription connection
    ///
    /// - Parameter operation: Closure to run with subscription connection
    @usableFromInline
    func withSubscriptionConnection<Value>(
        isolation: isolated (any Actor)? = #isolation,
        _ operation: (ValkeyConnection) async throws -> sending Value
    ) async throws -> sending Value {
        let id = self.subscriptionConnectionIDGenerator.next()

        let connection = try await withTaskCancellationHandler {
            if Task.isCancelled {
                throw CancellationError()
            }
            return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<ValkeyConnection, Error>) in
                self.leaseSubscriptionConnection(id: id, request: cont)
            }
        } onCancel: {
            self.cancelSubscriptionConnection(id: id)
        }

        defer {
            self.releaseSubscriptionConnection(id: id)
        }
        return try await operation(connection)
    }

    func leaseSubscriptionConnection(id: Int, request: CheckedContinuation<ValkeyConnection, Error>) {
        self.logger.trace("Get subscription connection", metadata: ["valkey_subscription_connection_id": .stringConvertible(id)])
        self.subscriptionConnectionStateMachine.withLock { stateMachine in
            switch stateMachine.get(id: id, request: request) {
            case .startAcquire:
                self.queueAction(.leaseSubscriptionConnection)
            case .completeRequest(let connection):
                request.resume(returning: connection)
            case .doNothing:
                break
            }
        }
    }

    func acquiredSubscriptionConnection(_ result: Result<ValkeyConnection, Error>) {
        self.subscriptionConnectionStateMachine.withLock { stateMachine in
            switch stateMachine.acquired(result: result) {
            case .yield(let continuations):
                for cont in continuations {
                    cont.resume(with: result)
                }
            case .release(let connection):
                self.node.connectionPool.releaseConnection(connection)
            case .doNothing:
                break
            }
        }
    }

    func releaseSubscriptionConnection(id: Int) {
        self.logger.trace("Release subscription connection", metadata: ["valkey_subscription_connection_id": .stringConvertible(id)])
        self.subscriptionConnectionStateMachine.withLock { stateMachine in
            switch stateMachine.release(id: id) {
            case .release(let connection):
                self.node.connectionPool.releaseConnection(connection)
                self.logger.trace("Released connection for subscriptions")
            case .doNothing:
                break
            }
        }
    }

    func cancelSubscriptionConnection(id: Int) {
        self.logger.trace("Cancel subscription connection", metadata: ["valkey_subscription_connection_id": .stringConvertible(id)])
        self.subscriptionConnectionStateMachine.withLock { stateMachine in
            switch stateMachine.cancel(id: id) {
            case .cancel(let cont):
                cont.resume(throwing: CancellationError())
            case .release(let connection):
                self.node.connectionPool.releaseConnection(connection)
                self.logger.trace("Released connection for subscriptions")
            case .doNothing:
                break
            }
        }
    }
}

/// StateMachine for acquiring Subscription Connection.
@usableFromInline
struct SubscriptionConnectionStateMachine<Value, Request>: ~Copyable {
    enum State: ~Copyable {
        /// We have no connection
        case uninitialized
        /// We are acquiring a connection
        case acquiring([Int: Request])
        /// We have a connection
        case acquired(Value, Set<Int>)
    }
    var state: State

    init() {
        self.state = .uninitialized
    }

    init(state: consuming State) {
        self.state = state
    }

    enum GetAction {
        case startAcquire
        case doNothing
        case completeRequest(Value)
    }

    mutating func get(id: Int, request: Request) -> GetAction {
        switch consume self.state {
        case .uninitialized:
            self = .acquiring([id: request])
            return .startAcquire
        case .acquiring(var map):
            map[id] = request
            self = .acquiring(map)
            return .doNothing
        case .acquired(let connection, var ids):
            ids.insert(id)
            self = .acquired(connection, ids)
            return .completeRequest(connection)
        }
    }

    enum CancelAction {
        case cancel(Request)
        case release(Value)
        case doNothing
    }

    mutating func cancel(id: Int) -> CancelAction {
        switch consume self.state {
        case .uninitialized:
            self = .uninitialized
            return .doNothing
        case .acquiring(var map):
            guard let continuation = map.removeValue(forKey: id) else {
                self = .acquiring(map)
                return .doNothing
            }
            if map.isEmpty {
                self = .uninitialized
            } else {
                self = .acquiring(map)
            }
            return .cancel(continuation)
        case .acquired(let connection, var ids):
            ids.remove(id)
            if ids.isEmpty {
                self = .uninitialized
                return .release(connection)
            } else {
                self = .acquired(connection, ids)
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
        switch consume self.state {
        case .uninitialized:
            self = .uninitialized
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
                self = .acquired(connection, .init(map.keys))
            case .failure:
                self = .uninitialized
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
        switch consume self.state {
        case .uninitialized:
            fatalError()
        case .acquiring:
            fatalError()
        case .acquired(let connection, var ids):
            ids.remove(id)
            if ids.isEmpty {
                self = .uninitialized
                return .release(connection)
            } else {
                self = .acquired(connection, ids)
                return .doNothing
            }
        }
    }

    static var uninitialized: Self { .init(state: .uninitialized) }
    static func acquiring(_ map: [Int: Request]) -> Self { .init(state: .acquiring(map)) }
    static func acquired(_ value: Value, _ ids: Set<Int>) -> Self { .init(state: .acquired(value, ids)) }
}
/*
@available(valkeySwift 1.0, *)
extension SubscriptionConnectionManager.StateMachine {
    static var uninitialized: Self { .init(state: .uninitialized) }
    static func acquiring(_ map: [Int: Request]) -> Self { .init(state: .acquiring(map)) }
    static func acquired(_ value: Value, _ ids: Set<Int>) -> Self { .init(state: .acquired(value, ids)) }
}*/
