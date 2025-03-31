//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-redis open source project
//
// Copyright (c) 2025 Apple Inc. and the swift-redis project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-redis project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOSSL

/// Configuration for the redis client
public struct RedisClientConfiguration: Sendable {
    public struct RESPVersion: Sendable, Equatable {
        enum Base {
            case v2
            case v3
        }
        let base: Base

        public static var v2: Self { .init(base: .v2) }
        public static var v3: Self { .init(base: .v3) }
    }

    public struct TLS: Sendable {
        enum Base {
            case disable
            case enable(NIOSSLContext, String?)
        }
        let base: Base

        public static var disable: Self { .init(base: .disable) }
        public static func enable(tlsConfiguration: TLSConfiguration, tlsServerName: String?) throws -> Self {
            .init(base: .enable(try NIOSSLContext(configuration: tlsConfiguration), tlsServerName))
        }
    }

    public var respVersion: RESPVersion
    public var tls: TLS

    ///  Initialize RedisClientConfiguration
    /// - Parameters
    ///   - respVersion: RESP version to use
    ///   - tlsConfiguration: TLS configuration
    public init(
        respVersion: RESPVersion = .v3,
        tls: TLS = .disable
    ) {
        self.respVersion = respVersion
        self.tls = tls
    }
}
