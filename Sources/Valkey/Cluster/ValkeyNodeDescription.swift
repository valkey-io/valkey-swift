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

    /// The hostname of the Valkey node, if available.
    ///
    /// This may be `nil` if the node is only known by IP address.
    package var host: String?

    /// The IP address of the Valkey node, if available.
    ///
    /// This may be `nil` if the node is only known by hostname.
    package var ip: String?

    /// The network endpoint (hostname or IP) used to connect to this node.
    ///
    /// This property is required and is used as part of the node's unique identifier.
    package var endpoint: String

    /// The port number on which this Valkey node is listening.
    ///
    /// This property is required and is used as part of the node's unique identifier.
    package var port: Int

    /// Indicates whether TLS/SSL should be used when connecting to this node.
    ///
    /// When `true`, the connection will use secure transport with TLS.
    package var useTLS: Bool

    /// Creates a node description from any type conforming to the `ValkeyNodeDescriptionProtocol`.
    ///
    /// This initializer allows for easy conversion from various node description types
    /// that conform to the common protocol interface.
    ///
    /// - Parameter description: A value conforming to `ValkeyNodeDescriptionProtocol` that provides
    ///                         the necessary node information.
    package init(description: any ValkeyNodeDescriptionProtocol) {
        self.host = description.host
        self.ip = description.ip
        self.endpoint = description.endpoint
        self.port = description.port
        self.useTLS = description.useTLS
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
        self.host = description.hostname
        self.ip = description.ip
        self.endpoint = description.endpoint
        self.port = description.tlsPort ?? description.port ?? 6379
        self.useTLS = description.tlsPort != nil
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
            && self.useTLS == (other.tlsPort != nil)
    }
}
