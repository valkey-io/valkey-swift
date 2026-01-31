//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import Logging
import NIOCore

/// A factory for creating ``ValkeyNode`` instances to connect to specific nodes.
///
/// This factory is used by the ``ValkeyClusterClient`` to create client instances
/// for each node in the cluster as needed.
@available(valkeySwift 1.0, *)
@usableFromInline
package struct ValkeyNodeClientFactory: ValkeyNodeConnectionPoolFactory {
    var logger: Logger
    var configuration: ValkeyClientConfiguration
    var eventLoopGroup: any EventLoopGroup
    let connectionIDGenerator = ConnectionIDGenerator()
    let connectionFactory: ValkeyConnectionFactory

    /// Creates a new `ValkeyClientFactory` instance.
    ///
    /// - Parameters:
    ///   - logger: The logger used for diagnostic information.
    ///   - configuration: Configuration for the Valkey clients created by this factory.
    ///   - eventLoopGroup: The event loop group to use for client connections.
    package init(
        logger: Logger,
        configuration: ValkeyClientConfiguration,
        connectionFactory: ValkeyConnectionFactory,
        eventLoopGroup: any EventLoopGroup
    ) {
        self.logger = logger
        self.configuration = configuration
        self.connectionFactory = connectionFactory
        self.eventLoopGroup = eventLoopGroup
    }

    /// Creates a connection pool (client) for a specific node in the cluster.
    ///
    /// - Parameter nodeDescription: Description of the node to connect to.
    /// - Returns: A configured `ValkeyNode` instance ready to connect to the specified node.
    @usableFromInline
    package func makeConnectionPool(nodeDescription: ValkeyClientNodeDescription) -> ValkeyNodeClient {
        ValkeyNodeClient(
            nodeDescription.address,
            connectionIDGenerator: self.connectionIDGenerator,
            connectionFactory: self.connectionFactory,
            readOnly: configuration.readOnlyCommandNodeSelection != .primary,
            eventLoopGroup: self.eventLoopGroup,
            logger: self.logger
        )
    }
}

@usableFromInline
package struct ValkeyClientNodeDescription: Equatable, Identifiable, Sendable {
    let address: ValkeyServerAddress

    @usableFromInline
    package var id: ValkeyServerAddress { self.address }
}
