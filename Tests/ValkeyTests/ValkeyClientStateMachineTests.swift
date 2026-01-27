//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import Testing

@testable import Valkey

struct ValkeyClientStateMachineTests {
    @available(valkeySwift 1.0, *)
    typealias TestStateMachine = ValkeyClientStateMachine<
        MockClient<ValkeyClientNodeDescription>,
        MockClientFactory<ValkeyClientNodeDescription>
    >

    @Test
    @available(valkeySwift 1.0, *)
    func testSetGetPrimary() {
        let factory = MockClientFactory<ValkeyClientNodeDescription>()
        var stateMachine = TestStateMachine(poolFactory: factory, configuration: .init())
        switch stateMachine.setPrimary(.hostname("127.0.0.1", port: 9000)) {
        case .runNode(let client):
            #expect(client.nodeDescription.address == .hostname("127.0.0.1", port: 9000))
        default:
            Issue.record()
        }

        #expect(stateMachine.getNode(.primary).nodeDescription.address == .hostname("127.0.0.1", port: 9000))
        #expect(stateMachine.getNode(.cycleAllNodes(4)).nodeDescription.address == .hostname("127.0.0.1", port: 9000))
        #expect(stateMachine.getNode(.cycleReplicas(4)).nodeDescription.address == .hostname("127.0.0.1", port: 9000))
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testSetPrimaryAndReplicas() {
        let factory = MockClientFactory<ValkeyClientNodeDescription>()
        var stateMachine = TestStateMachine(poolFactory: factory, configuration: .init(readOnlyCommandNodeSelection: .cycleReplicas))
        switch stateMachine.setPrimary(.hostname("127.0.0.1", port: 9000)) {
        case .runNodeAndFindReplicas(let client):
            #expect(client.nodeDescription.address == .hostname("127.0.0.1", port: 9000))
        default:
            Issue.record()
        }

        let addReplicasAction = stateMachine.addReplicas(nodeIDs: [.hostname("127.0.0.1", port: 9001), .hostname("127.0.0.1", port: 9002)])
        #expect(addReplicasAction.clientsToRun.count == 2)
        #expect(addReplicasAction.clientsToRun[0].nodeDescription.address == .hostname("127.0.0.1", port: 9001))
        #expect(addReplicasAction.clientsToRun[1].nodeDescription.address == .hostname("127.0.0.1", port: 9002))
        #expect(addReplicasAction.clientsToShutdown.count == 0)

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
        switch stateMachine.setPrimary(.hostname("127.0.0.1", port: 9000)) {
        case .runNodeAndFindReplicas(let client):
            #expect(client.nodeDescription.address == .hostname("127.0.0.1", port: 9000))
        default:
            Issue.record()
        }
        switch stateMachine.setPrimary(.hostname("127.0.0.1", port: 9000)) {
        case .doNothing:
            break
        default:
            Issue.record()
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testReplaceReplicas() {
        let factory = MockClientFactory<ValkeyClientNodeDescription>()
        var stateMachine = TestStateMachine(poolFactory: factory, configuration: .init(readOnlyCommandNodeSelection: .cycleReplicas))
        _ = stateMachine.setPrimary(.hostname("127.0.0.1", port: 9000))
        _ = stateMachine.addReplicas(nodeIDs: [.hostname("127.0.0.1", port: 9001), .hostname("127.0.0.1", port: 9002)])
        let addReplicasAction = stateMachine.addReplicas(nodeIDs: [.hostname("127.0.0.1", port: 9002), .hostname("127.0.0.1", port: 9003)])
        #expect(addReplicasAction.clientsToRun.count == 1)
        #expect(addReplicasAction.clientsToRun[0].nodeDescription.address == .hostname("127.0.0.1", port: 9003))
        #expect(addReplicasAction.clientsToShutdown.count == 1)
        #expect(addReplicasAction.clientsToShutdown[0].nodeDescription.address == .hostname("127.0.0.1", port: 9001))

        #expect(stateMachine.getNode(.primary).nodeDescription.address == .hostname("127.0.0.1", port: 9000))
        #expect(stateMachine.getNode(.cycleReplicas(0)).nodeDescription.address == .hostname("127.0.0.1", port: 9002))
        #expect(stateMachine.getNode(.cycleReplicas(1)).nodeDescription.address == .hostname("127.0.0.1", port: 9003))
        #expect(stateMachine.getNode(.cycleReplicas(2)).nodeDescription.address == .hostname("127.0.0.1", port: 9002))
    }
}
