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
public protocol ValkeyClusterDiscovery {
    /// A type that describes a single node in a valkey cluster
    associatedtype NodeDescription: ValkeyNodeDescriptionProtocol

    /// A type that describes multiple nodes in a valkey cluster
    associatedtype NodeDescriptions: Collection<NodeDescription>

    /// Lookup all the nodes within the cluster.
    func lookupNodes() async throws -> NodeDescriptions
}

/// A description of a single node that is part of a valkey cluster
public protocol ValkeyNodeDescriptionProtocol: Sendable, Equatable {
    /// The node's host name.
    var host: String? { get }
    /// The node's ip address.
    var ip: String? { get }
    /// The nodes endpoint. This should normally be the ``host`` if the node has a routable hostname.
    /// Otherwise it is the ``ip``. This property is used to create connections to the node.
    var endpoint: String { get }
    /// The node's redis port
    var port: Int { get }
    /// Defines if TLS shall be used to create a connection to the node
    var useTLS: Bool { get }
}

public struct ValkeyStaticClusterDiscovery: ValkeyClusterDiscovery {

    public struct NodeDescription: ValkeyNodeDescriptionProtocol {
        public var host: String?
        public var ip: String?
        public var endpoint: String
        public var port: Int
        public var useTLS: Bool

        public init(host: String, ip: String? = nil, port: Int = 5678, useTLS: Bool = true) {
            self.host = host
            self.ip = ip
            self.endpoint = host
            self.port = port
            self.useTLS = useTLS
        }

        public init(ip: String, port: Int = 5678, useTLS: Bool = false) {
            self.host = nil
            self.ip = ip
            self.endpoint = ip
            self.port = port
            self.useTLS = useTLS
        }
    }

    private var nodes: [NodeDescription]

    public init(_ nodes: [NodeDescription]) {
        self.nodes = nodes
    }

    public func lookupNodes() -> [NodeDescription] {
        self.nodes
    }
}
