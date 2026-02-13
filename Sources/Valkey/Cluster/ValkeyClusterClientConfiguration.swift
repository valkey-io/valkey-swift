//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

@available(valkeySwift 1.0, *)
/// Configuration for ValkeyClusterClient
public struct ValkeyClusterClientConfiguration: Sendable {
    /// Configuration for underlying Valkey client connections
    public var client: ValkeyClientConfiguration

    /// Maximum number of times we follow a MOVE/ASK error before failing a request
    public var maximumNumberOfRedirects: Int

    /// How frequently cluster topology is refreshed
    public var clusterRefreshInterval: Duration

    /// The duration after which the cluster client rejects all requests, because it can't find a cluster consensus
    public var clusterConsensusCircuitBreaker: Duration

    /// Initialize ValkeyClusterClientConfiguration
    /// - Parameters:
    ///   - client: Configuration for underlying Valkey client connections
    ///   - maximumNumberOfRedirects: Maximum number of times we follow a MOVE/ASK error before failing a request
    ///   - clusterRefreshInterval: How frequently cluster topology is refreshed
    ///   - clusterConsensusCircuitBreaker: The duration after which the cluster client rejects all requests, because
    ///         it can't find a cluster consensus
    init(
        client: ValkeyClientConfiguration = .init(),
        maximumNumberOfRedirects: Int = 4,
        clusterRefreshInterval: Duration = .seconds(30),
        clusterConsensusCircuitBreaker: Duration = .seconds(30)
    ) {
        // disable client capa redirect for cluster
        var client = client
        client.enableClientCapaRedirect = false

        self.client = client
        self.maximumNumberOfRedirects = maximumNumberOfRedirects
        self.clusterRefreshInterval = clusterRefreshInterval
        self.clusterConsensusCircuitBreaker = clusterConsensusCircuitBreaker
    }
}
