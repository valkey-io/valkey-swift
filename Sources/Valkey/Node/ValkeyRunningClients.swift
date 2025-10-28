//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
@usableFromInline
@available(valkeySwift 1.0, *)
struct ValkeyRunningClientsStateMachine<
    ConnectionPool: Sendable,
    ConnectionPoolFactory: ValkeyNodeConnectionPoolFactory
> where ConnectionPoolFactory.ConnectionPool == ConnectionPool, ConnectionPoolFactory.NodeDescription: Sendable & Identifiable & Equatable {
    @usableFromInline typealias NodeDescription = ConnectionPoolFactory.NodeDescription
    @usableFromInline
    /* private */ struct NodeBundle: Sendable {
        @usableFromInline
        var nodeID: NodeDescription.ID { self.nodeDescription.id }
        @usableFromInline
        var pool: ConnectionPool
        @usableFromInline
        var nodeDescription: NodeDescription
    }
    let poolFactory: ConnectionPoolFactory
    @usableFromInline
    var clientMap: [NodeDescription.ID: NodeBundle]
    @inlinable
    var clients: some Collection<NodeBundle> { clientMap.values }

    init(poolFactory: ConnectionPoolFactory) {
        self.poolFactory = poolFactory
        self.clientMap = [:]
    }

    struct PoolUpdateAction {
        var poolsToShutdown: [ConnectionPool]
        var poolsToRun: [(ConnectionPool, NodeDescription.ID)]

        static func empty() -> PoolUpdateAction { PoolUpdateAction(poolsToShutdown: [], poolsToRun: []) }
    }

    mutating func updateNodes(
        _ newNodes: some Collection<NodeDescription>,
        removeUnmentionedPools: Bool
    ) -> PoolUpdateAction {
        var previousNodes = self.clientMap
        self.clientMap.removeAll(keepingCapacity: true)
        var newPools = [(ConnectionPool, NodeDescription.ID)]()
        newPools.reserveCapacity(16)
        var poolsToShutdown = [ConnectionPool]()

        for newNodeDescription in newNodes {
            // if we had a pool previously, let's continue to use it!
            if let existingPool = previousNodes.removeValue(forKey: newNodeDescription.id) {
                if newNodeDescription == existingPool.nodeDescription {
                    // the existing pool matches the new node description. nothing todo
                    self.clientMap[newNodeDescription.id] = existingPool
                } else {
                    // the existing pool does not match new node description. For example it might be swapping between
                    // readonly and readwrite state
                    poolsToShutdown.append(existingPool.pool)
                    let newPool = self.makePool(for: newNodeDescription)
                    self.clientMap[newNodeDescription.id] = NodeBundle(pool: newPool, nodeDescription: newNodeDescription)
                    newPools.append((newPool, newNodeDescription.id))
                }
            } else {
                let newPool = self.makePool(for: newNodeDescription)
                self.clientMap[newNodeDescription.id] = NodeBundle(pool: newPool, nodeDescription: newNodeDescription)
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
            self.clientMap[nodeID] = poolDescription
        }

        return PoolUpdateAction(
            poolsToShutdown: poolsToShutdown,
            poolsToRun: newPools
        )
    }

    enum AddNodeAction {
        case useExistingPool(ConnectionPool)
        case runAndUsePool(ConnectionPool)
    }

    mutating func addNode(
        _ node: NodeDescription
    ) -> AddNodeAction {
        if let pool = self.clientMap[node.id] {
            return .useExistingPool(pool.pool)
        }
        let newPool = self.makePool(for: node)
        self.clientMap[node.id] = NodeBundle(pool: newPool, nodeDescription: node)
        return .runAndUsePool(newPool)
    }

    @inlinable
    subscript(_ index: NodeDescription.ID) -> NodeBundle? {
        self.clientMap[index]
    }

    @usableFromInline
    mutating func removeAll() {
        self.clientMap.removeAll(keepingCapacity: false)
    }

    func makePool(for description: NodeDescription) -> ConnectionPool {
        self.poolFactory.makeConnectionPool(nodeDescription: description)
    }
}
