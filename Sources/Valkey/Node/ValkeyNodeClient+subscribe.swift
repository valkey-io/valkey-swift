//
//  ValkeyNodeClient+subscribe.swift
//  valkey-swift
//
//  Created by Fabian Fett on 26.08.25.
//

@available(valkeySwift 1.0, *)
extension ValkeyNodeClient {

    func withSubscriptionConnection<Value>(
        _ body: (ValkeyConnection) async throws -> sending Value
    ) async throws -> sending Value {
        let connection = try await self.leaseSubscriptionConnection()
        defer { self.releaseSubscriptionConnection(connection) }
        return try await body(connection)
    }

    private func leaseSubscriptionConnection() async throws -> ValkeyConnection {
        let requestID = self.requestIDGenerator.next()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ValkeyConnection, any Error>) in
                let leaseAction = self.subscriptionConnectionLock.withLock {
                    $0.lease(requestID: requestID, continuation: continuation)
                }

                switch leaseAction {
                case .nothing:
                    break

                case .use(let connection):
                    continuation.resume(returning: connection)

                case .startLease(let leaseID):
                    self.clientActionContinuation.yield(.leaseSubscriptionConnection(leaseID: leaseID))
                }
            }
        } onCancel: {
            // TODO: Add cancellation for leasing the connection
        }
    }

    func releaseSubscriptionConnection(_ connection: ValkeyConnection) {
        let action = self.subscriptionConnectionLock.withLock {
            $0.connectionReleased(connection)
        }

        switch action {
        case .nothing:
            break

        case .releaseConnection(let checkedContinuation):
            checkedContinuation.resume()
        }
    }

    func leaseAndParkConnection(leaseID: Int) async {
        do {
            try await self.withConnection { connection in
                await withCheckedContinuation { (returnContinuation: CheckedContinuation<Void, Never>) in
                    let action = self.subscriptionConnectionLock.withLock {
                        $0.connectionLeased(
                            leaseID: leaseID,
                            valkeyConnection: connection,
                            returnContinuation: returnContinuation
                        )
                    }

                    connection.onClose { error in
                        // if the connection is closed while we have leased it
                        // we should clean up the state machine ASAP

                        // TODO: Release connection state and reset to initialized
                    }

                    switch action {
                    case .releaseConnection:
                        returnContinuation.resume()

                    case .succeedWaiters(let waiters):
                        for waiter in waiters {
                            waiter.resume(returning: connection)
                        }
                    }
                }
            }
        } catch {
            // TODO: Report that leasing a connection failed. Fail all waiters.
        }
    }
}

@available(valkeySwift 1.0, *)
struct ValkeyNodeClientSubscriptionConnectionStateMachine {

    enum State {
        case initialized(nextLeaseID: Int)
        case leasingConnection(leaseID: Int, waiters: [Int: CheckedContinuation<ValkeyConnection, any Error>])
        case leased(leaseID: Int, ValkeyConnection, leaseCount: Int, CheckedContinuation<Void, Never>)
    }

    var state: State = .initialized(nextLeaseID: 0)

    enum LeaseAction {
        case startLease(leaseID: Int)
        case nothing
        case use(ValkeyConnection)
    }

    mutating func lease(requestID: Int, continuation: CheckedContinuation<ValkeyConnection, any Error>) -> LeaseAction {
        switch self.state {
        case .initialized:
            self.state = .leasingConnection(leaseID: 0, waiters: [requestID: continuation])
            return .startLease(leaseID: 0)

        case .leasingConnection(let leaseID, var checkedContinuations):
            checkedContinuations[requestID] = continuation
            self.state = .leasingConnection(leaseID: leaseID, waiters: checkedContinuations)
            return .nothing

        case .leased(let leaseID, let valkeyConnection, let leaseCount, let returnContinuation):
            self.state = .leased(leaseID: leaseID, valkeyConnection, leaseCount: leaseCount + 1, returnContinuation)
            return .use(valkeyConnection)
        }
    }

    enum LeasedAction {
        case succeedWaiters([CheckedContinuation<ValkeyConnection, any Error>])
        case releaseConnection
    }

    mutating func connectionLeased(
        leaseID: Int,
        valkeyConnection: ValkeyConnection,
        returnContinuation: CheckedContinuation<Void, Never>
    ) -> LeasedAction {
        switch self.state {
        case .initialized:
            return .releaseConnection

        case .leasingConnection(let storedLeaseID, let waiters):
            guard storedLeaseID == leaseID else {
                return .releaseConnection
            }

            self.state = .leased(leaseID: leaseID, valkeyConnection, leaseCount: waiters.count, returnContinuation)
            return .succeedWaiters(Array(waiters.values))

        case .leased(let storedLeaseID, _, _, _):
            if storedLeaseID == leaseID {
                fatalError("Invalid state: \(self.state)")
            } else {
                return .releaseConnection
            }
        }
    }

    enum ReleasedAction {
        case nothing
        case releaseConnection(CheckedContinuation<Void, Never>)
    }

    mutating func connectionReleased(_ returnedConnection: ValkeyConnection) -> ReleasedAction {
        switch self.state {
        case .initialized:
            return .nothing

        case .leasingConnection:
            return .nothing

        case .leased(let storedLeaseID, let valkeyConnection, var leaseCount, let checkedContinuation):
            guard returnedConnection === valkeyConnection else {
                return .nothing
            }

            leaseCount -= 1
            if leaseCount == 0 {
                self.state = .initialized(nextLeaseID: storedLeaseID + 1)
                return .releaseConnection(checkedContinuation)
            } else {
                self.state = .leased(leaseID: storedLeaseID, valkeyConnection, leaseCount: leaseCount, checkedContinuation)
                return .nothing
            }
        }
    }
}
