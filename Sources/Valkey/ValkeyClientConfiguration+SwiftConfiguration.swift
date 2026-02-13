//
// This source file is part of the valkey-swift project
// Copyright (c) 2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

#if compiler(>=6.2)
import Configuration

@available(valkeySwift 1.0, *)
extension ValkeyClientConfiguration {
    /// Initializes a ``ValkeyClientConfiguration``` from a ConfigReader.
    ///
    /// - Note: Does NOT handle tls configuration. TLS will be disabled on the returned configuration.
    ///
    /// ## Configuration keys:
    /// - `connectionPool.*` (nested object, optional): Connection pool settings.
    /// - `keepAlive.*` (nested object, optional): Keep-alive behavior settings.
    /// - `retry.*` (nested object, optional): Retry parameters.
    /// - `authentication.*` (nested object, optional): Server authentication.
    /// - `commandTimeoutMs` (duration, optional, default: 30 seconds): Timeout for command responses.
    /// - `blockingCommandTimeoutMs` (duration, optional, default: 120 seconds): Timeout for blocking command responses.
    /// - `databaseNumber` (int, optional, default: 0, range: 0-15): Database number to use for the Valkey Connection
    /// - `readOnlyCommandNodeSelection` (string, optional, default: "primary"): Determine how we chose nodes for readonly commands. Valid values: "primary", "cycleReplicas", "cycleAllNodes".
    ///
    /// - Throws: Errors from nested configuration readers.
    public init(configReader: ConfigReader) throws {
        self.init()

        self.connectionPool = .init(configReader: configReader.scoped(to: "connectionPool"))
        self.keepAliveBehavior = .init(configReader: configReader.scoped(to: "keepAlive"))
        self.retryParameters = .init(configReader: configReader.scoped(to: "retry"))

        if let commandTimeoutMs = configReader.durationAsMillis(forKey: "commandTimeoutMs") {
            self.commandTimeout = commandTimeoutMs
        }

        if let blockingCommandTimeoutMs = configReader.durationAsMillis(forKey: "blockingCommandTimeoutMs") {
            self.blockingCommandTimeout = blockingCommandTimeoutMs
        }

        self.authentication = try ValkeyClientConfiguration.Authentication(configReader: configReader.scoped(to: "authentication"))

        if let databaseNumber = configReader.int(forKey: "databaseNumber") {
            self.databaseNumber = databaseNumber
        }

        if let readOnlyCommandNodeSelection = configReader.string(forKey: "readOnlyCommandNodeSelection") {
            guard let typed = ReadOnlyCommandNodeSelection._Internal(rawValue: readOnlyCommandNodeSelection) else {
                // Set but not valid - that's an error
                let validValues = Array(ReadOnlyCommandNodeSelection._Internal.allCases.map(\.rawValue)).joined(separator: ", ")
                throw ConfigurationError(message: "readOnlyCommandNodeSelection has invalid value. Valid values are \(validValues)")
            }
            self.readOnlyCommandNodeSelection = .init(value: typed)
        }
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyClientConfiguration.ConnectionPool {
    /// Initializes ``ValkeyClientConfiguration/ConnectionPool``` from a `ConfigReader`.
    ///
    /// ## Configuration keys:
    /// - `minimumConnectionCount` (int, optional, default: 0): Minimum connections to preserve in the pool.
    /// - `maximumConnectionSoftLimit` (int, optional, default: 20): Max connections that can persist when idle.
    /// - `maximumConnectionHardLimit` (int, optional, default: 20): The maximum number of connections for this pool, that can exist at any point in time.
    /// - `idleTimeoutMs` (int, optional, default: 60,000): Milliseconds before idle preserved connections are closed.
    /// - `circuitBreakerTripAfterMs` (int, optional, default: 60,000): Milliseconds between first connection failure and circuit breaker activation.
    /// - `maximumConcurrentConnectionRequests` (int, optional, default: 20): Max concurrent new connection requests.
    public init(configReader: ConfigReader) {
        self.init()

        if let minConnections = configReader.int(forKey: "minimumConnectionCount") {
            self.minimumConnectionCount = minConnections
        }

        if let maxConnections = configReader.int(forKey: "maximumConnectionHardLimit") {
            self.maximumConnectionHardLimit = maxConnections
        }

        if let maxConnections = configReader.int(forKey: "maximumConnectionSoftLimit") {
            self.maximumConnectionSoftLimit = maxConnections
        }

        if let idleTimeoutMs = configReader.durationAsMillis(forKey: "idleTimeoutMs") {
            self.idleTimeout = idleTimeoutMs
        }

        if let circuitBreakerTripAfterMs = configReader.durationAsMillis(forKey: "circuitBreakerTripAfterMs") {
            self.circuitBreakerTripAfter = circuitBreakerTripAfterMs
        }

        if let maxConcurrentRequests = configReader.int(forKey: "maximumConcurrentConnectionRequests") {
            self.maximumConcurrentConnectionRequests = maxConcurrentRequests
        }
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyClientConfiguration.KeepAliveBehavior {
    /// Initializes ``ValkeyClientConfiguration/KeepAliveBehavior``` from a `ConfigReader`.
    ///
    /// ## Configuration keys:
    /// - `frequencyMs` (int, optional, default: 30000): Milliseconds between keep-alive pings on idle connections.
    public init(configReader: ConfigReader) {
        self.init(
            frequency: configReader.durationAsMillis(forKey: "frequencyMs", default: .seconds(30))
        )
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyClientConfiguration.RetryParameters {
    /// Initializes ``ValkeyClientConfiguration/RetryParameters``` from a `ConfigReader`.
    ///
    /// ## Configuration keys:
    /// - `exponentBase` (double, optional, default: 2.0): Base for exponential backoff calculation.
    /// - `factorMs` (int, optional, default: 10 milliseconds): Multiplier in milliseconds for exponential base.
    /// - `minWaitTimeMs` (int, optional, default: 1.28 seconds): Minimum wait time between retries, in milliseconds.
    /// - `maxWaitTimeMs` (int, optional, default: 655.36 seconds): Maximum wait time between retries, in milliseconds (capped with jitter).
    ///
    /// Wait time calculation uses exponential backoff with random jitter within [minWaitTime, maxWaitTime].
    public init(configReader: ConfigReader) {
        self.init(
            exponentBase: configReader.double(forKey: "exponentBase", default: 2.0),
            factor: configReader.durationAsMillis(forKey: "factorMs", default: .milliseconds(10.0)),
            minWaitTime: configReader.durationAsMillis(forKey: "minWaitTimeMs", default: .seconds(1.28)),
            maxWaitTime: configReader.durationAsMillis(forKey: "maxWaitTimeMs", default: .seconds(655.36))
        )
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyClientConfiguration.Authentication {
    /// Initializes ``ValkeyClientConfiguration/Authentication``` from a `ConfigReader`.
    ///
    /// Returns `nil` if either username or password are not configured.
    ///
    /// ## Configuration keys:
    /// - `username` (string, optional, secret): Username for server.
    /// - `password` (string, optional, secret): Password for server.
    ///
    /// - Note: Both `username` and `password` must be present to create valid authentication credentials.
    ///   If either is missing, this initializer returns `nil`.
    public init?(configReader: ConfigReader) throws {
        guard let username = configReader.string(forKey: "username"),
            let password = configReader.string(forKey: "password")
        else {
            return nil
        }
        self.init(username: username, password: password)
    }
}

@available(valkeySwift 1.0, *)
extension ConfigReader {
    func durationAsMillis(forKey key: ConfigKey) -> Duration? {
        let ms = self.int(forKey: key)
        return ms.map { .milliseconds($0) }
    }

    func durationAsMillis(forKey key: ConfigKey, default: Duration) -> Duration {
        let ms = self.int(forKey: key)
        return ms.map { .milliseconds($0) } ?? `default`
    }
}

struct ConfigurationError: Error, Hashable {
    var message: String
}

#endif
