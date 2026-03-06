//
// This source file is part of the valkey-swift project
// Copyright (c) 2025-2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

/// Errors thrown from ValkeySentinelError
public struct ValkeySentinelError: Error, Equatable {
    private enum Internal: Error, Equatable {
        case sentinelIsUnavailable
        case sentinelNoConsensusReached
        case sentinelUnknownPrimary
    }
    private let value: Internal
    private init(_ value: Internal) {
        self.value = value
    }

    /// Sentinel is unavailable
    static public var sentinelIsUnavailable: Self { .init(.sentinelIsUnavailable) }
    /// No consensus on Sentinel server array reached
    static public var sentinelNoConsensusReached: Self { .init(.sentinelNoConsensusReached) }
    /// Sentinel does not know about requested primary
    static public var sentinelUnknownPrimary: Self { .init(.sentinelUnknownPrimary) }
}
