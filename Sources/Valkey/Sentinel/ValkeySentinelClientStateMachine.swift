//
// This source file is part of the valkey-swift project
// Copyright (c) 2025-2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

@available(valkeySwift 1.0, *)
package struct ValkeySentinelTimer: Sendable, Hashable {
    package enum UseCase: Hashable {
        case nextDiscovery
    }

    package var useCase: UseCase
    package var duration: Duration
    package var timerID: Int

    package init(timerID: Int, useCase: UseCase, duration: Duration) {
        self.useCase = useCase
        self.timerID = timerID
        self.duration = duration
    }
}

@usableFromInline
@available(valkeySwift 1.0, *)
struct ValkeySentinelClientStateMachine<
    ConnectionPool: ValkeyNodeConnectionPool,
    ConnectionPoolFactory: ValkeyNodeConnectionPoolFactory,
    WaiterToken: Sendable,
    TimerCancellationToken: Sendable
>
where ConnectionPoolFactory.ConnectionPool == ConnectionPool, ConnectionPoolFactory.NodeDescription == ValkeyClusterNodeClientFactory.NodeDescription
{
    /// Configuration
    @usableFromInline
    struct Configuration {
        /// Default interval before we attempt to refresh the sentinel list, if the previous refresh was
        /// successful
        let defaultSentinelRefreshInterval: Duration = .seconds(30)
    }
    @usableFromInline
    struct Timer {
        var id: Int
        var cancellationToken: TimerCancellationToken?
    }
    /// current state
    @usableFromInline
    enum State {
        @usableFromInline
        struct UnavailableState {
            var waiters: [Int: WaiterToken]
            let error: ValkeyClientError?
        }
        @usableFromInline
        struct HealthyState {
            let nodes: ValkeySentinelNodeList
        }
        @usableFromInline
        struct DegradedState {
            let nodes: ValkeySentinelNodeList
        }
        case unavailable(UnavailableState)
        case degraded(DegradedState)
        case healthy(HealthyState)
        case shutdown
    }

    enum RefreshState {
        struct RefreshContext {
            var consecutiveFailures: Int
            var lastError: (any Error)?
        }

        case notRefreshing
        case refreshing(RefreshContext)
        case waitingForRefresh(Timer, previousRefresh: RefreshContext)
    }

    let configuration: Configuration
    @usableFromInline
    var state: State
    var refreshState: RefreshState
    @usableFromInline
    var runningClients: ValkeyRunningClientsStateMachine<ConnectionPool, ConnectionPoolFactory>

    private var _nextTimerID: Int = 0

    init(poolFactory: ConnectionPoolFactory, configuration: Configuration) {
        self.configuration = configuration
        self.state = .unavailable(.init(waiters: [:], error: nil))
        self.refreshState = .notRefreshing
        self.runningClients = .init(poolFactory: poolFactory)
    }

    mutating func start() {
        switch self.refreshState {
        case .notRefreshing:
            switch self.state {
            case .unavailable:
                self.refreshState = .refreshing(.init(consecutiveFailures: 0, lastError: nil))
            case .degraded, .healthy, .shutdown:
                preconditionFailure("Invalid state \(self.state)")
            }
        case .refreshing, .waitingForRefresh:
            preconditionFailure("Invalid refresh state \(self.refreshState)")
        }
    }

    /// Get initial list of voters for election process
    func getInitialVoters() -> [ValkeyTopologyVoter<ConnectionPool>] {
        switch self.state {
        case .unavailable, .shutdown:
            return []
        case .degraded(let degradedState):
            return degradedState.nodes.nodes.compactMap { (element) -> ValkeyTopologyVoter<ConnectionPool>? in
                self.runningClients[element.id].map { .init(client: $0.pool, nodeID: $0.nodeID) }
            }
        case .healthy(let healthyState):
            return healthyState.nodes.nodes.compactMap { (element) -> ValkeyTopologyVoter<ConnectionPool>? in
                self.runningClients[element.id].map { .init(client: $0.pool, nodeID: $0.nodeID) }
            }
        }
    }

    /// Get list of all sentinel clients
    func getSentinelClients() -> [ConnectionPool] {
        switch self.state {
        case .unavailable, .shutdown:
            return []
        case .degraded(let degradedState):
            return degradedState.nodes.nodes.compactMap { (element) -> ConnectionPool? in
                self.runningClients[element.id].map { $0.pool }
            }
        case .healthy(let healthyState):
            return healthyState.nodes.nodes.compactMap { (element) -> ConnectionPool? in
                self.runningClients[element.id].map { $0.pool }
            }
        }
    }

    struct UpdateNodesAction {
        let clientsToRun: [ConnectionPool]
        let clientsToShutdown: [ConnectionPool]
        let voters: [ValkeyTopologyVoter<ConnectionPool>]
    }
    /// Update list of sentinels during election process
    mutating func updateSentinelNodes(_ nodes: ValkeySentinelNodeList) -> UpdateNodesAction {
        let action = self.runningClients.updateNodes(nodes.nodes, removeUnmentionedPools: false)
        return .init(
            clientsToRun: action.poolsToRun.map { $0.0 },
            clientsToShutdown: action.poolsToShutdown,
            voters: action.poolsToRun.map { .init(client: $0.0, nodeID: $0.1) }
        )
    }

    struct DiscoverySucceededAction {
        internal init(
            waitersToSucceed: [WaiterToken] = [],
            clientsToRun: [ConnectionPool] = [],
            clientsToShutdown: [ConnectionPool] = [],
            timerToRun: ValkeySentinelTimer? = nil
        ) {
            self.waitersToSucceed = waitersToSucceed
            self.clientsToRun = clientsToRun
            self.clientsToShutdown = clientsToShutdown
            self.timerToRun = timerToRun
        }

        var waitersToSucceed: [WaiterToken]
        var clientsToRun: [ConnectionPool]
        var clientsToShutdown: [ConnectionPool]
        var timerToRun: ValkeySentinelTimer?
    }

    /// Topology successfully discovered, update state
    mutating func topologyDiscoverySucceeded(_ nodes: ValkeySentinelNodeList) -> DiscoverySucceededAction {
        switch self.refreshState {
        case .refreshing:
            break
        case .notRefreshing, .waitingForRefresh:
            preconditionFailure("Invalid refresh state \(self.refreshState)")
        }
        let refreshTimerID = self.nextTimerID()
        self.refreshState = .waitingForRefresh(.init(id: refreshTimerID), previousRefresh: .init(consecutiveFailures: 0))
        let updateAction = self.runningClients.updateNodes(nodes.nodes, removeUnmentionedPools: true)

        var action = DiscoverySucceededAction(
            waitersToSucceed: [],
            clientsToRun: updateAction.poolsToRun.map { $0.0 },
            clientsToShutdown: updateAction.poolsToShutdown,
            timerToRun: .init(timerID: refreshTimerID, useCase: .nextDiscovery, duration: self.configuration.defaultSentinelRefreshInterval)
        )
        switch self.state {
        case .unavailable(let unavailableState):
            self.state = .healthy(.init(nodes: nodes))
            action.waitersToSucceed = Array(unavailableState.waiters.values)
            return action

        case .degraded:
            self.state = .healthy(.init(nodes: nodes))
            return action

        case .healthy:
            self.state = .healthy(.init(nodes: nodes))
            return action

        case .shutdown:
            return .init()
        }
    }

    struct DiscoveryFailedAction {
        var waitersToFail: [WaiterToken]
        var timerToRun: ValkeySentinelTimer?
    }

    /// Topology discovery failed, update state and return waiters to fail
    mutating func topologyDiscoveryFailed(error: ValkeyClientError) -> DiscoveryFailedAction {
        switch self.refreshState {
        case .refreshing(var refreshContext):
            refreshContext.consecutiveFailures += 1
            refreshContext.lastError = error
            let refreshTimerID = self.nextTimerID()
            let waitTillNextTry = Self.calculateBackoff(failedAttempt: refreshContext.consecutiveFailures)
            self.refreshState = .waitingForRefresh(.init(id: refreshTimerID), previousRefresh: refreshContext)
            var action = DiscoveryFailedAction(
                waitersToFail: [],
                timerToRun: .init(timerID: refreshTimerID, useCase: .nextDiscovery, duration: waitTillNextTry)
            )

            switch self.state {
            case .unavailable(let unavailableState):
                self.state = .unavailable(.init(waiters: [:], error: error))
                action.waitersToFail = Array(unavailableState.waiters.values)
                return action
            case .degraded:
                return action

            case .healthy(let healthyState):
                self.state = .degraded(.init(nodes: healthyState.nodes))
                return action

            case .shutdown:
                return .init(waitersToFail: [], timerToRun: nil)
            }
        case .notRefreshing, .waitingForRefresh:
            preconditionFailure("Invalid refresh state \(self.refreshState)")
        }
    }

    enum WaitForDiscoveryAction {
        case complete
        case fail(ValkeyClientError)
        case doNothing
    }
    mutating func waitForDiscovery(waiterID: Int, successNotification: WaiterToken) -> WaitForDiscoveryAction {
        switch self.state {
        case .unavailable(var unavailableState):
            if let error = unavailableState.error {
                return .fail(error)
            } else {
                unavailableState.waiters[waiterID] = successNotification
                self.state = .unavailable(unavailableState)
                return .doNothing
            }
        case .degraded:
            return .complete
        case .healthy:
            return .complete
        case .shutdown:
            return .fail(.init(.clientIsShutDown))
        }
    }

    mutating func cancelWaitForDiscovery(waiterID: Int) -> WaiterToken? {
        switch self.state {
        case .unavailable(var unavailableState):
            let token = unavailableState.waiters.removeValue(forKey: waiterID)
            self.state = .unavailable(unavailableState)
            return token
        case .degraded:
            return nil
        case .healthy:
            return nil
        case .shutdown:
            return nil
        }
    }

    private mutating func nextTimerID() -> Int {
        defer { self._nextTimerID += 1 }
        return self._nextTimerID
    }

    package enum TimerFiredAction {
        package struct RunDiscovery {
            package var runNodeDiscoveryFirst: Bool

            package init(runNodeDiscoveryFirst: Bool) {
                self.runNodeDiscoveryFirst = runNodeDiscoveryFirst
            }
        }

        case runDiscovery(RunDiscovery)
        case doNothing
    }

    package mutating func timerFired(_ timer: ValkeySentinelTimer) -> TimerFiredAction {
        switch timer.useCase {
        case .nextDiscovery:
            let runNodeDiscoveryFirst: Bool
            switch self.state {
            case .shutdown:
                return .doNothing

            case .healthy:
                runNodeDiscoveryFirst = false

            case .degraded, .unavailable:
                runNodeDiscoveryFirst = true
            }

            switch self.refreshState {
            case .refreshing, .notRefreshing:
                // race condition. we are already refreshing
                return .doNothing

            case .waitingForRefresh(let storedTimer, let previousRefresh):
                guard storedTimer.id == timer.timerID else {
                    // race condition. the timer that fired isn't interesting anymore
                    return .doNothing
                }
                self.refreshState = .refreshing(previousRefresh)
                return .runDiscovery(.init(runNodeDiscoveryFirst: runNodeDiscoveryFirst))
            }
        }
    }

    package mutating func registerTimerCancellationToken(
        _ token: TimerCancellationToken,
        for timer: ValkeySentinelTimer
    ) -> TimerCancellationToken? {
        switch timer.useCase {
        case .nextDiscovery:
            switch self.refreshState {
            case .notRefreshing, .refreshing:
                return token

            case .waitingForRefresh(var timerState, let previousRefresh):
                if timerState.id == timer.timerID {
                    timerState.cancellationToken = token
                    self.refreshState = .waitingForRefresh(timerState, previousRefresh: previousRefresh)
                    return nil
                }
                return token
            }
        }
    }

    package mutating func shutdown() -> [ConnectionPool] {
        switch self.state {
        case .unavailable, .degraded, .healthy:
            self.state = .shutdown
            let existingNodes = self.runningClients
            self.runningClients.removeAll()
            return existingNodes.clients.lazy.map { $0.pool }

        case .shutdown:
            return []
        }
    }

    @usableFromInline
    static func calculateBackoff(failedAttempt attempts: Int) -> Duration {
        // Our backoff formula is: 100ms * 1.25^(attempts - 1) that is capped of at 1minute
        // This means for:
        //   -  1 failed attempt :  100ms
        //   -  5 failed attempts: ~300ms
        //   - 10 failed attempts: ~930ms
        //   - 15 failed attempts: ~2.84s
        //   - 20 failed attempts: ~8.67s
        //   - 25 failed attempts: ~26s
        //   - 29 failed attempts: ~60s (max out)

        let start = Double(100_000_000)
        let backoffNanosecondsDouble = start * pow(1.25, Double(attempts - 1))

        // Cap to 60s _before_ we convert to Int64, to avoid trapping in the Int64 initializer.
        let backoffNanoseconds = Int64(min(backoffNanosecondsDouble, Double(60_000_000_000)))

        let backoff = Duration.nanoseconds(backoffNanoseconds)

        // Calculate a 10% jitter range
        let jitterRange = (backoffNanoseconds / 100) * 10
        // Pick a random element from the range +/- jitter range.
        let jitter: Duration = .nanoseconds((-jitterRange...jitterRange).randomElement()!)
        let jitteredBackoff = backoff + jitter
        return jitteredBackoff
    }
}
