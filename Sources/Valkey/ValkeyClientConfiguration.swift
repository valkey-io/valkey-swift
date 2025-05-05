//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey open source project
//
// Copyright (c) 2025 the swift-valkey project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-valkey project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOSSL

/// Configuration for the Valkey client
public struct ValkeyClientConfiguration: Sendable {
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

    /// Authentication details
    public struct Authentication: Sendable {
        public var username: String
        public var password: String

        public init(username: String, password: String) {
            self.username = username
            self.password = password
        }
    }

    /// authentication details
    public var authentication: Authentication?
    /// TLS setup
    public var tls: TLS

    ///  Initialize ValkeyClientConfiguration
    /// - Parameters
    ///   - authentication: Authentication details
    ///   - tlsConfiguration: TLS configuration
    public init(
        authentication: Authentication? = nil,
        tls: TLS = .disable
    ) {
        self.authentication = authentication
        self.tls = tls
    }
}
