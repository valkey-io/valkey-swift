//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import Testing
import Valkey

final class SuccessNotifier: Sendable {}
final class TimerCancellationToken: Sendable {}

@Suite
struct ValkeyClusterClientStateMachineTests {

    @available(valkeySwift 1.0, *)
    typealias TestStateMachine = ValkeyClusterClientStateMachine<
        MockClient<ValkeyNodeDescription>,
        MockClientFactory<ValkeyNodeDescription>,
        MockClock,
        SuccessNotifier,
        TimerCancellationToken
    >

    @available(valkeySwift 1.0, *)
    var testConfiguration: ValkeyClusterClientStateMachineConfiguration {
        .init(
            circuitBreakerDuration: .seconds(30),
            defaultClusterRefreshInterval: .seconds(60)
        )
    }

    @Test
    @available(valkeySwift 1.0, *)
    func runDiscoveryAfterStartup() throws {
        let factory = MockClientFactory<ValkeyNodeDescription>()
        let clock = MockClock()
        var stateMachine = TestStateMachine(configuration: testConfiguration, poolFactory: factory, clock: clock)

        let circuitBreakerTimer = stateMachine.start()
        #expect(circuitBreakerTimer.duration == self.testConfiguration.circuitBreakerDuration)

        // register cancel handler
        let circuitBreakerCancelToken = TimerCancellationToken()
        #expect(stateMachine.registerTimerCancellationToken(circuitBreakerCancelToken, for: circuitBreakerTimer) == nil)
        let cluster = ValkeyTopologyElectionTests.createClusterWithReplicas()

        let firstNode = cluster.shards.randomElement()!.nodes.randomElement()!
        let firstNodeDescription = ValkeyNodeDescription(description: firstNode)
        #expect(stateMachine.getInitialVoters().isEmpty)

        let firstNodeDiscoveredAction = stateMachine.updateValkeyServiceNodes([firstNodeDescription])
        #expect(firstNodeDiscoveredAction.clientsToRun.count == 1)
        #expect(firstNodeDiscoveredAction.clientsToShutdown.isEmpty)

        // try to get shard
        #expect(throws: ValkeyClusterError.clusterIsUnavailable) {
            try stateMachine.poolFastPath(for: CollectionOfOne(HashSlot(rawValue: 100)!), nodeSelection: .primary)
        }
        // let's register for the slow path
        let successNotifier = SuccessNotifier()
        let waitAction = stateMachine.waitForHealthy(waiterID: 1, successNotifier: successNotifier)
        #expect(waitAction.isNone)

        let firstClient = firstNodeDiscoveredAction.clientsToRun.first
        #expect(firstClient!.nodeDescription == firstNodeDescription)

        // use the first node to discover the rest of the cluster
        let clusterDiscoveredAction = stateMachine.updateValkeyServiceNodes(cluster)
        #expect(clusterDiscoveredAction.voters.count == 2)
        #expect(clusterDiscoveredAction.clientsToRun.count == 2)

        let discoveredAction = try stateMachine.valkeyClusterDiscoverySucceeded(.init(cluster))
        #expect(discoveredAction.cancelTimer === circuitBreakerCancelToken)
        #expect(discoveredAction.waitersToSucceed.count == 1)
        #expect(discoveredAction.waitersToSucceed.first === successNotifier)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func runCircuitBreakerWillOpenIfDiscoveryIsntSuccessfulWithinCircuitBreakerDuration() {
        let factory = MockClientFactory<ValkeyNodeDescription>()
        let clock = MockClock()
        var stateMachine = TestStateMachine(configuration: testConfiguration, poolFactory: factory, clock: clock)

        let circuitBreakerTimer = stateMachine.start()
        #expect(circuitBreakerTimer.duration == self.testConfiguration.circuitBreakerDuration)

        // register cancel handler
        let circuitBreakerCancelToken = TimerCancellationToken()
        #expect(stateMachine.registerTimerCancellationToken(circuitBreakerCancelToken, for: circuitBreakerTimer) == nil)

        // try to get shard
        #expect(throws: ValkeyClusterError.clusterIsUnavailable) {
            try stateMachine.poolFastPath(for: CollectionOfOne(HashSlot(rawValue: 100)!), nodeSelection: .primary)
        }
        // let's register for the slow path
        let successNotifier = SuccessNotifier()
        let waitAction = stateMachine.waitForHealthy(waiterID: 1, successNotifier: successNotifier)
        #expect(waitAction.isNone)

        clock.advance(to: clock.now.advanced(by: self.testConfiguration.circuitBreakerDuration))

        let timerFiredAction = stateMachine.timerFired(circuitBreakerTimer)
        guard case .failWaiters(let waiters) = timerFiredAction else {
            Issue.record()
            return
        }
        #expect(waiters.waitersToFail.count == 1)
        #expect(waiters.waitersToFail.first === successNotifier)
        #expect(waiters.error as? ValkeyClusterError == .noConsensusReachedCircuitBreakerOpen)

        // wait for healthy calls are rejected right away
        let nextSuccessNotifier = SuccessNotifier()
        let circuitedAction = stateMachine.waitForHealthy(waiterID: 2, successNotifier: nextSuccessNotifier)
        #expect(circuitedAction.isCircuited)
    }

}

@available(valkeySwift 1.0, *)
extension ValkeyClusterClientStateMachine.WaitForHealthyAction {
    var isNone: Bool {
        switch self {
        case .none: true
        case .fail, .succeed: false
        }
    }

    var isCircuited: Bool {
        switch self {
        case .fail: true
        case .none, .succeed: false
        }
    }
}
