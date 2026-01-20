//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

@usableFromInline
@available(valkeySwift 1.0, *)
struct ValkeyClientStateMachine<
    ConnectionPool: ValkeyNodeConnectionPool,
    ConnectionPoolFactory: ValkeyNodeConnectionPoolFactory
> where ConnectionPoolFactory.ConnectionPool == ConnectionPool, ConnectionPoolFactory.NodeDescription == ValkeyNodeClientFactory.NodeDescription {
    @usableFromInline
    enum State {
        case uninitialized
        case running(ValkeyNodeIDs<ValkeyServerAddress>)
    }
    @usableFromInline
    var runningClients: ValkeyRunningClientsStateMachine<ConnectionPool, ConnectionPoolFactory>
    @usableFromInline
    var state: State
    @usableFromInline
    let findReplicas: Bool

    init(poolFactory: ConnectionPoolFactory, configuration: ValkeyClientConfiguration) {
        self.runningClients = .init(poolFactory: poolFactory)
        self.state = .uninitialized
        self.findReplicas = configuration.readOnlyCommandNodeSelection != .primary
    }

    @inlinable
    func getNode(_ selection: ValkeyNodeSelection) -> ConnectionPool {
        guard case .running(let nodes) = self.state else {
            preconditionFailure("Cannot get a node if the client statemachine isn't initialized")
        }
        let nodeID = selection.select(nodeIDs: nodes)
        if let pool = self.runningClients[nodeID]?.pool {
            return pool
        } else {
            preconditionFailure()
        }
    }

    @usableFromInline
    enum SetPrimaryAction {
        case runNodeAndFindReplicas(ConnectionPool)
        case runNode(ConnectionPool)
        case findReplicas
        case doNothing
    }
    @usableFromInline
    mutating func setPrimary(_ address: ValkeyServerAddress, readOnly: Bool) -> SetPrimaryAction {
        let nodes = ValkeyNodeIDs(primary: address)
        let action = self.runningClients.addNode(.init(address: address, readOnly: readOnly))
        self.state = .running(nodes)
        if self.findReplicas {
            return switch action {
            case .useExistingPool: .findReplicas
            case .runAndUsePool(let pool): .runNodeAndFindReplicas(pool)
            }
        } else {
            return switch action {
            case .useExistingPool: .doNothing
            case .runAndUsePool(let pool): .runNode(pool)
            }
        }
    }

    struct AddReplicasAction {
        var clientsToShutdown: [ConnectionPool]
        var clientsToRun: [ConnectionPool]
    }

    mutating func addReplicas(nodeIDs: [ValkeyServerAddress]) -> AddReplicasAction {
        switch self.state {
        case .uninitialized:
            preconditionFailure("Cannot get a node if the client statemachine isn't initialized")
        case .running(let nodes):
            var nodeDescriptions = [
                ValkeyClientNodeDescription(address: nodes.primary, readOnly: false)
            ]
            nodeDescriptions.append(
                contentsOf: nodeIDs.lazy.map { ValkeyClientNodeDescription(address: $0, readOnly: true) }
            )
            let action = self.runningClients.updateNodes(nodeDescriptions, removeUnmentionedPools: true)
            let newNodes = ValkeyNodeIDs(primary: nodes.primary, replicas: nodeIDs)
            self.state = .running(newNodes)
            return .init(clientsToShutdown: action.poolsToShutdown, clientsToRun: action.poolsToRun.map { $0.0 })
        }
    }
}
