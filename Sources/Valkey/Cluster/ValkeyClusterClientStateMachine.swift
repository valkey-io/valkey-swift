//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey project
//
// Copyright (c) 2025 the swift-valkey authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See swift-valkey/CONTRIBUTORS.txt for the list of swift-valkey authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore
import NIOSSL

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

package struct ValkeyClusterTimer: Sendable, Hashable {
    package enum UseCase: Hashable {
        case nextDiscovery
        case circuitBreaker
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
package struct ValkeyClusterClientStateMachineConfiguration {
    /// The duration after which the cluster client rejects all requests, because it can't find a cluster consensus
    @usableFromInline
    package var circuitBreakerDuration: Duration

    /// The default duration between starts of cluster refreshs, if the previous refresh was successful
    package var defaultClusterRefreshInterval: Duration

    package init(circuitBreakerDuration: Duration, defaultClusterRefreshInterval: Duration) {
        self.circuitBreakerDuration = circuitBreakerDuration
        self.defaultClusterRefreshInterval = defaultClusterRefreshInterval
    }
}

@usableFromInline
package struct ValkeyClusterClientStateMachine<
    ConnectionPool: ValkeyNodeConnectionPool,
    ConnectionPoolFactory: ValkeyNodeConnectionPoolFactory,
    Clock: _Concurrency.Clock,
    SuccessNotifier,
    TimerCancellationToken: Sendable
> where ConnectionPool == ConnectionPoolFactory.ConnectionPool, Clock.Duration == Duration {

    @usableFromInline
    struct Timer {
        var id: Int
        var cancellationToken: TimerCancellationToken?
    }

    @usableFromInline
    /* private */ enum ClusterState {
        /// We have no idea about the current cluster state.
        case unavailable(UnavailableContext)

        /// The cluster was healthy before, but we received a MOVED error to an unknown host
        /// In this state we have about a minute to become healthy again. Otherwise we mark
        /// the cluster as unavailable.
        case degraded(DegradedContext)

        /// The state we assume everything is awesome in.
        case healthy(HealthyContext)

        /// The cluster is shutting down. No new commands are served.
        case shutdown

        @usableFromInline
        struct UnavailableContext {
            @usableFromInline
            /* private */ var start: Clock.Instant
            @usableFromInline
            /* private */ var pendingSuccessNotifiers: [Int: SuccessNotifier]
            @usableFromInline
            /* private */ var circuitBreakerTimer: Timer?

            var lastHealthyState: ValkeyClusterDescription?

            var lastError: any Error
        }

        @usableFromInline
        struct DegradedContext {
            /// The time the cluster state switched from healthy to degraded
            @usableFromInline
            /* private */ var start: Clock.Instant

            /// Waiters, that wait for the next healthy state. If we can't reach a healthy state
            /// within a minute we fail all of them anyway.
            @usableFromInline
            /* private */ var pendingSuccessNotifiers: [Int: SuccessNotifier]

            @usableFromInline
            /* private */ var circuitBreakerTimer: Timer?

            @usableFromInline
            /* private */ var hashSlotShardMap: HashSlotShardMap

            var lastHealthyState: ValkeyClusterDescription

            var lastError: any Error
        }

        @usableFromInline
        struct HealthyContext {
            var clusterDescription: ValkeyClusterDescription
            @usableFromInline
            /* private */ var hashSlotShardMap: HashSlotShardMap
            var consensusStart: Clock.Instant
        }
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

    @usableFromInline
    /* private */ struct NodeBundle: Sendable {
        @usableFromInline
        var nodeID: ValkeyNodeID { self.nodeDescription.id }

        @usableFromInline
        var pool: ConnectionPool
        @usableFromInline
        var nodeDescription: ValkeyNodeDescription
    }

    @usableFromInline
    /* private */ let clock: Clock
    private let poolFactory: ConnectionPoolFactory

    /* private */ var refreshState: RefreshState
    @usableFromInline
    /* private */ var clusterState: ClusterState
    @usableFromInline
    /* private */ var runningClients: [ValkeyNodeID: NodeBundle] = [:]
    @usableFromInline
    /* private */ var configuration: ValkeyClusterClientStateMachineConfiguration

    private var _nextTimerID: Int = 0

    package init(
        configuration: ValkeyClusterClientStateMachineConfiguration,
        poolFactory: ConnectionPoolFactory,
        clock: Clock
    ) {
        self.clusterState = .unavailable(
            ClusterState.UnavailableContext(
                start: clock.now,
                pendingSuccessNotifiers: [:],
                lastError: ValkeyClusterError.noConsensusReachedCircuitBreakerOpen
            )
        )
        self.refreshState = .notRefreshing
        self.runningClients = [:]
        self.configuration = configuration
        self.clock = clock
        self.poolFactory = poolFactory
    }

    package mutating func start() -> ValkeyClusterTimer {
        switch self.refreshState {
        case .notRefreshing:
            switch self.clusterState {
            case .unavailable(var unavailableContext):
                self.refreshState = .refreshing(.init(consecutiveFailures: 0, lastError: nil))
                let timerID = self.nextTimerID()
                unavailableContext.circuitBreakerTimer = .init(id: timerID)
                self.clusterState = .unavailable(unavailableContext)
                return .init(timerID: timerID, useCase: .circuitBreaker, duration: self.configuration.circuitBreakerDuration)

            case .degraded, .healthy, .shutdown:
                preconditionFailure("Invalid state: \(self.refreshState)")
            }

        case .waitingForRefresh, .refreshing:
            preconditionFailure("Invalid state: \(self.refreshState)")
        }
    }

    package struct UpdateValkeyNodesAction {
        // new pools that were created as a response to the update
        package var clientsToRun: [ConnectionPool]

        package var clientsToShutdown: [ConnectionPool]

        package var voters: [ValkeyClusterVoter<ConnectionPool>]

        static func empty() -> Self {
            .init(clientsToRun: [], clientsToShutdown: [], voters: [])
        }
    }

    package mutating func updateValkeyServiceNodes(
        _ newNodes: [ValkeyNodeDescription]
    ) -> UpdateValkeyNodesAction {
        switch self.refreshState {
        case .notRefreshing, .waitingForRefresh:
            preconditionFailure("Invalid state: \(self.refreshState)")

        case .refreshing:
            switch self.clusterState {
            case .unavailable, .degraded, .healthy:
                let action = self.updateNodes(newNodes, removeUnmentionedPools: false)
                let voters = self.allNodeClients().map { ValkeyClusterVoter(client: $0.pool, nodeID: $0.nodeID) }
                return .init(
                    clientsToRun: action.poolsToRun.map(\.0),
                    clientsToShutdown: action.poolsToShutdown,
                    voters: voters
                )

            case .shutdown:
                return .empty()
            }
        }
    }

    package func getInitialVoters() -> [ValkeyClusterVoter<ConnectionPool>] {
        self.allNodeClients().map { ValkeyClusterVoter(client: $0.pool, nodeID: $0.nodeID) }
    }

    package struct ClusterDiscoverySucceededAction {
        package var createTimer: ValkeyClusterTimer? = nil

        package var cancelTimer: TimerCancellationToken? = nil

        package var waitersToSucceed: [SuccessNotifier] = []

        package var clientsToShutdown: [ConnectionPool] = []

        package var clientsToRun: [ConnectionPool] = []
    }

    package mutating func valkeyClusterDiscoverySucceeded(
        _ description: ValkeyClusterDescription
    ) -> ClusterDiscoverySucceededAction {
        switch self.refreshState {
        case .notRefreshing, .waitingForRefresh:
            preconditionFailure("Invalid state: \(self.refreshState)")

        case .refreshing:
            let oldCusterState = self.clusterState
            var map = HashSlotShardMap()
            map.updateCluster(description.shards)
            self.clusterState = .healthy(.init(clusterDescription: description, hashSlotShardMap: map, consensusStart: self.clock.now))

            let refreshTimerID = self.nextTimerID()
            self.refreshState = .waitingForRefresh(.init(id: refreshTimerID), previousRefresh: .init(consecutiveFailures: 0))

            let newShards = description.shards
            let poolUpdate = self.updateNodes(
                newShards.lazy.flatMap { $0.nodes.lazy.map { ValkeyNodeDescription(description: $0) } },
                removeUnmentionedPools: true
            )
            assert(poolUpdate.poolsToRun.isEmpty)

            var result = ClusterDiscoverySucceededAction(
                createTimer: .init(
                    timerID: refreshTimerID,
                    useCase: .nextDiscovery,
                    duration: self.configuration.defaultClusterRefreshInterval
                ),
                clientsToShutdown: poolUpdate.poolsToShutdown,
                clientsToRun: poolUpdate.poolsToRun.map(\.0)
            )

            switch oldCusterState {
            case .healthy:
                return result

            case .degraded(let context):
                result.cancelTimer = context.circuitBreakerTimer?.cancellationToken
                result.waitersToSucceed = Array(context.pendingSuccessNotifiers.values)
                return result

            case .unavailable(let context):
                result.cancelTimer = context.circuitBreakerTimer?.cancellationToken
                result.waitersToSucceed = Array(context.pendingSuccessNotifiers.values)
                return result

            case .shutdown:
                return .init()
            }
        }
    }

    package struct ClusterDiscoveryFailedAction: Hashable, Sendable {
        package var retryTimer: ValkeyClusterTimer?

        package var circuitBreakerTimer: ValkeyClusterTimer?
    }

    package mutating func valkeyClusterDiscoveryFailed(
        _ error: any Error
    ) -> ClusterDiscoveryFailedAction {
        switch self.refreshState {
        case .notRefreshing, .waitingForRefresh:
            preconditionFailure("Invalid state: \(self.refreshState)")

        case .refreshing(var refreshContext):
            var failedAction: ClusterDiscoveryFailedAction
            switch self.clusterState {
            case .healthy(let healthyContext):
                assert(refreshContext.consecutiveFailures == 0)
                let circuitBreakerTimerID = self.nextTimerID()
                let timerTillUnavailable = ValkeyClusterTimer(
                    timerID: circuitBreakerTimerID,
                    useCase: .circuitBreaker,
                    duration: self.configuration.circuitBreakerDuration
                )
                self.clusterState = .degraded(.init(
                    start: self.clock.now,
                    pendingSuccessNotifiers: [:],
                    circuitBreakerTimer: .init(id: circuitBreakerTimerID),
                    hashSlotShardMap: healthyContext.hashSlotShardMap,
                    lastHealthyState: healthyContext.clusterDescription,
                    lastError: error
                ))
                failedAction = ClusterDiscoveryFailedAction(
                    circuitBreakerTimer: timerTillUnavailable
                )

            case .degraded(var degradedContext):
                assert(refreshContext.consecutiveFailures > 0)
                degradedContext.lastError = error
                self.clusterState = .degraded(degradedContext)
                failedAction = ClusterDiscoveryFailedAction()

            case .unavailable(var unavailableContext):
                unavailableContext.lastError = error
                self.clusterState = .unavailable(unavailableContext)
                failedAction = ClusterDiscoveryFailedAction()

            case .shutdown:
                return ClusterDiscoveryFailedAction()
            }

            refreshContext.consecutiveFailures += 1
            let waitTillNextTry = Self.calculateBackoff(failedAttempt: refreshContext.consecutiveFailures)
            let refreshTimerID = self.nextTimerID()
            self.refreshState = .waitingForRefresh(
                .init(id: refreshTimerID),
                previousRefresh: refreshContext
            )

            failedAction.retryTimer = .init(
                timerID: refreshTimerID,
                useCase: .nextDiscovery,
                duration: waitTillNextTry
            )
            return failedAction
        }
    }

    package struct TimerFiredAction {
        package struct RunDiscovery {
            package var runNodeDiscoveryFirst: Bool

            package init(runNodeDiscoveryFirst: Bool) {
                self.runNodeDiscoveryFirst = runNodeDiscoveryFirst
            }
        }

        package struct FailWaiters {
            package var waitersToFail: [SuccessNotifier]

            package var error: any Error
        }

        package var runDiscovery: RunDiscovery?
        package var failWaiters: FailWaiters?

        package init(runDiscovery: RunDiscovery? = nil, failWaiters: FailWaiters? = nil) {
            self.runDiscovery = runDiscovery
            self.failWaiters = failWaiters
        }
    }

    package mutating func timerFired(_ timer: ValkeyClusterTimer) -> TimerFiredAction {
        switch timer.useCase {
        case .nextDiscovery:
            let runNodeDiscoveryFirst: Bool
            switch self.clusterState {
            case .shutdown:
                return .init()

            case .healthy:
                runNodeDiscoveryFirst = false

            case .degraded, .unavailable:
                runNodeDiscoveryFirst = true
            }

            switch self.refreshState {
            case .refreshing, .notRefreshing:
                // race condition. we are already refreshing
                return .init()

            case .waitingForRefresh(let storedTimer, let previousRefresh):
                guard storedTimer.id == timer.timerID else {
                    // race condition. the timer that fired isn't interesting anymore
                    return .init()
                }
                self.refreshState = .refreshing(previousRefresh)
                return .init(runDiscovery: .init(runNodeDiscoveryFirst: runNodeDiscoveryFirst))
            }

        case .circuitBreaker:
            switch self.clusterState {
            case .unavailable(var unavailableContext):
                // this will only happen at startup, if we can't find a cluster within the circuit
                // breaker interval
                guard unavailableContext.circuitBreakerTimer?.id == timer.timerID else {
                    return .init()
                }

                unavailableContext.circuitBreakerTimer = nil
                let successNotifiers = Array(unavailableContext.pendingSuccessNotifiers.values)
                unavailableContext.pendingSuccessNotifiers.removeAll()
                self.clusterState = .unavailable(unavailableContext)
                return .init(
                    failWaiters: .init(
                        waitersToFail: successNotifiers,
                        error: unavailableContext.lastError
                    )
                )

            case .degraded(let degradedContext):
                guard degradedContext.circuitBreakerTimer?.id == timer.timerID else {
                    // we were degraded, got healthy and are now degraded again. timerID doesn't match
                    return .init()
                }

                self.clusterState = .unavailable(
                    .init(
                        start: degradedContext.start,
                        pendingSuccessNotifiers: [:],
                        lastHealthyState: degradedContext.lastHealthyState,
                        lastError: degradedContext.lastError,
                    )
                )
                return .init(
                    failWaiters: .init(
                        waitersToFail: Array(degradedContext.pendingSuccessNotifiers.values),
                        error: degradedContext.lastError
                    )
                )

            case .healthy:
                // race. we likely where degraded before but we just recovered. therefore ignore
                return .init()

            case .shutdown:
                return .init()
            }
        }
    }

    package mutating func registerTimerCancellationToken(
        _ token: TimerCancellationToken,
        for timer: ValkeyClusterTimer
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

        case .circuitBreaker:
            switch self.clusterState {
            case .degraded(var context):
                if context.circuitBreakerTimer?.id == timer.timerID {
                    context.circuitBreakerTimer!.cancellationToken = token
                    self.clusterState = .degraded(context)
                    return nil
                }
                return token

            case .unavailable(var context):
                if context.circuitBreakerTimer?.id == timer.timerID {
                    context.circuitBreakerTimer!.cancellationToken = token
                    self.clusterState = .unavailable(context)
                    return nil
                }
                return token

            case .healthy, .shutdown:
                return token
            }
        }
    }

    @inlinable
    package func poolFastPath(for slots: some Collection<HashSlot>) throws(ValkeyClusterError) -> ConnectionPool {
        switch self.clusterState {
        case .unavailable:
            throw ValkeyClusterError.clusterIsUnavailable

        case .degraded(let context):
            let shardID = try context.hashSlotShardMap.nodeID(for: slots)
            if let pool = self.runningClients[shardID.primary]?.pool {
                return pool
            }
            // If we don't have a node for a shard, that means that this shard got created from
            // a MOVED error. It might be that we are missing info about this node, which is why
            // we need to wait for the next discovery cycle.
            throw ValkeyClusterError.clusterIsMissingMovedErrorNode

        case .healthy(let context):
            let shardID = try context.hashSlotShardMap.nodeID(for: slots)
            if let pool = self.runningClients[shardID.primary]?.pool {
                return pool
            }
            // If we don't have a node for a shard, that means that this shard got created from
            // a MOVED error. It might be that we are missing info about this node, which is why
            // we need to wait for the next discovery cycle.
            throw ValkeyClusterError.clusterIsMissingMovedErrorNode

        case .shutdown:
            throw ValkeyClusterError.clusterClientIsShutDown
        }
    }

    @usableFromInline
    package enum PoolForMovedErrorAction {
        case connectionPool(ConnectionPool)
        case moveToDegraded(MoveToDegraded)
        case waitForDiscovery

        @usableFromInline
        package struct MoveToDegraded {
            package var runDiscoveryAndCancelTimer: TimerCancellationToken?
            package var circuitBreakerTimer: ValkeyClusterTimer

            package init(runDiscoveryAndCancelTimer: TimerCancellationToken? = nil, circuitBreakerTimer: ValkeyClusterTimer) {
                self.runDiscoveryAndCancelTimer = runDiscoveryAndCancelTimer
                self.circuitBreakerTimer = circuitBreakerTimer
            }
        }
    }

    @usableFromInline
    package mutating func poolFastPath(for movedError: ValkeyMovedError) throws(ValkeyClusterError) -> PoolForMovedErrorAction {
        switch self.clusterState {
        case .unavailable(let unavailableContext):
            if unavailableContext.start.advanced(by: self.configuration.circuitBreakerDuration) > self.clock.now {
                return .waitForDiscovery
            }
            throw ValkeyClusterError.noConsensusReachedCircuitBreakerOpen

        case .degraded(var degradedContext):
            switch degradedContext.hashSlotShardMap.updateSlots(with: movedError) {
            case .updatedSlotToExistingNode, .updatedSlotToUnknownNode:
                self.clusterState = .degraded(degradedContext)
                if let pool = self.runningClients[movedError.nodeID]?.pool {
                    return .connectionPool(pool)
                }
                return .waitForDiscovery
            }

        case .healthy(var healthyContext):
            switch healthyContext.hashSlotShardMap.updateSlots(with: movedError) {
            case .updatedSlotToUnknownNode:
                break

            case .updatedSlotToExistingNode:
                if let pool = self.runningClients[movedError.nodeID]?.pool {
                    self.clusterState = .healthy(healthyContext)
                    return .connectionPool(pool)
                }
            }

            let circuitBreakerTimerID = self.nextTimerID()

            self.clusterState = .degraded(.init(
                start: self.clock.now,
                pendingSuccessNotifiers: [:],
                circuitBreakerTimer: .init(id: circuitBreakerTimerID),
                hashSlotShardMap: healthyContext.hashSlotShardMap,
                lastHealthyState: healthyContext.clusterDescription,
                lastError: ValkeyClusterError.clusterIsMissingMovedErrorNode
            ))

            // move into degraded state.
            let cancelTimer: TimerCancellationToken?
            switch self.refreshState {
            case .notRefreshing, .refreshing:
                cancelTimer = nil
            case .waitingForRefresh(let context, let previousRefresh):
                self.refreshState = .refreshing(previousRefresh)
                cancelTimer = context.cancellationToken
            }

            return .moveToDegraded(.init(
                runDiscoveryAndCancelTimer: cancelTimer,
                circuitBreakerTimer: .init(
                    timerID: circuitBreakerTimerID,
                    useCase: .circuitBreaker,
                    duration: self.configuration.circuitBreakerDuration
                )
            ))

        case .shutdown:
            throw ValkeyClusterError.clusterClientIsShutDown
        }
    }

    @usableFromInline
    package enum WaitForHealthyAction {
        case none
        case succeed(SuccessNotifier)
        case fail(any Error, SuccessNotifier)
    }

    @inlinable
    mutating package func waitForHealthy(waiterID: Int, successNotifier: SuccessNotifier) -> WaitForHealthyAction {
        switch self.clusterState {
        case .unavailable(var context):
            if context.start.advanced(by: self.configuration.circuitBreakerDuration) <= self.clock.now {
                return .fail(ValkeyClusterError.noConsensusReachedCircuitBreakerOpen, successNotifier)
            }
            context.pendingSuccessNotifiers[waiterID] = successNotifier
            self.clusterState = .unavailable(context)
            return .none

        case .degraded(var context):
            context.pendingSuccessNotifiers[waiterID] = successNotifier
            self.clusterState = .degraded(context)
            return .none

        case .healthy:
            return .succeed(successNotifier)

        case .shutdown:
            return .fail(ValkeyClusterError.clusterClientIsShutDown, successNotifier)
        }
    }


    package mutating func updateValkeyServiceNodes(
        _ description: ValkeyClusterDescription
    ) -> UpdateValkeyNodesAction {

        switch self.clusterState {
        case .unavailable, .degraded, .healthy:
            switch self.refreshState {
            case .notRefreshing, .waitingForRefresh:
                assert(false, "A valkey cluster update is illegal, if we are not refreshing.")
                return .empty()

            case .refreshing:
                let newShards = description.shards
                let poolActions = self.updateNodes(
                    newShards.lazy.flatMap { $0.nodes.lazy.map { ValkeyNodeDescription(description: $0) } },
                    removeUnmentionedPools: false
                )
                return .init(
                    clientsToRun: poolActions.poolsToRun.map(\.0),
                    clientsToShutdown: poolActions.poolsToShutdown,
                    voters: poolActions.poolsToRun.map { ValkeyClusterVoter(client: $0.0, nodeID: $0.1) }
                )
            }

        case .shutdown:
            return .empty()
        }
    }

    struct ShutdownAction {

    }

    package mutating func shutdown() -> [ConnectionPool] {
        switch self.clusterState {
        case .unavailable, .degraded, .healthy:
            self.clusterState = .shutdown
            let existingNodes = self.runningClients
            self.runningClients.removeAll(keepingCapacity: false)
            return existingNodes.values.lazy.map { $0.pool }

        case .shutdown:
            return []
        }
    }

    private struct PoolUpdateAction {
        var poolsToShutdown: [ConnectionPool]
        var poolsToRun: [(ConnectionPool, ValkeyNodeID)]

        static func empty() -> PoolUpdateAction { PoolUpdateAction(poolsToShutdown: [], poolsToRun: []) }
    }

    private mutating func updateNodes(
        _ newNodes: some Collection<ValkeyNodeDescription>,
        removeUnmentionedPools: Bool
    ) -> PoolUpdateAction {
        var previousNodes = self.runningClients
        self.runningClients.removeAll(keepingCapacity: true)
        var newPools = [(ConnectionPool, ValkeyNodeID)]()
        newPools.reserveCapacity(16)
        var poolsToShutdown = [ConnectionPool]()

        for newNodeDescription in newNodes {
            // if we had a pool previously, let's continue to use it!
            if let existingPool = previousNodes.removeValue(forKey: newNodeDescription.id) {
                if newNodeDescription == existingPool.nodeDescription {
                    // the existing pool matches the new node description. nothing todo
                    self.runningClients[newNodeDescription.id] = existingPool
                } else {
                    // the existing pool does not match new node description. For example tls may now be required.
                    // shutdown the old pool and create a new one
                    poolsToShutdown.append(existingPool.pool)
                    let newPool = self.makePool(for: newNodeDescription)
                    self.runningClients[newNodeDescription.id] = NodeBundle(pool: newPool, nodeDescription: newNodeDescription)
                    newPools.append((newPool, newNodeDescription.id))
                }
            } else {
                let newPool = self.makePool(for: newNodeDescription)
                self.runningClients[newNodeDescription.id] = NodeBundle(pool: newPool, nodeDescription: newNodeDescription)
                newPools.append((newPool, newNodeDescription.id))
            }
        }

        if removeUnmentionedPools {
            poolsToShutdown.append(contentsOf: previousNodes.values.lazy.map { $0.pool })

            return PoolUpdateAction(
                poolsToShutdown: poolsToShutdown,
                poolsToRun: newPools
            )
        }

        // re-add pools that were not part of the node list.
        for (nodeID, poolDescription) in previousNodes {
            self.runningClients[nodeID] = poolDescription
        }

        return PoolUpdateAction(
            poolsToShutdown: poolsToShutdown,
            poolsToRun: newPools
        )
    }

    private func makePool(for description: ValkeyNodeDescription) -> ConnectionPool {
        self.poolFactory.makeConnectionPool(nodeDescription: description)
    }

    private func allNodeClients() -> some Collection<NodeBundle> {
        self.runningClients.values
    }

    private mutating func nextTimerID() -> Int {
        defer { self._nextTimerID += 1 }
        return self._nextTimerID
    }

    @inlinable
    mutating func cancelWaitingForHealthy(id: Int) -> SuccessNotifier? {
        switch self.clusterState {
        case .unavailable(var context):
            let fail = context.pendingSuccessNotifiers.removeValue(forKey: id)
            self.clusterState = .unavailable(context)
            return fail

        case .degraded(var context):
            let fail = context.pendingSuccessNotifiers.removeValue(forKey: id)
            self.clusterState = .degraded(context)
            return fail

        case .shutdown, .healthy:
            return nil
        }
    }
}

extension ValkeyClusterClientStateMachine {
    /// Calculates the delay for the next connection attempt after the given number of failed `attempts`.
    ///
    /// Our backoff formula is: 100ms * 1.25^(attempts - 1) with 3% jitter that is capped of at 1 minute.
    /// This means for:
    ///   -  1 failed attempt :  100ms
    ///   -  5 failed attempts: ~300ms
    ///   - 10 failed attempts: ~930ms
    ///   - 15 failed attempts: ~2.84s
    ///   - 20 failed attempts: ~8.67s
    ///   - 25 failed attempts: ~26s
    ///   - 29 failed attempts: ~60s (max out)
    ///
    /// - Parameter attempts: number of failed attempts in a row
    /// - Returns: time to wait until trying to establishing a new connection
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
