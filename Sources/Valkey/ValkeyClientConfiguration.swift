//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import NIOSSL
import _ValkeyConnectionPool

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(WinSDK)
import WinSDK
#elseif canImport(Bionic)
import Bionic
#else
#error("Unsupported platform")
#endif

/// Configuration for the Valkey client.
@available(valkeySwift 1.0, *)
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

    /// Retry parameters for when a client needs to retry a command
    public struct RetryParameters: Sendable {
        let exponentBase: Double
        let factor: Double
        let minWaitTime: Double
        let maxWaitTime: Double
        @usableFromInline
        let maxAttempts: Int

        /// Initialize RetryParameters
        /// - Parameters:
        ///   - exponentBase: Exponent base number
        ///   - factor: Duration to multiple exponent by get base wait value
        ///   - minWaitTime: Minimum wait time
        ///   - maxWaitTime: Maximum wait time
        ///   - maxAttempts: The maximum number of times an operation should be attempted
        public init(
            exponentBase: Double = 2,
            factor: Duration = .milliseconds(10.0),
            minWaitTime: Duration = .seconds(1.28),
            maxWaitTime: Duration = .seconds(655.36),
            maxAttempts: Int = 16
        ) {
            self.exponentBase = exponentBase
            self.factor = factor / .milliseconds(1)
            self.minWaitTime = minWaitTime / .milliseconds(1)
            self.maxWaitTime = maxWaitTime / .milliseconds(1)
            self.maxAttempts = maxAttempts
        }

        /// Calculate wait time for retry number
        ///
        /// A nil value implies we have reached the maximum number of attempts and should not
        /// retry again
        ///
        /// This code is a copy from the `RetryParam` type in cluster_clients.rs of valkey-glide,
        @usableFromInline
        func calculateWaitTime(attempt: Int) -> Duration? {
            if attempt >= self.maxAttempts {
                return nil
            }
            let baseWait = pow(self.exponentBase, Double(attempt)) * self.factor
            let clampedWait = max(min(baseWait, self.maxWaitTime), self.minWaitTime)
            let jitteredWait = Double.random(in: minWaitTime...clampedWait)
            return .milliseconds(jitteredWait)
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

        /// Between the `minimumConnectionCount` and
        /// `maximumConnectionSoftLimit` the connection pool creates
        /// _preserved_ connections. Preserved connections are closed
        /// if they have been idle for ``idleTimeout``.
        public var maximumConnectionSoftLimit: Int

        /// The maximum number of connections for this pool, that can
        /// exist at any point in time. The pool can create _overflow_
        /// connections, if all connections are leased, and the
        /// `maximumConnectionHardLimit` > `maximumConnectionSoftLimit `
        /// Overflow connections are closed immediately as soon as they
        /// become idle.
        public var maximumConnectionHardLimit: Int

        /// The time that a _preserved_ idle connection stays in the
        /// pool before it is closed.
        public var idleTimeout: Duration

        /// The amount of time to pass between the first failed connection
        /// before triggering the circuit breaker.
        public var circuitBreakerTripAfter: Duration

        /// Maximum number of in-progress new connection requests to run at any one time
        public var maximumConcurrentConnectionRequests: Int

        /// Creates the configuration for a Valkey client connection pool.
        /// - Parameters:
        ///   - minimumConnectionCount: The minimum number of connections to maintain.
        ///   - maximumConnectionSoftLimit: The maximum number of connections to allow that are not closed immediately.
        ///   - maximumConnectionHardLimit: The maximum number of connections to allow.
        ///   - idleTimeout: The duration to allow a connect to be idle, that defaults to 60 seconds.
        ///   - circuitBreakerTripAfter: Time after first connection fail before circuit breaker trips.
        ///   - maximumConcurrentConnectionRequests: Maximum concurrent connection requests that can be run at one time.
        public init(
            minimumConnectionCount: Int = 0,
            maximumConnectionSoftLimit: Int = 20,
            maximumConnectionHardLimit: Int = 20,
            idleTimeout: Duration = .seconds(60),
            circuitBreakerTripAfter: Duration = .seconds(60),
            maximumConcurrentConnectionRequests: Int = 20
        ) {
            precondition(
                minimumConnectionCount <= maximumConnectionSoftLimit,
                "Minimum connection count cannot be greater than maximum connection soft limit"
            )
            precondition(
                maximumConnectionSoftLimit <= maximumConnectionHardLimit,
                "Maximum connection soft limit connection count cannot be greater than the maximum connection hard limit"
            )
            self.minimumConnectionCount = minimumConnectionCount
            self.maximumConnectionSoftLimit = maximumConnectionSoftLimit
            self.maximumConnectionHardLimit = maximumConnectionHardLimit
            self.idleTimeout = idleTimeout
            self.circuitBreakerTripAfter = circuitBreakerTripAfter
            self.maximumConcurrentConnectionRequests = maximumConcurrentConnectionRequests
        }
    }

    /// Determine how nodes are chosen for readonly commands
    public struct ReadOnlyCommandNodeSelection: Sendable, Equatable {
        enum _Internal {
            case primary
            case cycleReplicas
            case cycleAllNodes
        }

        let value: _Internal

        /// Always use the primary node
        public static var primary: Self { .init(value: .primary) }
        /// Cycle through replicas
        public static var cycleReplicas: Self { .init(value: .cycleReplicas) }
        /// Cycle through primary and replicas
        public static var cycleAllNodes: Self { .init(value: .cycleAllNodes) }
    }

    /// The authentication credentials for the connection.
    public var authentication: Authentication?
    /// The connection pool configuration.
    public var connectionPool: ConnectionPool
    /// The keep alive behavior for the connection.
    public var keepAliveBehavior: KeepAliveBehavior
    /// Retry parameters for when a client needs to retry a command
    public var retryParameters: RetryParameters

    /// Maximum number of times we follow a MOVE/ASK error in the cluster client before
    /// failing a request
    public var clusterMaximumNumberOfRedirects: Int

    /// The timeout the client uses to determine if a connection is considered dead.
    ///
    /// The connection is considered dead if a response isn't received within this time.
    public var commandTimeout: Duration
    /// The global timeout for blocking commands.
    public var blockingCommandTimeout: Duration

    /// The TLS to use for the Valkey connection.
    public var tls: TLS

    /// Database Number to use for the Valkey Connection
    public var databaseNumber: Int = 0

    /// Determine how we chose nodes for readonly commands
    ///
    /// Cluster by default will redirect commands from replica nodes to the primary node.
    /// Setting this value to something other than ``ReadOnlyCommandNodeSelection/primary``
    /// will allow replicas to run readonly commands. This will reduce load on your primary
    /// nodes but there is a chance you will receive stale data as the replica is not up to date.
    public var readOnlyCommandNodeSelection: ReadOnlyCommandNodeSelection

    /// Enable client redirect capability
    ///
    /// Valkey 8.0 introduced a new command CLIENT CAPA to indicate client capabilities. It
    /// currently only supports one capability `redirect`. This indicates the client is
    /// capable of handling redirect messages from replica nodes back to the primary. See
    /// https://valkey.io/commands/client-capa/
    ///
    /// This is only valid when used with `ValkeyClient`. Redirection is handled differently with
    /// `ValkeyClusterClient`.
    public var enableClientCapaRedirect: Bool

    /// Flag that we are connecting to a Replica in standalone mode and shouldn't redirect to
    /// the primary unless `enableClientRedirect` is set to true and we call a non readonly command
    ///
    /// This is only valid when used with `ValkeyClient`as it is a standalone client feature.
    public var connectingToReplica: Bool

    #if DistributedTracingSupport
    /// The distributed tracing configuration to use for the Valkey connection.
    /// Defaults to using the globally bootstrapped tracer with OpenTelemetry semantic conventions.
    public var tracing: ValkeyTracingConfiguration = .init()
    #endif

    /// Creates a Valkey client connection configuration.
    ///
    /// - Parameters:
    ///   - authentication: The authentication credentials.
    ///   - connectionPool: The connection pool configuration.
    ///   - keepAliveBehavior: The connection keep alive behavior.
    ///   - retryParameters: Retry parameters for when client returns an error that requires a retry
    ///   - clusterMaximumNumberOfRedirects: Maximum number of times we follow a MOVE/ASK error before failing
    ///   - commandTimeout: The timeout for a connection response.
    ///   - blockingCommandTimeout: The timeout for a blocking command response.
    ///   - tls: The TLS configuration.
    ///   - databaseNumber: The Valkey Database number.
    ///   - readOnlyCommandNodeSelection: How we choose a node when processing readonly commands
    ///   - enableClientCapaRedirect: Support client redirection errors from replicas
    ///   - connectingToReplica: Flag we are connecting to a replica and don't want to redirect to the primary
    public init(
        authentication: Authentication? = nil,
        connectionPool: ConnectionPool = .init(),
        keepAliveBehavior: KeepAliveBehavior = .init(),
        retryParameters: RetryParameters = .init(),
        clusterMaximumNumberOfRedirects: Int = 4,
        commandTimeout: Duration = .seconds(30),
        blockingCommandTimeout: Duration = .seconds(120),
        tls: TLS = .disable,
        databaseNumber: Int = 0,
        readOnlyCommandNodeSelection: ReadOnlyCommandNodeSelection = .primary,
        enableClientCapaRedirect: Bool = true,
        connectingToReplica: Bool = false
    ) {
        self.authentication = authentication
        self.connectionPool = connectionPool
        self.keepAliveBehavior = keepAliveBehavior
        self.retryParameters = retryParameters
        self.clusterMaximumNumberOfRedirects = clusterMaximumNumberOfRedirects
        self.commandTimeout = commandTimeout
        self.blockingCommandTimeout = blockingCommandTimeout
        self.tls = tls
        self.databaseNumber = databaseNumber
        self.readOnlyCommandNodeSelection = readOnlyCommandNodeSelection
        self.enableClientCapaRedirect = enableClientCapaRedirect
        self.connectingToReplica = connectingToReplica
    }
}
