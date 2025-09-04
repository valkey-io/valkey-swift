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
> where ConnectionPoolFactory.ConnectionPool == ConnectionPool {
    @usableFromInline
    /* private */ struct NodeBundle: Sendable {
        @usableFromInline
        var nodeID: ValkeyNodeID { self.nodeDescription.id }
        @usableFromInline
        var pool: ConnectionPool
        @usableFromInline
        var nodeDescription: ValkeyNodeDescription
    }
    let poolFactory: ConnectionPoolFactory
    @usableFromInline
    var clientMap: [ValkeyNodeID: NodeBundle]
    @inlinable
    var clients: some Collection<NodeBundle> { clientMap.values }

    init(poolFactory: ConnectionPoolFactory) {
        self.poolFactory = poolFactory
        self.clientMap = [:]
    }

    struct PoolUpdateAction {
        var poolsToShutdown: [ConnectionPool]
        var poolsToRun: [(ConnectionPool, ValkeyNodeID)]

        static func empty() -> PoolUpdateAction { PoolUpdateAction(poolsToShutdown: [], poolsToRun: []) }
    }

    mutating func updateNodes(
        _ newNodes: some Collection<ValkeyNodeDescription>,
        removeUnmentionedPools: Bool
    ) -> PoolUpdateAction {
        var previousNodes = self.clientMap
        self.clientMap.removeAll(keepingCapacity: true)
        var newPools = [(ConnectionPool, ValkeyNodeID)]()
        newPools.reserveCapacity(16)
        var poolsToShutdown = [ConnectionPool]()

        for newNodeDescription in newNodes {
            // if we had a pool previously, let's continue to use it!
            if let existingPool = previousNodes.removeValue(forKey: newNodeDescription.id) {
                if newNodeDescription == existingPool.nodeDescription {
                    // the existing pool matches the new node description. nothing todo
                    self.clientMap[newNodeDescription.id] = existingPool
                } else {
                    // the existing pool does not match new node description. For example tls may now be required.
                    // shutdown the old pool and create a new one
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

    @inlinable
    subscript(_ index: ValkeyNodeID) -> NodeBundle? {
        self.clientMap[index]
    }

    @usableFromInline
    mutating func removeAll() {
        self.clientMap.removeAll(keepingCapacity: false)
    }

    func makePool(for description: ValkeyNodeDescription) -> ConnectionPool {
        self.poolFactory.makeConnectionPool(nodeDescription: description)
    }
}
