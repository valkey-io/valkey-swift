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

@usableFromInline
package enum ValkeyClusterError: Error {
    case clusterIsMissingSlotAssignment
    case clusterIsMissingMovedErrorNode
    case shardIsMissingPrimaryNode
    case shardHasMultiplePrimaryNodes
    case noNodeToTalkTo
    case serverDiscoveryFailedNoKnownNode
    case keysInCommandRequireMultipleNodes
    case clusterIsUnavailable
    case noConsensusReachedCircuitBreakerOpen
    case clusterHasNoNodes
    case clusterClientIsShutDown
    case clientRequestCancelled
    case waitedForDiscoveryAfterMovedErrorThreeTimes
}
