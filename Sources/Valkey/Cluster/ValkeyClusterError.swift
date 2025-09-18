//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

/// Errors thrown from ValkeyClusterClient
public struct ValkeyClusterError: Error, Equatable {
    private enum Internal: Error, Equatable {
        case clusterIsMissingSlotAssignment
        case clusterIsMissingMovedErrorNode
        case shardIsMissingPrimaryNode
        case shardHasMultiplePrimaryNodes
        case noNodeToTalkTo
        case serverDiscoveryFailedNoKnownNode
        case keysRequireMultipleNodes
        case keysInCommandRequireMultipleHashSlots
        case clusterIsUnavailable
        case noConsensusReachedCircuitBreakerOpen
        case clusterHasNoNodes
        case clusterClientIsShutDown
        case clientRequestCancelled
        case waitedForDiscoveryAfterMovedErrorThreeTimes
    }
    private let value: Internal
    private init(_ value: Internal) {
        self.value = value
    }

    /// Slot is not assigned to any shard
    static public var clusterIsMissingSlotAssignment: Self { .init(.clusterIsMissingSlotAssignment) }
    /// We don't have a node for a shard associated with move error.
    static public var clusterIsMissingMovedErrorNode: Self { .init(.clusterIsMissingMovedErrorNode) }
    /// Shard in cluster description is missing a primary node
    static public var shardIsMissingPrimaryNode: Self { .init(.shardIsMissingPrimaryNode) }
    /// Shard in cluster description has multiple primary node
    static public var shardHasMultiplePrimaryNodes: Self { .init(.shardHasMultiplePrimaryNodes) }
    /// Not current used
    static public var noNodeToTalkTo: Self { .init(.noNodeToTalkTo) }
    /// Not current used
    static public var serverDiscoveryFailedNoKnownNode: Self { .init(.serverDiscoveryFailedNoKnownNode) }
    /// Keys require multiple nodes
    static public var keysRequireMultipleNodes: Self { .init(.keysRequireMultipleNodes) }
    /// Keys in command require multiple hash slots
    static public var keysInCommandRequireMultipleHashSlots: Self { .init(.keysInCommandRequireMultipleHashSlots) }
    /// Cluster is currently unavailable
    static public var clusterIsUnavailable: Self { .init(.clusterIsUnavailable) }
    /// No consensus about cluster state was reached in time
    static public var noConsensusReachedCircuitBreakerOpen: Self { .init(.noConsensusReachedCircuitBreakerOpen) }
    /// Cluster has no nodes
    static public var clusterHasNoNodes: Self { .init(.clusterHasNoNodes) }
    /// Cluster client is shutdown
    static public var clusterClientIsShutDown: Self { .init(.clusterClientIsShutDown) }
    /// Request was cancelled
    static public var clientRequestCancelled: Self { .init(.clientRequestCancelled) }
    /// Wait for discovery failed three times after receiving a MOVED error
    static public var waitedForDiscoveryAfterMovedErrorThreeTimes: Self { .init(.waitedForDiscoveryAfterMovedErrorThreeTimes) }

}
