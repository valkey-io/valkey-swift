//
// This source file is part of the valkey-swift project
// Copyright (c) 2025-2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

struct ValkeySentinelClientStateMachine<
    ConnectionPool: ValkeyNodeConnectionPool,
    ConnectionPoolFactory: ValkeyNodeConnectionPoolFactory
> where ConnectionPoolFactory.ConnectionPool == ConnectionPool, ConnectionPoolFactory.NodeDescription == ValkeyNodeClientFactory.NodeDescription {
    /// current state
    @usableFromInline
    enum State {
        struct HealthyState {
            let nodes: [ValkeyServerAddress]
        }
        struct DegradedState {
            let nodes: [ValkeyServerAddress]
        }
        case uninitialized
        case degraded(DegradedState)
        case healthy(HealthyState)
        case shutdown
    }
    @usableFromInline
    var state: State

    init(poolFactory: ConnectionPoolFactory, configuration: ValkeyClientConfiguration) {
        self.state = .uninitialized
    }
}
