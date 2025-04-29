//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey open source project
//
// Copyright (c) 2025 Apple Inc. and the swift-valkey project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-valkey project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore

/// A Valkey command that can be executed on a connection.
public protocol ValkeyCommand: Sendable {
    associatedtype Response: RESPTokenDecodable = RESPToken
    associatedtype Keys: Collection<ValkeyKey>

    /// Keys affected by command. This is used in cluster mode to determine which
    /// shard to connect to.
    var keysAffected: Keys { get }

    ///
    /// Encode Valkey Command into RESP
    /// - Parameter commandEncoder: ValkeyCommandEncoder
    func encode(into commandEncoder: inout ValkeyCommandEncoder)
}

extension ValkeyCommand {
    /// Default to no keys affected
    public var keysAffected: [ValkeyKey] { [] }
}
