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

import NIOSSL
import _ConnectionPoolModule

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

    /// A keep-alive behavior for Valkey connections. The ``frequency`` defines after which time an idle
    /// connection shall run a keep-alive ``query``.
    public struct KeepAliveBehavior: Sendable {
        /// The amount of time that shall pass before an idle connection runs a keep-alive ``query``.
        public var frequency: Duration

        /// The ``command`` that is run on an idle connection after it has been idle for ``frequency``.
        public var command: [String]

        /// Create a new `KeepAliveBehavior`.
        /// - Parameters:
        ///   - frequency: The amount of time that shall pass before an idle connection runs a keep-alive `query`.
        ///                Defaults to `30` seconds.
        ///   - query: The `command` that is run on an idle connection after it has been idle for `frequency`.
        ///            Defaults to `SELECT 1;`.
        public init(frequency: Duration = .seconds(30), command: [String] = ["PING"]) {
            self.frequency = frequency
            self.command = command
        }
    }

    /// authentication details
    public var authentication: Authentication?
    /// connection pool configuration
    public var connectionPool: ConnectionPoolConfiguration
    /// keep alive behavior
    public var keepAliveBehavior: KeepAliveBehavior

    /// TLS setup
    public var tls: TLS

    ///  Initialize ValkeyClientConfiguration
    /// - Parameters
    ///   - authentication: Authentication details
    ///   - tlsConfiguration: TLS configuration
    public init(
        authentication: Authentication? = nil,
        connectionPool: ConnectionPoolConfiguration = .init(),
        keepAliveBehavior: KeepAliveBehavior = .init(),
        tls: TLS = .disable
    ) {
        self.authentication = authentication
        self.connectionPool = connectionPool
        self.keepAliveBehavior = keepAliveBehavior
        self.tls = tls
    }
}
