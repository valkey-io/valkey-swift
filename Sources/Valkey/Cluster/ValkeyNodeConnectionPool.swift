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

/// A connection pool against a node
@usableFromInline
package protocol ValkeyNodeConnectionPool: AnyObject, Sendable {
    /// Function that process background events, cancel the task or call ``triggerShutdown`` to
    /// shutdown the server
    func run() async

    /// Triggers the ConnectionPool to gracefully shutdown. This will lead cause the ``run`` method to terminate.
    func triggerGracefulShutdown()
}

/// A connection pool factory that creates `ConnectionPool`s
@usableFromInline
package protocol ValkeyNodeConnectionPoolFactory: Sendable {
    associatedtype ConnectionPool: ValkeyNodeConnectionPool

    /// Create a shard connection pool based on the provided configuration
    func makeConnectionPool(
        nodeDescription: ValkeyNodeDescription
    ) -> ConnectionPool
}
