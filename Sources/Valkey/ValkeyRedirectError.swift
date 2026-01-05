//
// This source file is part of the valkey-swift project
// Copyright (c) 2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore

/// Represents a `REDIRECT` redirection error from a Valkey replica node.
///
/// When a client sends a command to a Valkey replica when CAPA redirect is enabled
/// the node responds with a `REDIECT` error containing information about the primary node.
///
/// This error provides the necessary information for clients to redirect their
/// request to the correct node in the cluster.
@usableFromInline
package struct ValkeyRedirectError: Hashable, Sendable {
    /// The hostname or IP address of the node that owns the requested hash slot.
    package var endpoint: String

    /// The port number of the node that owns the requested hash slot.
    package var port: Int

    package init(endpoint: String, port: Int) {
        self.endpoint = endpoint
        self.port = port
    }

    @usableFromInline
    package var nodeID: ValkeyNodeID {
        ValkeyNodeID(endpoint: self.endpoint, port: self.port)
    }
}

extension ValkeyRedirectError {
    static let redirectPrefix = "REDIRECT "

    /// Attempts to parse a Valkey REDIRECT error from a String.
    ///
    /// This method extracts the endpoint and port information from the string
    /// if it represents a Valkey REDIRECT error. REDIRECT errors are returned by Valkey replica
    /// nodes when a client attempts to access a key when CAPA redirect is enabled.
    ///
    /// The error format is expected to be: `"REDIRECT <endpoint>:<port>"`
    ///
    /// - Returns: A `ValkeyRedirectError` if the token represents a valid REDIRECT error, or `nil` otherwise.
    @usableFromInline
    init?(_ errorMessage: String) {
        guard errorMessage.hasPrefix(Self.redirectPrefix) else {
            return nil
        }

        let msg = errorMessage.dropFirst(Self.redirectPrefix.count)
        let firstEndpointIndex = msg.startIndex

        guard let colonIndex = msg[firstEndpointIndex...].lastIndex(of: ":") else {
            return nil
        }

        let firstPortIndex = msg.index(after: colonIndex)

        let endpoint = msg[firstEndpointIndex..<colonIndex]
        guard let port = Int(msg[firstPortIndex...]) else {
            return nil
        }

        self = ValkeyRedirectError(endpoint: Swift.String(endpoint), port: port)
    }
}
