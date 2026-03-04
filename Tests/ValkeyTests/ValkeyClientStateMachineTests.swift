//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import Testing

@testable import Valkey

struct ClientTestsTimerCancellationToken: Sendable {
    var id: Int
}

struct ValkeyClientStateMachineTests {
    @available(valkeySwift 1.0, *)
    typealias TestStateMachine = ValkeyClientStateMachine<
        MockClient<ValkeyClientNodeDescription>,
        MockClientFactory<ValkeyClientNodeDescription>,
        ClientTestsTimerCancellationToken
    >

    @available(valkeySwift 1.0, *)
    @discardableResult
    func runInitialStates(
        stateMachine: inout TestStateMachine,
        primary: ValkeyServerAddress = .hostname("127.0.0.1", port: 9000),
        replicas: [ValkeyServerAddress] = [.hostname("127.0.0.1", port: 9001), .hostname("127.0.0.1", port: 9002)]
    ) -> ValkeyTimer? {
        // set primary
        let setPrimaryAction = stateMachine.setPrimary(.hostname("127.0.0.1", port: 9000))
        #expect(setPrimaryAction.nodeToRun?.nodeDescription.address == .hostname("127.0.0.1", port: 9000))
        switch setPrimaryAction.nextAction {
        case .doNothing:
            // if do nothing verify we aren't looking for replicas
            #expect(stateMachine.configuration.findReplicas == false)
            return nil

        case .refreshTopology(let cancelTimer):
            #expect(stateMachine.configuration.findReplicas == true)
            #expect(cancelTimer == nil)

            // replicas found, should return timer for topology refresh
            let refreshAction = stateMachine.topologyRefreshSucceeded(
                primary: nil,
                replicas: replicas
            )
            guard case .startTimer(let timer) = refreshAction.nextAction else {
                Issue.record()
                return nil
            }
            #expect(timer.timerID == 0)
            #expect(timer.useCase == .nextTopologyDiscovery)
            #expect(refreshAction.clientsToRun.count == 2)
            #expect(refreshAction.clientsToRun[0].nodeDescription.address == replicas[0])
            #expect(refreshAction.clientsToRun[1].nodeDescription.address == replicas[1])
            #expect(refreshAction.clientsToShutdown.count == 0)

            // register timer cancellation token
            let registerTimer = stateMachine.registerTimerCancellationToken(.init(id: 1), for: timer)
            guard case .doNothing = registerTimer else {
                Issue.record()
                return nil
            }
            return timer
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testSetGetPrimary() {
        let factory = MockClientFactory<ValkeyClientNodeDescription>()
        var stateMachine = TestStateMachine(poolFactory: factory, configuration: .init())

        runInitialStates(stateMachine: &stateMachine)

        #expect(stateMachine.getNode(.primary).nodeDescription.address == .hostname("127.0.0.1", port: 9000))
        #expect(stateMachine.getNode(.cycleAllNodes(4)).nodeDescription.address == .hostname("127.0.0.1", port: 9000))
        #expect(stateMachine.getNode(.cycleReplicas(4)).nodeDescription.address == .hostname("127.0.0.1", port: 9000))
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testSetPrimaryAndReplicas() {
        let factory = MockClientFactory<ValkeyClientNodeDescription>()
        var stateMachine = TestStateMachine(poolFactory: factory, configuration: .init(readOnlyCommandNodeSelection: .cycleReplicas))

        runInitialStates(stateMachine: &stateMachine)

        #expect(stateMachine.getNode(.primary).nodeDescription.address == .hostname("127.0.0.1", port: 9000))
        #expect(stateMachine.getNode(.cycleAllNodes(0)).nodeDescription.address == .hostname("127.0.0.1", port: 9000))
        #expect(stateMachine.getNode(.cycleAllNodes(1)).nodeDescription.address == .hostname("127.0.0.1", port: 9001))
        #expect(stateMachine.getNode(.cycleAllNodes(2)).nodeDescription.address == .hostname("127.0.0.1", port: 9002))
        #expect(stateMachine.getNode(.cycleAllNodes(3)).nodeDescription.address == .hostname("127.0.0.1", port: 9000))
        #expect(stateMachine.getNode(.cycleReplicas(0)).nodeDescription.address == .hostname("127.0.0.1", port: 9001))
        #expect(stateMachine.getNode(.cycleReplicas(1)).nodeDescription.address == .hostname("127.0.0.1", port: 9002))
        #expect(stateMachine.getNode(.cycleReplicas(2)).nodeDescription.address == .hostname("127.0.0.1", port: 9001))
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testSetPrimaryCalledTwice() {
        let factory = MockClientFactory<ValkeyClientNodeDescription>()
        var stateMachine = TestStateMachine(poolFactory: factory, configuration: .init(readOnlyCommandNodeSelection: .cycleReplicas))

        runInitialStates(stateMachine: &stateMachine)

        switch stateMachine.setPrimary(.hostname("127.0.0.1", port: 9000)).nextAction {
        case .doNothing:
            break
        default:
            Issue.record()
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testReplaceReplicas() throws {
        let factory = MockClientFactory<ValkeyClientNodeDescription>()
        var stateMachine = TestStateMachine(poolFactory: factory, configuration: .init(readOnlyCommandNodeSelection: .cycleReplicas))

        let timer = try #require(runInitialStates(stateMachine: &stateMachine))

        let timerFired = stateMachine.timerFired(timer)
        #expect(timerFired == .runRole)
        let refreshAction2 = stateMachine.topologyRefreshSucceeded(
            primary: nil,
            replicas: [.hostname("127.0.0.1", port: 9002), .hostname("127.0.0.1", port: 9003)]
        )

        #expect(refreshAction2.clientsToRun.count == 1)
        #expect(refreshAction2.clientsToRun[0].nodeDescription.address == .hostname("127.0.0.1", port: 9003))
        #expect(refreshAction2.clientsToShutdown.count == 1)
        #expect(refreshAction2.clientsToShutdown[0].nodeDescription.address == .hostname("127.0.0.1", port: 9001))

        #expect(stateMachine.getNode(.primary).nodeDescription.address == .hostname("127.0.0.1", port: 9000))
        #expect(stateMachine.getNode(.cycleReplicas(0)).nodeDescription.address == .hostname("127.0.0.1", port: 9002))
        #expect(stateMachine.getNode(.cycleReplicas(1)).nodeDescription.address == .hostname("127.0.0.1", port: 9003))
        #expect(stateMachine.getNode(.cycleReplicas(2)).nodeDescription.address == .hostname("127.0.0.1", port: 9002))
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testSetPrimaryDuringTopologyRefresh() throws {
        let factory = MockClientFactory<ValkeyClientNodeDescription>()
        var stateMachine = TestStateMachine(poolFactory: factory, configuration: .init(readOnlyCommandNodeSelection: .cycleReplicas))

        let timer = try #require(runInitialStates(stateMachine: &stateMachine))

        // timer fired
        let timerFired = stateMachine.timerFired(timer)
        #expect(timerFired == .runRole)
        // set primary is called
        let setPrimaryAction = stateMachine.setPrimary(.hostname("127.0.0.1", port: 9002))
        guard case .doNothing = setPrimaryAction.nextAction else {
            Issue.record()
            return
        }
        // topology refresh
        _ = stateMachine.topologyRefreshSucceeded(
            primary: nil,
            replicas: [.hostname("127.0.0.1", port: 9001), .hostname("127.0.0.1", port: 9003)]
        )
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testSetPrimaryDuringTopologyWaitingForRefresh() throws {
        let factory = MockClientFactory<ValkeyClientNodeDescription>()
        var stateMachine = TestStateMachine(poolFactory: factory, configuration: .init(readOnlyCommandNodeSelection: .cycleReplicas))

        let timer = try #require(runInitialStates(stateMachine: &stateMachine))

        // set primary
        let setPrimaryAction = stateMachine.setPrimary(.hostname("127.0.0.1", port: 9002))
        guard case .refreshTopology(let cancelTimer) = setPrimaryAction.nextAction else {
            Issue.record()
            return
        }
        #expect(cancelTimer?.id == 1)
        // topology refresh
        let refreshAction = stateMachine.topologyRefreshSucceeded(
            primary: nil,
            replicas: [.hostname("127.0.0.1", port: 9001), .hostname("127.0.0.1", port: 9003)]
        )
        guard case .startTimer(let timer2) = refreshAction.nextAction else {
            Issue.record()
            return
        }
        #expect(timer2.timerID == 1)
        #expect(timer2.useCase == .nextTopologyDiscovery)

        // verify original timer now does nothing
        let timerFired = stateMachine.timerFired(timer)
        #expect(timerFired == .doNothing)
    }
}
