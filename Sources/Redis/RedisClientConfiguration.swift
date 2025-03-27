//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-redis open source project
//
// Copyright (c) 2023 the swift-redis project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-redis project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Configuration for the redis client
public struct RedisClientConfiguration: Sendable {
    public enum RESPVersion: Sendable {
        case v2
        case v3
    }

    public var respVersion: RESPVersion

    ///  Initialize RedisClientConfiguration
    /// - Parameters
    ///   - respVersion: RESP version to use
    public init(respVersion: RESPVersion = .v3) {
        self.respVersion = respVersion
    }
}
