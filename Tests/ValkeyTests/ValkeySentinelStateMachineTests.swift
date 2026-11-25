//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import Testing

@testable import Valkey

struct ValkeySentinelStateMachineTests {
    @available(valkeySwift 1.0, *)
    typealias TestStateMachine = ValkeySentinelClientStateMachine<
        MockClient<ValkeyNodeDescription>,
        MockClientFactory<ValkeyNodeDescription>,
        MockClock,
        SuccessNotifier,
        TimerCancellationToken
    >
    @available(valkeySwift 1.0, *)
    var testConfiguration: TestStateMachine.Configuration {
        .init()
    }

    func setupStateMachine() throws -> (stateMachine: TestStateMachine, clock: MockClock, timer: ValkeySentinelTimer) {
        let factory = MockClientFactory<ValkeyNodeDescription>()
        let clock = MockClock()
        var stateMachine = TestStateMachine(
            poolFactory: factory,
            configuration: .init(defaultSentinelRefreshInterval: .seconds(30), circuitBreakerTripAfter: .seconds(30)),
            clock: clock
        )
        let initialNodes = (9000..<9002).map { ValkeyNodeDescription(endpoint: "127.0.0.1", port: $0) }
        let additionalNodes = (9002..<9004).map { ValkeyNodeDescription(endpoint: "127.0.0.1", port: $0) }

        let circuitBreakerTimer = stateMachine.start()
        #expect(circuitBreakerTimer.timerID == 0)
        #expect(circuitBreakerTimer.useCase == .circuitBreaker)
        #expect(circuitBreakerTimer.duration == .seconds(30))

        let updateAction = stateMachine.updateSentinelNodes(.init(initialNodes))
        #expect(Set(updateAction.clientsToRun.map { $0.nodeDescription.id }) == Set(initialNodes.map { $0.id }))
        #expect(updateAction.clientsToShutdown.isEmpty)
        #expect(Set(updateAction.voters.map { $0.nodeID }) == Set(initialNodes.map { $0.id }))

        let succeededAction = stateMachine.topologyDiscoverySucceeded(.init(initialNodes + additionalNodes))
        #expect(Set(succeededAction.clientsToRun.map { $0.nodeDescription.id }) == Set(additionalNodes.map { $0.id }))
        #expect(succeededAction.clientsToShutdown.isEmpty)
        let refreshTimer = try #require(succeededAction.timerToRun)

        let timerCancellationToken = TimerCancellationToken()
        let unusedCancellationToken = stateMachine.registerTimerCancellationToken(timerCancellationToken, for: refreshTimer)
        #expect(unusedCancellationToken === nil)

        return (stateMachine, clock, refreshTimer)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func runDiscoveryAfterStartup() throws {
        let factory = MockClientFactory<ValkeyNodeDescription>()
        let clock = MockClock()
        var stateMachine = TestStateMachine(poolFactory: factory, configuration: .init(), clock: clock)
        let initialNodes = (9000..<9002).map { ValkeyNodeDescription(endpoint: "127.0.0.1", port: $0) }
        let additionalNodes = (9002..<9004).map { ValkeyNodeDescription(endpoint: "127.0.0.1", port: $0) }

        _ = stateMachine.start()

        let updateAction = stateMachine.updateSentinelNodes(.init(initialNodes))
        #expect(Set(updateAction.clientsToRun.map { $0.nodeDescription.id }) == Set(initialNodes.map { $0.id }))
        #expect(updateAction.clientsToShutdown.isEmpty)
        #expect(Set(updateAction.voters.map { $0.nodeID }) == Set(initialNodes.map { $0.id }))

        let successNotifier = SuccessNotifier()
        let waitAction = stateMachine.waitForDiscovery(waiterID: 0, successNotification: successNotifier)
        switch waitAction {
        case .doNothing: break
        default: Issue.record("Expected to do nothing")
        }

        let succeededAction = stateMachine.topologyDiscoverySucceeded(.init(initialNodes + additionalNodes))
        #expect(Set(succeededAction.clientsToRun.map { $0.nodeDescription.id }) == Set(additionalNodes.map { $0.id }))
        #expect(succeededAction.clientsToShutdown.isEmpty)
        #expect(succeededAction.waitersToSucceed.first === successNotifier)

        let successNotifier2 = SuccessNotifier()
        let waitAction2 = stateMachine.waitForDiscovery(waiterID: 0, successNotification: successNotifier2)
        switch waitAction2 {
        case .complete: break
        default: Issue.record("Expected to do nothing")
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func cancelWaitForDiscovery() throws {
        let factory = MockClientFactory<ValkeyNodeDescription>()
        let clock = MockClock()
        var stateMachine = TestStateMachine(poolFactory: factory, configuration: .init(), clock: clock)
        let initialNodes = (9000..<9002).map { ValkeyNodeDescription(endpoint: "127.0.0.1", port: $0) }
        let additionalNodes = (9002..<9004).map { ValkeyNodeDescription(endpoint: "127.0.0.1", port: $0) }

        _ = stateMachine.start()

        let updateAction = stateMachine.updateSentinelNodes(.init(initialNodes))
        #expect(Set(updateAction.clientsToRun.map { $0.nodeDescription.id }) == Set(initialNodes.map { $0.id }))
        #expect(updateAction.clientsToShutdown.isEmpty)
        #expect(Set(updateAction.voters.map { $0.nodeID }) == Set(initialNodes.map { $0.id }))

        let successNotifier = SuccessNotifier()
        let waitAction = stateMachine.waitForDiscovery(waiterID: 0, successNotification: successNotifier)
        switch waitAction {
        case .doNothing: break
        default: Issue.record("Expected to do nothing")
        }

        let cancelNotifier = stateMachine.cancelWaitForDiscovery(waiterID: 0)
        #expect(cancelNotifier === successNotifier)

        let succeededAction = stateMachine.topologyDiscoverySucceeded(.init(initialNodes + additionalNodes))
        #expect(Set(succeededAction.clientsToRun.map { $0.nodeDescription.id }) == Set(additionalNodes.map { $0.id }))
        #expect(succeededAction.clientsToShutdown.isEmpty)
        #expect(succeededAction.waitersToSucceed.isEmpty)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func runRefresh() throws {
        let factory = MockClientFactory<ValkeyNodeDescription>()
        let clock = MockClock()
        var stateMachine = TestStateMachine(poolFactory: factory, configuration: .init(defaultSentinelRefreshInterval: .seconds(30)), clock: clock)
        let initialNodes = (9000..<9002).map { ValkeyNodeDescription(endpoint: "127.0.0.1", port: $0) }
        let additionalNodes = (9002..<9004).map { ValkeyNodeDescription(endpoint: "127.0.0.1", port: $0) }

        _ = stateMachine.start()

        let updateAction = stateMachine.updateSentinelNodes(.init(initialNodes))
        #expect(Set(updateAction.clientsToRun.map { $0.nodeDescription.id }) == Set(initialNodes.map { $0.id }))
        #expect(updateAction.clientsToShutdown.isEmpty)
        #expect(Set(updateAction.voters.map { $0.nodeID }) == Set(initialNodes.map { $0.id }))

        let succeededAction = stateMachine.topologyDiscoverySucceeded(.init(initialNodes + additionalNodes))
        #expect(Set(succeededAction.clientsToRun.map { $0.nodeDescription.id }) == Set(additionalNodes.map { $0.id }))
        #expect(succeededAction.clientsToShutdown.isEmpty)
        #expect(succeededAction.waitersToSucceed.isEmpty)
        let discoveryTimer = try #require(succeededAction.timerToRun)
        #expect(discoveryTimer == .init(timerID: 1, useCase: .nextDiscovery, duration: .seconds(30)))

        let timerCancellationToken = TimerCancellationToken()
        let unusedCancellationToken = stateMachine.registerTimerCancellationToken(timerCancellationToken, for: discoveryTimer)
        #expect(unusedCancellationToken === nil)

        let timerFiredAction = stateMachine.timerFired(discoveryTimer)
        if case .runDiscovery(let runDiscoveryContext) = timerFiredAction {
            #expect(runDiscoveryContext.runNodeDiscoveryFirst == false)
        } else {
            Issue.record()
        }
        let succeededAction2 = stateMachine.topologyDiscoverySucceeded(.init(initialNodes + additionalNodes))
        #expect(succeededAction2.clientsToRun.isEmpty)
        #expect(succeededAction2.clientsToShutdown.isEmpty)
        #expect(succeededAction2.waitersToSucceed.isEmpty)
        #expect(succeededAction2.timerToRun == .init(timerID: 2, useCase: .nextDiscovery, duration: .seconds(30)))
    }

    @Test
    @available(valkeySwift 1.0, *)
    func failedThenSucessfulDiscovery() throws {
        let factory = MockClientFactory<ValkeyNodeDescription>()
        let clock = MockClock()
        var stateMachine = TestStateMachine(poolFactory: factory, configuration: .init(defaultSentinelRefreshInterval: .seconds(30)), clock: clock)
        let initialNodes = (9000..<9002).map { ValkeyNodeDescription(endpoint: "127.0.0.1", port: $0) }
        let additionalNodes = (9002..<9004).map { ValkeyNodeDescription(endpoint: "127.0.0.1", port: $0) }

        _ = stateMachine.start()

        let updateAction = stateMachine.updateSentinelNodes(.init(initialNodes))
        #expect(Set(updateAction.clientsToRun.map { $0.nodeDescription.id }) == Set(initialNodes.map { $0.id }))
        #expect(updateAction.clientsToShutdown.isEmpty)
        #expect(Set(updateAction.voters.map { $0.nodeID }) == Set(initialNodes.map { $0.id }))

        let failedAction = stateMachine.topologyDiscoveryFailed(error: ValkeyClientError(.unrecognisedError))
        let discoveryTimer = try #require(failedAction.retryTimer)
        #expect(discoveryTimer.timerID == 1)
        #expect(discoveryTimer.useCase == .nextDiscovery)
        #expect(discoveryTimer.duration > .seconds(0) && discoveryTimer.duration < .seconds(1))

        let timerCancellationToken = TimerCancellationToken()
        let unusedCancellationToken = stateMachine.registerTimerCancellationToken(timerCancellationToken, for: discoveryTimer)
        #expect(unusedCancellationToken === nil)

        let timerFiredAction = stateMachine.timerFired(discoveryTimer)
        if case .runDiscovery(let runDiscoveryContext) = timerFiredAction {
            #expect(runDiscoveryContext.runNodeDiscoveryFirst == false)
        } else {
            Issue.record()
        }

        let succeededAction = stateMachine.topologyDiscoverySucceeded(.init(initialNodes + additionalNodes))
        #expect(Set(succeededAction.clientsToRun.map { $0.nodeDescription.id }) == Set(additionalNodes.map { $0.id }))
        #expect(succeededAction.clientsToShutdown.isEmpty)
        #expect(succeededAction.waitersToSucceed.isEmpty)
        #expect(succeededAction.timerToRun == .init(timerID: 2, useCase: .nextDiscovery, duration: .seconds(30)))
    }

    /// Test triggering circuit breaker during startup
    @Test
    @available(valkeySwift 1.0, *)
    func tripCircuitBreakerAtStartup() throws {
        let factory = MockClientFactory<ValkeyNodeDescription>()
        let clock = MockClock()
        var stateMachine = TestStateMachine(poolFactory: factory, configuration: .init(circuitBreakerTripAfter: .seconds(30)), clock: clock)
        let initialNodes = (9000..<9002).map { ValkeyNodeDescription(endpoint: "127.0.0.1", port: $0) }

        _ = stateMachine.start()

        let successNotifier = SuccessNotifier()
        let waitAction = stateMachine.waitForDiscovery(waiterID: 0, successNotification: successNotifier)
        switch waitAction {
        case .doNothing: break
        default: Issue.record("Expected to do nothing")
        }

        let updateAction = stateMachine.updateSentinelNodes(.init(initialNodes))
        #expect(Set(updateAction.clientsToRun.map { $0.nodeDescription.id }) == Set(initialNodes.map { $0.id }))
        #expect(updateAction.clientsToShutdown.isEmpty)
        #expect(Set(updateAction.voters.map { $0.nodeID }) == Set(initialNodes.map { $0.id }))

        let failedAction = stateMachine.topologyDiscoveryFailed(error: ValkeyClientError(.unrecognisedError))
        #expect(failedAction.waitersToFail.isEmpty)
        let discoveryTimer = try #require(failedAction.retryTimer)
        #expect(discoveryTimer.timerID == 1)
        #expect(discoveryTimer.useCase == .nextDiscovery)
        #expect(discoveryTimer.duration > .seconds(0) && discoveryTimer.duration < .seconds(1))

        let timerCancellationToken = TimerCancellationToken()
        let unusedCancellationToken = stateMachine.registerTimerCancellationToken(timerCancellationToken, for: discoveryTimer)
        #expect(unusedCancellationToken === nil)

        let timerFiredAction = stateMachine.timerFired(discoveryTimer)
        if case .runDiscovery(let runDiscoveryContext) = timerFiredAction {
            #expect(runDiscoveryContext.runNodeDiscoveryFirst == false)
        } else {
            Issue.record()
        }

        clock.advance(to: clock.now.advanced(by: .seconds(40)))
        let failedAction2 = stateMachine.topologyDiscoveryFailed(error: ValkeyClientError(.unrecognisedError))
        #expect(failedAction2.waitersToFail.first === successNotifier)
        let discoveryTimer2 = try #require(failedAction2.retryTimer)
        #expect(discoveryTimer2.timerID == 2)
        #expect(discoveryTimer2.useCase == .nextDiscovery)
        #expect(discoveryTimer2.duration > .seconds(0) && discoveryTimer.duration < .seconds(1))
    }

    /// Test moving from healthy to degraded state and back with a waitForDiscovery call during the degraded state
    @Test
    @available(valkeySwift 1.0, *)
    func degradeAndRevive() throws {
        var (stateMachine, _, timer) = try self.setupStateMachine()

        let timerFiredAction = stateMachine.timerFired(timer)
        if case .runDiscovery(let runDiscoveryContext) = timerFiredAction {
            #expect(runDiscoveryContext.runNodeDiscoveryFirst == false)
        } else {
            Issue.record()
        }

        let failedAction = stateMachine.topologyDiscoveryFailed(error: ValkeyClientError(.unrecognisedError))
        let discoveryTimer = try #require(failedAction.retryTimer)
        #expect(discoveryTimer.timerID == 2)
        #expect(discoveryTimer.useCase == .nextDiscovery)
        #expect(discoveryTimer.duration > .seconds(0) && discoveryTimer.duration < .seconds(1))
        #expect(failedAction.circuitBreakerTimer == .init(timerID: 3, useCase: .circuitBreaker, duration: .seconds(30)))

        let timerCancellationToken = TimerCancellationToken()
        let unusedCancellationToken = stateMachine.registerTimerCancellationToken(timerCancellationToken, for: discoveryTimer)
        #expect(unusedCancellationToken === nil)

        let successNotifier = SuccessNotifier()
        let waitAction = stateMachine.waitForDiscovery(waiterID: 0, successNotification: successNotifier)
        switch waitAction {
        case .doNothing: break
        default: Issue.record("Expected to do nothing")
        }

        let timerFiredAction2 = stateMachine.timerFired(discoveryTimer)
        if case .runDiscovery(let runDiscoveryContext) = timerFiredAction2 {
            #expect(runDiscoveryContext.runNodeDiscoveryFirst == false)
        } else {
            Issue.record()
        }

        let succeededAction = stateMachine.topologyDiscoverySucceeded(
            .init((9000..<9003).map { ValkeyNodeDescription(endpoint: "127.0.0.1", port: $0) })
        )
        #expect(succeededAction.clientsToRun.isEmpty)
        #expect(succeededAction.clientsToShutdown.map { $0.nodeDescription.id } == [.init(endpoint: "127.0.0.1", port: 9003)])
        #expect(succeededAction.waitersToSucceed.first === successNotifier)
        #expect(succeededAction.timerToRun == .init(timerID: 4, useCase: .nextDiscovery, duration: .seconds(30)))
    }

    /// Test moving from healthy to degraded to unavailable
    @Test
    @available(valkeySwift 1.0, *)
    func triggerCircuitBreaker() throws {
        var (stateMachine, clock, timer) = try self.setupStateMachine()

        let timerFiredAction = stateMachine.timerFired(timer)
        if case .runDiscovery(let runDiscoveryContext) = timerFiredAction {
            #expect(runDiscoveryContext.runNodeDiscoveryFirst == false)
        } else {
            Issue.record()
        }

        let failedAction = stateMachine.topologyDiscoveryFailed(error: ValkeyClientError(.unrecognisedError))
        let discoveryTimer = try #require(failedAction.retryTimer)
        #expect(discoveryTimer.timerID == 2)
        #expect(discoveryTimer.useCase == .nextDiscovery)
        #expect(discoveryTimer.duration > .seconds(0) && discoveryTimer.duration < .seconds(1))
        #expect(failedAction.circuitBreakerTimer == .init(timerID: 3, useCase: .circuitBreaker, duration: .seconds(30)))

        let timerCancellationToken = TimerCancellationToken()
        let unusedCancellationToken = stateMachine.registerTimerCancellationToken(timerCancellationToken, for: discoveryTimer)
        #expect(unusedCancellationToken === nil)

        let successNotifier = SuccessNotifier()
        let waitAction = stateMachine.waitForDiscovery(waiterID: 0, successNotification: successNotifier)
        switch waitAction {
        case .doNothing: break
        default: Issue.record("Expected to do nothing")
        }

        let timerFiredAction2 = stateMachine.timerFired(discoveryTimer)
        if case .runDiscovery(let runDiscoveryContext) = timerFiredAction2 {
            #expect(runDiscoveryContext.runNodeDiscoveryFirst == false)
        } else {
            Issue.record()
        }

        clock.advance(to: clock.now.advanced(by: .seconds(40)))

        let failedAction2 = stateMachine.topologyDiscoveryFailed(error: ValkeyClientError(.unrecognisedError))
        #expect(failedAction2.waitersToFail.first === successNotifier)
        let discoveryTimer2 = try #require(failedAction2.retryTimer)
        #expect(discoveryTimer2.timerID == 4)
        #expect(discoveryTimer2.useCase == .nextDiscovery)
        #expect(discoveryTimer2.duration > .seconds(0) && discoveryTimer2.duration < .seconds(1))
        #expect(failedAction2.circuitBreakerTimer == nil)
    }
}
