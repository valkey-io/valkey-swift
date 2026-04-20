//
// This source file is part of the valkey-swift project
// Copyright (c) 2025-2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import Testing

@testable import _ValkeyConnectionPool

/// Simple Sendable token used in place of `CheckedContinuation` so we can
/// observe timer cancellation flow in unit tests without going through the
/// Swift concurrency runtime.
struct TestTimerCancellationToken: Sendable, Equatable, Hashable {
    let id: Int
}

final class TestPooledConnection: PooledConnection, @unchecked Sendable {
    typealias ID = Int
    let id: Int
    init(id: Int) { self.id = id }
    func onClose(_ closure: @escaping @Sendable ((any Error)?) -> Void) {}
    func close() {}
}

final class TestConnectionRequest: ConnectionRequestProtocol, @unchecked Sendable {
    typealias ID = Int
    typealias Connection = TestPooledConnection
    let id: Int
    init(id: Int) { self.id = id }
    func complete(with: Result<ConnectionLease<TestPooledConnection>, ConnectionPoolError>) {}
}

@Suite("Idle timer reschedule")
struct IdleTimerRescheduleTests {
    typealias StateMachine = PoolStateMachine<
        TestPooledConnection,
        ConnectionIDGenerator,
        Int,
        TestConnectionRequest,
        Int,
        TestTimerCancellationToken,
        ContinuousClock,
        ContinuousClock.Instant
    >

    /// When the idle-timeout timer fires while a request is waiting in the queue, the state
    /// machine reschedules a new idle timer for the connection. Before the fix this code path
    /// dropped the old idle timer's `cancellationContinuation` on the floor, which later
    /// triggered a "SWIFT TASK CONTINUATION MISUSE: runTimer(_:in:) leaked its continuation
    /// without resuming it" runtime warning because the continuation stored in
    /// `ConnectionPool.runTimer`'s child task was never resumed.
    ///
    /// This test drives the state machine into that exact scenario and asserts that the
    /// `.timerTriggered` action propagates the old idle timer's cancellation token so the
    /// caller can resume its continuation.
    @Test
    func reschedulingIdleTimerReturnsOldCancellationToken() {
        var config = PoolConfiguration()
        config.minimumConnectionCount = 0
        config.maximumConnectionSoftLimit = 1
        config.maximumConnectionHardLimit = 1
        config.keepAliveDuration = .seconds(30)
        config.idleTimeoutDuration = .seconds(60)

        var sm = StateMachine(
            configuration: config,
            generator: ConnectionIDGenerator(),
            timerCancellationTokenType: TestTimerCancellationToken.self,
            clock: ContinuousClock()
        )

        // 1. Leasing a request when no connection exists triggers creation of a demand
        //    connection.
        let firstRequest = TestConnectionRequest(id: 1)
        let leaseAction = sm.leaseConnection(firstRequest)
        guard case .makeConnection(let makeRequest, _) = leaseAction.connection else {
            Issue.record("expected .makeConnection, got \(leaseAction.connection)")
            return
        }

        // 2. Establish the connection. Because the request is already queued, the state
        //    machine leases it immediately.
        let connection = TestPooledConnection(id: makeRequest.connectionID)
        let established = sm.connectionEstablished(connection, maxStreams: 1)
        guard case .leaseConnection(_, _) = established.request else {
            Issue.record("expected lease, got \(established.request)")
            return
        }

        // 3. Release the connection so it parks with both keep-alive and idle timers.
        let released = sm.releaseConnection(connection, streams: 1)
        guard case .scheduleTimers(let parkedTimers) = released.connection else {
            Issue.record("expected .scheduleTimers, got \(released.connection)")
            return
        }
        var keepAliveTimer: StateMachine.Timer?
        var idleTimer: StateMachine.Timer?
        for timer in parkedTimers {
            switch timer.underlying.usecase {
            case .keepAlive: keepAliveTimer = timer
            case .idleTimeout: idleTimer = timer
            case .backoff: Issue.record("unexpected backoff timer")
            }
        }
        guard let keepAliveTimer, let idleTimer else {
            Issue.record("missing keep-alive or idle timer in \(parkedTimers)")
            return
        }

        // 4. Register cancellation tokens for both timers (simulates the child task in
        //    `ConnectionPool.runTimer` storing its continuation via `timerScheduled`).
        let keepAliveToken = TestTimerCancellationToken(id: 100)
        let idleToken = TestTimerCancellationToken(id: 200)
        #expect(sm.timerScheduled(keepAliveTimer, cancelContinuation: keepAliveToken) == nil)
        #expect(sm.timerScheduled(idleTimer, cancelContinuation: idleToken) == nil)

        // 5. Keep-alive fires → state transitions to `.idle(keepAlive: .running, idleTimer: .some)`.
        //    The keep-alive's own token is handed back via `.runKeepAlive` so it can be
        //    resumed - this path already works correctly.
        let keepAliveFired = sm.timerTriggered(keepAliveTimer)
        guard case .runKeepAlive(_, let handedBackKeepAliveToken) = keepAliveFired.connection else {
            Issue.record("expected .runKeepAlive, got \(keepAliveFired.connection)")
            return
        }
        #expect(handedBackKeepAliveToken == keepAliveToken)

        // 6. Queue a second request. Because the running keep-alive consumes the single
        //    available stream, this request stays in the queue.
        let secondRequest = TestConnectionRequest(id: 2)
        _ = sm.leaseConnection(secondRequest)

        // 7. The idle timer now fires. Because the request queue is non-empty the state
        //    machine takes the `rescheduleIdleTimer` path: it replaces the old idle timer
        //    with a fresh one and emits a `.scheduleTimers` action for the new timer.
        //
        //    BUG: without the fix the action drops `idleToken` on the floor. The token
        //    stays stored inside the dropped `State.Timer` and its `CheckedContinuation`
        //    in the real pool is never resumed, producing the runtime warning.
        //
        //    FIX: the action should also carry `idleToken` so the caller can resume it.
        let idleFired = sm.timerTriggered(idleTimer)

        let collectedCancelledTokens = collectCancelledTokens(idleFired.connection)
        #expect(
            collectedCancelledTokens.contains(idleToken),
            "rescheduling the idle timer must surface the old idle timer's cancellation token so the pool can resume its continuation. Got action: \(idleFired.connection)"
        )
    }

    private func collectCancelledTokens(
        _ action: StateMachine.ConnectionAction
    ) -> [TestTimerCancellationToken] {
        switch action {
        case .scheduleTimers:
            return []
        case .makeConnection(_, let tokens):
            return Array(tokens)
        case .makeConnectionsCancelAndScheduleTimers(_, let tokens, _):
            return Array(tokens)
        case .runKeepAlive(_, let token):
            return token.map { [$0] } ?? []
        case .cancelTimers(let tokens):
            return Array(tokens)
        case .closeConnection(_, let tokens):
            return Array(tokens)
        case .initiateShutdown(let shutdown):
            return shutdown.timersToCancel
        case .cancelEventStreamAndFinalCleanup(let tokens):
            return tokens
        case .none:
            return []
        }
    }
}
