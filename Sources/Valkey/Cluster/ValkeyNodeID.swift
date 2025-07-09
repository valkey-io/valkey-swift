//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Identifies a node in a Valkey cluster.
///
/// `ValkeyNodeID` uniquely represents a node in the cluster by its network location
/// (endpoint and port).
@usableFromInline
package struct ValkeyNodeID: Hashable, Sendable {
    /// The node's endpoint.
    ///
    /// This can be either a hostname (preferred) or an IP address.
    @usableFromInline
    package var endpoint: String

    /// The TCP port on which the Valkey instance is listening.
    @usableFromInline
    package var port: Int

    /// Creates a new node identifier with the specified endpoint and port.
    ///
    /// - Parameters:
    ///   - endpoint: The hostname or IP address of the Valkey node.
    ///   - port: The port number on which the node is accessible.
    @usableFromInline
    package init(endpoint: String, port: Int) {
        self.endpoint = endpoint
        self.port = port
    }
}

extension ValkeyClusterDescription.Node {
    var nodeID: ValkeyNodeID {
        ValkeyNodeID(endpoint: self.endpoint, port: self.tlsPort ?? self.port ?? 6379)
    }
}
