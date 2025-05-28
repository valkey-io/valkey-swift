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

/// Allows the cluster client to initially find at least one node in the cluster or find the
/// nodes again if connection to the has been lost.
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
///     .init(host: "replica1.valkey.io", port: 10600, useTLS: false),
///     .init(ip: "192.168.12.1", port: 10600, useTLS: true)
/// ]
/// ```
public struct ValkeyStaticNodeDiscovery: ValkeyNodeDiscovery {
    /// A description of a single node in the Valkey cluster.
    public struct NodeDescription: ValkeyNodeDescriptionProtocol {
        public var host: String?
        public var ip: String?
        public var endpoint: String
        public var port: Int
        public var useTLS: Bool

        /// Initializes a `NodeDescription` with a host and optional IP.
        ///
        /// - Parameters:
        ///   - host: The host name of the node.
        ///   - ip: The optional IP address of the node.
        ///   - port: The port number the node listens on (default is 6379).
        ///   - useTLS: A boolean indicating whether TLS should be used (default is true).
        public init(host: String, ip: String? = nil, port: Int = 6379, useTLS: Bool = true) {
            self.host = host
            self.ip = ip
            self.endpoint = host
            self.port = port
            self.useTLS = useTLS
        }

        /// Initializes a `NodeDescription` with an IP address.
        ///
        /// - Parameters:
        ///   - ip: The IP address of the node.
        ///   - port: The port number the node listens on (default is 6379).
        ///   - useTLS: A boolean indicating whether TLS should be used (default is false).
        public init(ip: String, port: Int = 6379, useTLS: Bool = false) {
            self.host = nil
            self.ip = ip
            self.endpoint = ip
            self.port = port
            self.useTLS = useTLS
        }
    }

    private var nodes: [NodeDescription]

    /// Initializes a ``ValkeyStaticClusterDiscovery`` with a list of nodes.
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
