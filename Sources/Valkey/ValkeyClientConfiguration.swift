//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 the valkey-swift project authors
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
public struct ValkeyClientConfiguration: Sendable {
    /// The TLS setting connecting to a Valkey Server.
    public struct TLS: Sendable {
        enum Base {
            case disable
            case enable(TLSConfiguration, String?)
        }
        let base: Base

        /// Creates a disabled TLS client configuration.
        public static var disable: Self { .init(base: .disable) }
        /// Creates a TLS enabled client configuration.
        /// - Parameters:
        ///   - tlsConfiguration: The TLS configuration to use with the Valkey connection.
        ///   - tlsServerName: The Valkey server name.
        ///
        /// The Valkey client uses the server name you provide for validation.
        public static func enable(_ tlsConfiguration: TLSConfiguration, tlsServerName: String?) throws -> Self {
            .init(base: .enable(tlsConfiguration, tlsServerName))
        }
    }

    /// Authentication credentials.
    public struct Authentication: Sendable {
        public var username: String
        public var password: String

        /// Creates authentication credentials with the username and password you provide.
        /// - Parameters:
        ///   - username: The username for the Valkey server.
        ///   - password: The password for the Valkey server.
        public init(username: String, password: String) {
            self.username = username
            self.password = password
        }
    }

    /// A keep-alive behavior for Valkey connections.
    ///
    /// The ``frequency`` defines after which time an idle connection shall run a keep-alive ``ValkeyClientProtocol/ping(message:)``.
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

    /// The connection pool definition for Valkey connections.
    public struct ConnectionPool: Hashable, Sendable {
        /// The minimum number of connections to preserve in the pool.
        ///
        /// If the pool is mostly idle and the remote servers closes
        /// idle connections,  the ``ValkeyClient`` will initiate new outbound
        /// connections proactively to avoid the number of available
        /// connections dropping below this number.
        public var minimumConnectionCount: Int

        /// The maximum number of connections in the pool.
        ///
        /// The client will at no time create more connections than this.
        /// If connections become idle, they will be closed, if they haven't received work
        /// within ``idleTimeout``, as long as we have more connections than
        /// ``minimumConnectionCount``.
        public var maximumConnectionCount: Int

        /// The time that a _preserved_ idle connection stays in the
        /// pool before it is closed.
        public var idleTimeout: Duration

        /// Creates the configuration for a Valkey client connection pool.
        /// - Parameters:
        ///   - minimumConnectionCount: The minimum number of connections to maintain.
        ///   - maximumConnectionCount: The maximum number of connections to allow.
        ///   - idleTimeout: The duration to allow a connect to be idle, that defaults to 60 seconds.
        public init(
            minimumConnectionCount: Int = 0,
            maximumConnectionCount: Int = 20,
            idleTimeout: Duration = .seconds(60)
        ) {
            self.minimumConnectionCount = minimumConnectionCount
            self.maximumConnectionCount = maximumConnectionCount
            self.idleTimeout = idleTimeout
        }
    }

    /// Should client run read-only commands from replicas and how it should select the replica
    public struct ReadOnlyReplicaSelection: Sendable {
        internal enum Base: Sendable {
            case usePrimary
            case random
        }

        internal let base: Base

        /// Only read from primary node
        public static var usePrimary: Self { .init(base: .usePrimary) }
        /// Read from random replica node
        public static var random: Self { .init(base: .random) }
    }

    /// The authentication credentials for the connection.
    public var authentication: Authentication?
    /// The connection pool configuration.
    public var connectionPool: ConnectionPool
    /// The keep alive behavior for the connection.
    public var keepAliveBehavior: KeepAliveBehavior
    /// Should client read from replicas
    public var readOnlyReplicaSelection: ReadOnlyReplicaSelection
    /// The timeout the client uses to determine if a connection is considered dead.
    ///
    /// The connection is considered dead if a response isn't received within this time.
    public var commandTimeout: Duration
    /// The global timeout for blocking commands.
    public var blockingCommandTimeout: Duration

    /// The TLS to use for the Valkey connection.
    public var tls: TLS

    /// Creates a Valkey client connection configuration.
    ///
    /// - Parameters:
    ///   - authentication: The authentication credentials.
    ///   - connectionPool: The connection pool configuration.
    ///   - keepAliveBehavior: The connection keep alive behavior.
    ///   - readOnlyReplicaSelection: Should client read from replicas
    ///   - commandTimeout: The timeout for a connection response.
    ///   - blockingCommandTimeout: The timeout for a blocking command response.
    ///   - tls: The TLS configuration.
    public init(
        authentication: Authentication? = nil,
        connectionPool: ConnectionPool = .init(),
        keepAliveBehavior: KeepAliveBehavior = .init(),
        readOnlyReplicaSelection: ReadOnlyReplicaSelection = .usePrimary,
        commandTimeout: Duration = .seconds(30),
        blockingCommandTimeout: Duration = .seconds(120),
        tls: TLS = .disable
    ) {
        self.authentication = authentication
        self.connectionPool = connectionPool
        self.keepAliveBehavior = keepAliveBehavior
        self.readOnlyReplicaSelection = readOnlyReplicaSelection
        self.commandTimeout = commandTimeout
        self.blockingCommandTimeout = blockingCommandTimeout
        self.tls = tls
    }
}
