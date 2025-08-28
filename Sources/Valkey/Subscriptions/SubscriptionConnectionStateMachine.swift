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
    /// - Parameters:
    ///   - isolation: Actor isolation
    ///   - operation: Closure to run with subscription connection
    @usableFromInline
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

        defer {
            self.releaseSubscriptionConnection(id: id)
        }
        return try await operation(connection)
    }

    func leaseSubscriptionConnection(id: Int, request: CheckedContinuation<ValkeyConnection, Error>) {
        self.logger.trace("Get subscription connection", metadata: ["valkey_subscription_connection_id": .stringConvertible(id)])
        enum LeaseAction {
            case cancel
            case action(ConnectionStateMachine.GetAction)
        }
        let action: LeaseAction = self.subscriptionConnectionStateMachine.withLock { stateMachine in
            if Task.isCancelled {
                return .cancel
            }
            return .action(stateMachine.get(id: id, request: request))
        }
        switch action {
        case .cancel:
            request.resume(throwing: CancellationError())
        case .action(let getAction):
            switch getAction {
            case .startAcquire(let leaseID):
                self.queueAction(.leaseSubscriptionConnection(leaseID: leaseID))
            case .completeRequest(let connection):
                request.resume(returning: connection)
            case .doNothing:
                break
            }
        }
    }

    func acquiredSubscriptionConnection(leaseID: Int, connection: ValkeyConnection, releaseContinuation: CheckedContinuation<Void, Never>) {
        let action = self.subscriptionConnectionStateMachine.withLock { stateMachine in
            stateMachine.acquired(leaseID: leaseID, value: connection, releaseRequest: releaseContinuation)
        }
        switch action {
        case .yield(let continuations):
            for cont in continuations {
                cont.resume(returning: connection)
            }
        case .release:
            releaseContinuation.resume()
        }

    }

    func errorAcquiringSubscriptionConnection(leaseID: Int, error: Error) {
        let action = self.subscriptionConnectionStateMachine.withLock { stateMachine in
            stateMachine.errorAcquiring(leaseID: leaseID, error: error)
        }
        switch action {
        case .yield(let continuations):
            for cont in continuations {
                cont.resume(throwing: error)
            }
        case .doNothing:
            break
        }

    }

    func releaseSubscriptionConnection(id: Int) {
        self.logger.trace("Release subscription connection", metadata: ["valkey_subscription_connection_id": .stringConvertible(id)])
        let action = self.subscriptionConnectionStateMachine.withLock { stateMachine in
            stateMachine.release(id: id)
        }
        switch action {
        case .release(let continuation):
            continuation.resume()
            self.logger.trace("Released connection for subscriptions")
        case .doNothing:
            break
        }

    }

    func cancelSubscriptionConnection(id: Int) {
        self.logger.trace("Cancel subscription connection", metadata: ["valkey_subscription_connection_id": .stringConvertible(id)])
        let action = self.subscriptionConnectionStateMachine.withLock { stateMachine in
            stateMachine.cancel(id: id)
        }
        switch action {
        case .cancel(let cont):
            cont.resume(throwing: CancellationError())
        case .release(let continuation):
            continuation.resume()
            self.logger.trace("Released connection for subscriptions")
        case .doNothing:
            break
        }
    }
}

/// StateMachine for acquiring Subscription Connection.
@usableFromInline
struct SubscriptionConnectionStateMachine<Value, Request, ReleaseRequest>: ~Copyable {
    enum State: ~Copyable {
        /// We have no connection
        case uninitialized(nextLeaseID: Int)
        /// We are acquiring a connection
        case acquiring(leaseID: Int, waiters: [Int: Request])
        /// We have a connection
        case acquired(AcquiredState)

        struct AcquiredState {
            var leaseID: Int
            var value: Value
            var requestIDs: Set<Int>
            var releaseRequest: ReleaseRequest
        }
    }
    var state: State

    init() {
        self.state = .uninitialized(nextLeaseID: 0)
    }

    init(state: consuming State) {
        self.state = state
    }

    enum GetAction {
        case startAcquire(Int)
        case doNothing
        case completeRequest(Value)
    }

    mutating func get(id: Int, request: Request) -> GetAction {
        switch consume self.state {
        case .uninitialized(let leaseID):
            self = .acquiring(leaseID: leaseID, waiters: [id: request])
            return .startAcquire(leaseID)
        case .acquiring(let leaseID, var waiters):
            waiters[id] = request
            self = .acquiring(leaseID: leaseID, waiters: waiters)
            return .doNothing
        case .acquired(var state):
            state.requestIDs.insert(id)
            self = .acquired(state)
            return .completeRequest(state.value)
        }
    }

    enum CancelAction {
        case cancel(Request)
        case release(ReleaseRequest)
        case doNothing
    }

    mutating func cancel(id: Int) -> CancelAction {
        switch consume self.state {
        case .uninitialized(let leaseID):
            self = .uninitialized(nextLeaseID: leaseID)
            return .doNothing
        case .acquiring(let leaseID, var waiters):
            guard let continuation = waiters.removeValue(forKey: id) else {
                self = .acquiring(leaseID: leaseID, waiters: waiters)
                return .doNothing
            }
            if waiters.isEmpty {
                self = .uninitialized(nextLeaseID: leaseID + 1)
            } else {
                self = .acquiring(leaseID: leaseID, waiters: waiters)
            }
            return .cancel(continuation)
        case .acquired(var state):
            state.requestIDs.remove(id)
            if state.requestIDs.isEmpty {
                self = .uninitialized(nextLeaseID: state.leaseID + 1)
                return .release(state.releaseRequest)
            } else {
                self = .acquired(state)
                return .doNothing
            }
        }
    }

    enum AcquiredAction {
        case yield([Request])
        case release
    }

    mutating func acquired(leaseID: Int, value: Value, releaseRequest: ReleaseRequest) -> AcquiredAction {
        switch consume self.state {
        case .uninitialized(let leaseID):
            self = .uninitialized(nextLeaseID: leaseID)
            return .release
        case .acquiring(let storedLeaseID, let waiters):
            if storedLeaseID != leaseID {
                self = .acquiring(leaseID: storedLeaseID, waiters: waiters)
                return .release
            }
            let continuations = waiters.values
            self = .acquired(.init(leaseID: leaseID, value: value, requestIDs: .init(waiters.keys), releaseRequest: releaseRequest))
            return .yield(.init(continuations))
        case .acquired(let state):
            if state.leaseID != leaseID {
                self = .acquired(state)
                return .release
            } else {
                preconditionFailure("Acquired connection twice")
            }
        }
    }

    enum ErrorAcquiringAction {
        case yield([Request])
        case doNothing
    }

    mutating func errorAcquiring(leaseID: Int, error: Error) -> ErrorAcquiringAction {
        switch consume self.state {
        case .uninitialized(let leaseID):
            self = .uninitialized(nextLeaseID: leaseID)
            return .doNothing
        case .acquiring(let storedLeaseID, let waiters):
            if storedLeaseID != leaseID {
                self = .acquiring(leaseID: storedLeaseID, waiters: waiters)
                return .doNothing
            }
            let continuations = waiters.values
            self = .uninitialized(nextLeaseID: leaseID + 1)
            return .yield(.init(continuations))
        case .acquired(let state):
            if state.leaseID != leaseID {
                self = .acquired(state)
                return .doNothing
            } else {
                preconditionFailure("Error acquiring connection we already have")
            }
        }
    }

    enum ReleaseAction {
        case release(ReleaseRequest)
        case doNothing
    }

    mutating func release(id: Int) -> ReleaseAction {
        switch consume self.state {
        case .uninitialized:
            preconditionFailure("Cannot release connection when in an uninitialized state")
        case .acquiring:
            preconditionFailure("Cannot release connection while acquiring a new connection")
        case .acquired(var state):
            state.requestIDs.remove(id)
            if state.requestIDs.isEmpty {
                self = .uninitialized(nextLeaseID: state.leaseID + 1)
                return .release(state.releaseRequest)
            } else {
                self = .acquired(state)
                return .doNothing
            }
        }
    }

    static private func uninitialized(nextLeaseID: Int) -> Self { .init(state: .uninitialized(nextLeaseID: nextLeaseID)) }
    static private func acquiring(leaseID: Int, waiters: [Int: Request]) -> Self { .init(state: .acquiring(leaseID: leaseID, waiters: waiters)) }
    static private func acquired(_ state: State.AcquiredState) -> Self { .init(state: .acquired(state)) }
}
