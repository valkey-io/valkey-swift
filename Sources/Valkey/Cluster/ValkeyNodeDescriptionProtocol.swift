//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore

/// A description of a single node that is part of a Valkey cluster.
///
/// This protocol defines the minimum information needed to identify and connect to a Valkey server node.
/// It plays a crucial role in the ``ValkeyNodeDiscovery`` mechanism, primarily used to initially find
/// members of a Valkey cluster or reconnect when connections are lost.
///
/// Implementations of this protocol are typically returned by discovery services to provide
/// the necessary information for establishing connections to cluster nodes. The discovery process
/// is the first step in cluster operations, allowing clients to locate available nodes before
/// initiating commands or transactions.
///
/// The protocol requires both hostname and IP address properties to be available, though either may be nil
/// depending on how the node is identified. The ``endpoint`` property provides the actual connection target.
public protocol ValkeyNodeDescriptionProtocol: Sendable, Equatable {
    /// The node's connection endpoint string.
    ///
    /// This should typically be the hostname if the node has a routable hostname,
    /// otherwise it should be the ip. This property is used to establish
    /// network connections to the node.
    var endpoint: String { get }

    /// The port number on which the Valkey service is listening.
    var port: Int { get }

    /// Is node a readonly replica.
    var readOnly: Bool { get }
}
