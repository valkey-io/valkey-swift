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
        SuccessNotifier,
        TimerCancellationToken
    >
    @available(valkeySwift 1.0, *)
    var testConfiguration: TestStateMachine.Configuration {
        .init()
    }

    @Test
    @available(valkeySwift 1.0, *)
    func runDiscoveryAfterStartup() throws {
        let factory = MockClientFactory<ValkeyNodeDescription>()
        var stateMachine = TestStateMachine(poolFactory: factory, configuration: .init())
        let initialNodes = (9000..<9002).map { ValkeyNodeDescription(endpoint: "127.0.0.1", port: $0) }
        let additionalNodes = (9002..<9004).map { ValkeyNodeDescription(endpoint: "127.0.0.1", port: $0) }

        let updateAction = stateMachine.updateSentinelNodes(.init(initialNodes))
        #expect(Set(updateAction.clientsToRun.map { $0.nodeDescription.id }) == Set(initialNodes.map { $0.id }))
        #expect(updateAction.clientsToShutdown.isEmpty)
        #expect(Set(updateAction.voters.map { $0.nodeID }) == Set(initialNodes.map { $0.id }))

        let succeededAction = stateMachine.topologyDiscoverySucceeded(.init(initialNodes + additionalNodes))
        #expect(Set(succeededAction.clientsToRun.map { $0.nodeDescription.id }) == Set(additionalNodes.map { $0.id }))
        #expect(succeededAction.clientsToShutdown.isEmpty)
    }
}
