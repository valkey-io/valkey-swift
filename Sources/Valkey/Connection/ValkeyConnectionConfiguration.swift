//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import NIOSSL

#if DistributedTracingSupport
import Tracing
#endif

/// A configuration object that defines how to connect to a Valkey server.
///
/// `ValkeyConnectionConfiguration` allows you to customize various aspects of the connection,
/// including authentication credentials, timeouts, and TLS security settings.
///
/// Example usage:
/// ```swift
/// // Basic configuration
/// let config = ValkeyConnectionConfiguration()
///
/// // Configuration with authentication
/// let authConfig = ValkeyConnectionConfiguration(
///     authentication: .init(username: "user", password: "pass"),
///     commandTimeout: .seconds(60)
/// )
///
/// // Configuration with TLS
/// let sslContext = try NIOSSLContext(configuration: .makeClientConfiguration())
/// let secureConfig = ValkeyConnectionConfiguration(
///     authentication: .init(username: "user", password: "pass"),
///     tls: .enable(sslContext, tlsServerName: "your-valkey-server.com")
/// )
/// ```
@available(valkeySwift 1.0, *)
public struct ValkeyConnectionConfiguration: Sendable {
    /// Configuration for TLS (Transport Layer Security) encryption.
    ///
    /// This structure allows you to enable or disable encrypted connections to the Valkey server.
    /// When enabled, it requires an `NIOSSLContext` and optionally a server name for SNI (Server Name Indication).
    public struct TLS: Sendable {
        enum Base {
            case disable
            case enable(NIOSSLContext, String?)
        }
        let base: Base

        /// Disables TLS for the connection.
        ///
        /// Use this option when connecting to a Valkey server that doesn't require encryption.
        public static var disable: Self { .init(base: .disable) }

        /// Enables TLS for the connection.
        ///
        /// - Parameters:
        ///   - sslContext: The SSL context used to establish the secure connection
        ///   - tlsServerName: Optional server name for SNI (Server Name Indication)
        /// - Returns: A configured TLS instance
        public static func enable(_ sslContext: NIOSSLContext, tlsServerName: String?) throws -> Self {
            .init(base: .enable(sslContext, tlsServerName))
        }
    }

    /// Authentication credentials for accessing a Valkey server.
    ///
    /// Use this structure to provide username and password credentials when the server
    /// requires authentication for access.
    public struct Authentication: Sendable {
        /// The username for authentication
        public var username: String
        /// The password for authentication
        public var password: String

        /// Creates a new authentication configuration.
        ///
        /// - Parameters:
        ///   - username: The username for server authentication
        ///   - password: The password for server authentication
        public init(username: String, password: String) {
            self.username = username
            self.password = password
        }
    }

    /// Optional authentication credentials for accessing the Valkey server.
    ///
    /// Set this property when connecting to a server that requires authentication.
    public var authentication: Authentication?

    /// TLS configuration for the connection.
    ///
    /// Use `.disable` for unencrypted connections or `.enable(...)` for secure connections.
    public var tls: TLS

    /// The maximum time to wait for a response to a command before considering the connection dead.
    ///
    /// This timeout applies to all standard commands sent to the Valkey server.
    /// Default value is 30 seconds.
    public var commandTimeout: Duration

    /// The maximum time to wait for a response to blocking commands.
    ///
    /// This timeout applies specifically to blocking commands (like BLPOP, BRPOP, etc.)
    /// that may wait for conditions to be met before returning.
    /// Default value is 120 seconds.
    public var blockingCommandTimeout: Duration

    /// The client name to identify this connection to the Valkey server.
    ///
    /// When specified, this name will be sent to the server using the `HELLO` command
    /// during connection initialization. This can be useful for debugging and monitoring purposes,
    /// allowing you to identify different clients connected to the server.
    /// Default value is `nil` (no client name is set).
    public var clientName: String?

    /// Is connection to be flagged as readonly.
    ///
    /// Readonly connections can run readonly commands on replica nodes
    public var readOnly: Bool

    /// The number of Valkey Database
    public var databaseNumber: Int = 0

    #if DistributedTracingSupport
    /// The distributed tracing configuration to use for this connection.
    /// Defaults to using the globally bootstrapped tracer with OpenTelemetry semantic conventions.
    public var tracing: ValkeyTracingConfiguration = .init()
    #endif

    /// Creates a new Valkey connection configuration.
    ///
    /// Use this initializer to create a configuration object that can be used to establish
    /// a connection to a Valkey server with the specified parameters.
    ///
    /// - Parameters:
    ///   - authentication: Optional credentials for accessing the Valkey server. Set to `nil` for unauthenticated access.
    ///   - commandTimeout: Maximum time to wait for a response to standard commands. Defaults to 30 seconds.
    ///   - blockingCommandTimeout: Maximum time to wait for a response to blocking commands. Defaults to 120 seconds.
    ///   - tls: TLS configuration for secure connections. Defaults to `.disable` for unencrypted connections.
    ///   - clientName: Optional name to identify this client connection on the server. Defaults to `nil`.
    ///   - readOnly: Is the connection a readonly connection
    ///   - databaseNumber: Database Number to use for the connection
    public init(
        authentication: Authentication? = nil,
        commandTimeout: Duration = .seconds(30),
        blockingCommandTimeout: Duration = .seconds(120),
        tls: TLS = .disable,
        clientName: String? = nil,
        readOnly: Bool = false,
        databaseNumber: Int = 0
    ) {
        self.authentication = authentication
        self.commandTimeout = commandTimeout
        self.blockingCommandTimeout = blockingCommandTimeout
        self.tls = tls
        self.clientName = clientName
        self.readOnly = readOnly
        self.databaseNumber = databaseNumber
    }
}

#if DistributedTracingSupport
@available(valkeySwift 1.0, *)
/// A configuration object that defines distributed tracing behavior of a Valkey client.
public struct ValkeyTracingConfiguration: Sendable {
    /// The tracer to use, or `nil` to disable tracing.
    /// Defaults to the globally bootstrapped tracer.
    public var tracer: (any Tracer)? = InstrumentationSystem.tracer

    /// The attribute names used in spans created by Valkey. Defaults to OpenTelemetry semantics.
    public var attributeNames: AttributeNames = .init()

    /// The static attribute values used in spans created by Valkey.
    public var attributeValues: AttributeValues = .init()

    /// Attribute names used in spans created by Valkey.
    public struct AttributeNames: Sendable {
        public var databaseOperationName: String = "db.operation.name"
        public var databaseOperationBatchSize: String = "db.operation.batch.size"
        public var databaseSystemName: String = "db.system.name"
        public var networkPeerAddress: String = "network.peer.address"
        public var networkPeerPort: String = "network.peer.port"
        public var serverAddress: String = "server.address"
        public var serverPort: String = "server.port"
    }

    /// Static attribute values used in spans created by Valkey.
    public struct AttributeValues: Sendable {
        public var databaseSystem: String = "valkey"
    }
}
#endif
