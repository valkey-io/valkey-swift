//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
/// A type that allows the cluster client to initially find at least one node in the cluster, or find the
/// nodes again if connection to them has been lost.
@available(valkeySwift 1.0, *)
public protocol ValkeyNodeDiscovery: Sendable {
    /// A type that describes a single node in a valkey cluster
    associatedtype NodeDescription: ValkeyNodeDescriptionProtocol

    /// A type that describes multiple nodes in a valkey cluster
    associatedtype NodeDescriptions: Collection<NodeDescription>

    /// Lookup all the nodes within the cluster.
    ///
    /// - Returns: A collection of `NodeDescription` objects representing the nodes in the cluster.
    /// - Throws: An error if the lookup fails.
    func lookupNodes() async throws -> NodeDescriptions
}

/// A concrete implementation of ``ValkeyNodeDiscovery`` that provides a static, pre-configured
/// list of nodes in a Valkey cluster.
///
/// Use this implementation when you have a fixed set of nodes that don't change frequently.
/// It maintains an array of node descriptions that is provided at initialization time and
/// returns this static list when ``lookupNodes()`` is called.
///
/// This type conforms to `ExpressibleByArrayLiteral`, allowing you to create an instance
/// directly using an array literal syntax.
///
/// Example:
/// ```swift
/// // Using ExpressibleByArrayLiteral conformance for more concise initialization
/// let discovery: ValkeyStaticNodeDiscovery = [
///     .init(host: "replica1.valkey.io", port: 10600),
///     .init(ip: "192.168.12.1", port: 10600)
/// ]
/// ```
public struct ValkeyStaticNodeDiscovery: ValkeyNodeDiscovery {
    /// A description of a single node in the Valkey cluster.
    public struct NodeDescription: ValkeyNodeDescriptionProtocol {
        public var endpoint: String
        public var port: Int
        public var readOnly: Bool { false }

        /// Initializes a `NodeDescription` with a host and optional IP.
        ///
        /// - Parameters:
        ///   - endpoint: The node endpoint.
        ///   - port: The port number the node listens on (default is 6379).
        public init(endpoint: String, port: Int = 6379) {
            self.endpoint = endpoint
            self.port = port
        }
    }

    private var nodes: [NodeDescription]

    /// Initializes a ``ValkeyStaticNodeDiscovery`` with a list of nodes.
    ///
    /// - Parameter nodes: An array of ``ValkeyStaticNodeDiscovery/NodeDescription`` objects representing the nodes in the cluster.
    public init(_ nodes: [NodeDescription]) {
        self.nodes = nodes
    }

    /// Lookup all the nodes within the cluster.
    ///
    /// - Returns: An array of ``ValkeyStaticNodeDiscovery/NodeDescription`` objects representing the nodes in the cluster.
    public func lookupNodes() -> [NodeDescription] {
        self.nodes
    }
}

// MARK: - ExpressibleByArrayLiteral Conformance

extension ValkeyStaticNodeDiscovery: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = NodeDescription

    public init(arrayLiteral elements: ArrayLiteralElement...) {
        self.nodes = elements
    }
}
