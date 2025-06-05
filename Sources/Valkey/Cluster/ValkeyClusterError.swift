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
}

