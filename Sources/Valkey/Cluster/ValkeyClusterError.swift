//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift project
//
// Copyright (c) 2025 the valkey-swift authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See valkey-swift/CONTRIBUTORS.txt for the list of valkey-swift authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

@usableFromInline
package enum ValkeyClusterError: Error {
    case clusterIsMissingSlotAssignment
    case clusterIsMissingMovedErrorNode
    case shardIsMissingMasterNode
    case shardHasMultipleMasterNodes
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
