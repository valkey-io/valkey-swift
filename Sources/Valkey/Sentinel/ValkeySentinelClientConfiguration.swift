//
// This source file is part of the valkey-swift project
// Copyright (c) 2025-2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

@available(valkeySwift 1.0, *)
public struct ValkeySentinelClientConfiguration: Sendable {
    /// The authentication credentials for the connection.
    public var authentication: ValkeyClientConfiguration.Authentication?
    /// The connection pool configuration.
    public var connectionPool: ValkeyClientConfiguration.ConnectionPool
    /// The keep alive behavior for the connection.
    public var keepAliveBehavior: ValkeyClientConfiguration.KeepAliveBehavior
    /// Retry parameters for when a sentinel client needs to retry a command
    public var retryParameters: ValkeyClientConfiguration.RetryParameters

    /// The TLS setup to use for the Valkey sentinel connection.
    public var tls: ValkeyClientConfiguration.TLS

    /// The timeout the client uses to determine if a connection is considered dead.
    ///
    /// The connection is considered dead if a response isn't received within this time.
    public var commandTimeout: Duration

    #if DistributedTracingSupport
    /// The distributed tracing configuration to use for the Valkey connection.
    /// Defaults to using the globally bootstrapped tracer with OpenTelemetry semantic conventions.
    public var tracing: ValkeyTracingConfiguration = .init()
    #endif

    public init(
        authentication: ValkeyClientConfiguration.Authentication? = nil,
        connectionPool: ValkeyClientConfiguration.ConnectionPool = .init(
            minimumConnectionCount: 1,
            maximumConnectionSoftLimit: 2,
            maximumConnectionHardLimit: 2
        ),
        keepAliveBehavior: ValkeyClientConfiguration.KeepAliveBehavior = .init(),
        retryParameters: ValkeyClientConfiguration.RetryParameters = .init(),
        tls: ValkeyClientConfiguration.TLS = .disable,
        commandTimeout: Duration = .seconds(30)
    ) {
        self.authentication = authentication
        self.connectionPool = connectionPool
        self.keepAliveBehavior = keepAliveBehavior
        self.retryParameters = retryParameters
        self.tls = tls
        self.commandTimeout = commandTimeout
    }

    var clientConfiguration: ValkeyClientConfiguration {
        var configuration = ValkeyClientConfiguration(
            authentication: authentication,
            connectionPool: connectionPool,
            keepAliveBehavior: keepAliveBehavior,
            retryParameters: retryParameters,
            commandTimeout: commandTimeout,
            tls: tls,
            databaseNumber: 0,
            readOnlyCommandNodeSelection: .primary,
            enableClientCapaRedirect: false,
            connectingToReplica: false
        )
        configuration.tracing = self.tracing
        return configuration
    }

}
