//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
/// A structure that represents a Valkey node in a cluster.
///
/// `ValkeyNodeDescription` encapsulates all the necessary information to identify and connect
/// to a specific Valkey node, including:
///
/// - Network endpoint information (host, IP, port)
/// - Connection security settings (TLS configuration)
///
/// This structure conforms to `Identifiable` with its `id` property generated from the endpoint
/// and port information, allowing it to be uniquely identified within collections. It also
/// conforms to `Hashable` for use in sets and as dictionary keys, and `Sendable` for safe
/// use across concurrency domains.
///
/// - Note: This type is primarily used internally by the Valkey client for node management
///         in cluster configurations.
@usableFromInline
package struct ValkeyNodeDescription: Identifiable, Hashable, Sendable {
    /// The unique identifier for this node, computed from its endpoint and port.
    ///
    /// This property satisfies the `Identifiable` protocol requirement and provides
    /// a consistent way to uniquely identify nodes across the system.
    @usableFromInline
    package var id: ValkeyNodeID {
        ValkeyNodeID(endpoint: self.endpoint, port: self.port)
    }

    /// The network endpoint (hostname or IP) used to connect to this node.
    ///
    /// This property is required and is used as part of the node's unique identifier.
    package var endpoint: String

    /// The port number on which this Valkey node is listening.
    ///
    /// This property is required and is used as part of the node's unique identifier.
    package var port: Int

    /// Is node a readonly replica
    package var readOnly: Bool

    /// Creates a node description from any type conforming to the `ValkeyNodeDescriptionProtocol`.
    ///
    /// This initializer allows for easy conversion from various node description types
    /// that conform to the common protocol interface.
    ///
    /// - Parameter description: A value conforming to `ValkeyNodeDescriptionProtocol` that provides
    ///                         the necessary node information.
    package init(description: any ValkeyNodeDescriptionProtocol) {
        self.endpoint = description.endpoint
        self.port = description.port
        self.readOnly = description.readOnly
    }

    /// Creates a node description.
    ///
    /// - Parameter description: A value conforming to `ValkeyNodeDescriptionProtocol` that provides
    ///                         the necessary node information.
    package init(endpoint: String, port: Int, readOnly: Bool) {
        self.endpoint = endpoint
        self.port = port
        self.readOnly = readOnly
    }

    /// Creates a node description from a cluster node description.
    ///
    /// This initializer converts a `ValkeyClusterDescription.Node` to a `ValkeyNodeDescription`,
    /// handling the appropriate mapping of fields and setting default values when necessary.
    ///
    /// - Parameter description: A `ValkeyClusterDescription.Node` instance.
    /// - Note: If both TLS and regular ports are available, the TLS port takes precedence.
    ///         If no port is specified, the default Valkey port (6379) is used.
    package init(description: ValkeyClusterDescription.Node) {
        self.endpoint = description.endpoint
        self.port = description.tlsPort ?? description.port ?? 6379
        self.readOnly = description.role == .replica
    }

    /// Creates a node description from a redirection error.
    ///
    /// This initializer converts a `ValkeyClusterRedirectionError` to a `ValkeyNodeDescription`.
    ///
    /// - Parameter redirectionError: A `ValkeyClusterRedirectionError` instance.
    package init(redirectionError: ValkeyClusterRedirectionError) {
        self.endpoint = redirectionError.endpoint
        self.port = redirectionError.port
        self.readOnly = false
    }

    /// Determines whether this node description matches a given cluster node description.
    ///
    /// This method compares the essential connection properties of this node with
    /// another node description to determine if they refer to the same logical node.
    ///
    /// - Parameter other: The `ValkeyClusterDescription.Node` to compare against.
    /// - Returns: `true` if the nodes match (refer to the same logical node), otherwise `false`.
    func matches(_ other: ValkeyClusterDescription.Node) -> Bool {
        self.endpoint == other.endpoint
            && self.port == other.tlsPort ?? other.port ?? 6379
    }
}
