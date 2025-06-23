//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 Apple Inc. and the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of valkey-swift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOSSL
import _ValkeyConnectionPool

/// Configuration for the Valkey client
@available(valkeySwift 1.0, *)
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
    /// connection shall run a keep-alive ``ValkeyConnectionProtocol/ping(message:)``.
    public struct KeepAliveBehavior: Sendable {
        /// The amount of time that shall pass before an idle connection runs a keep-alive query.
        public var frequency: Duration

        /// Create a new `KeepAliveBehavior`.
        /// - Parameters:
        ///   - frequency: The amount of time that shall pass before an idle connection runs a keep-alive.
        ///                Defaults to `30` seconds.
        public init(frequency: Duration = .seconds(30)) {
            self.frequency = frequency
        }
    }

    /// authentication details
    public var authentication: Authentication?
    /// connection pool configuration
    public var connectionPool: ConnectionPoolConfiguration
    /// keep alive behavior
    public var keepAliveBehavior: KeepAliveBehavior
    /// dead connection timeout
    public var connectionTimeout: Duration
    /// global timeout for blocking commands
    public var blockingCommandTimeout: Duration

    /// TLS setup
    public var tls: TLS

    ///  Initialize ValkeyClientConfiguration
    /// - Parameters
    ///   - authentication: Authentication details
    ///   - connectionPool: Connection pool configuration
    ///   - keepAliveBehavior: Connection keep alive behavior
    ///   - connectionTimeout: Timeout for connection response
    ///   - blockingCommandTimeout: Blocking command response timeout
    ///   - tlsConfiguration: TLS configuration
    public init(
        authentication: Authentication? = nil,
        connectionPool: ConnectionPoolConfiguration = .init(),
        keepAliveBehavior: KeepAliveBehavior = .init(),
        connectionTimeout: Duration = .seconds(30),
        blockingCommandTimeout: Duration = .seconds(120),
        tls: TLS = .disable
    ) {
        self.authentication = authentication
        self.connectionPool = connectionPool
        self.keepAliveBehavior = keepAliveBehavior
        self.connectionTimeout = connectionTimeout
        self.blockingCommandTimeout = blockingCommandTimeout
        self.tls = tls
    }
}
