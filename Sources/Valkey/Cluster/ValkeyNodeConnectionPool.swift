//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore
import NIOSSL

/// A connection pool against a node
@usableFromInline
@available(valkeySwift 1.0, *)
package protocol ValkeyNodeConnectionPool: AnyObject, Sendable {
    /// Function that process background events, cancel the task or call ``triggerShutdown`` to
    /// shutdown the server
    func run() async

    /// Triggers the ConnectionPool to gracefully shutdown. This will lead cause the ``run`` method to terminate.
    func triggerGracefulShutdown()
}

/// A connection pool factory that creates `ConnectionPool`s
@usableFromInline
@available(valkeySwift 1.0, *)
package protocol ValkeyNodeConnectionPoolFactory: Sendable {
    associatedtype ConnectionPool: ValkeyNodeConnectionPool

    /// Create a shard connection pool based on the provided configuration
    func makeConnectionPool(
        nodeDescription: ValkeyNodeDescription
    ) -> ConnectionPool
}
