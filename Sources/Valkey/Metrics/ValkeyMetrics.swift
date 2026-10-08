//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

#if MetricsSupport
import Metrics
import Synchronization

// MARK: - Configuration

@available(valkeySwift 1.0, *)
/// A configuration object that defines metrics emission behavior of a Valkey client.
///
/// Metrics are off by default. Set ``factory`` to start emitting them, either through the factory
/// bootstrapped into `MetricsSystem`
/// ```swift
/// configuration.metrics.factory = MetricsSystem.factory
/// ```
/// or through a factory you own, which is useful when a single process feeds different backends, or
/// in tests
/// ```swift
/// configuration.metrics.factory = myMetricsFactory
/// ```
public struct ValkeyMetricsConfiguration: Sendable {
    /// The factory the client creates its metrics from, or `nil` to emit no metrics.
    /// Defaults to `nil`.
    ///
    /// The client creates its metrics once, when it is initialized, and holds them for its lifetime.
    /// Assigning `MetricsSystem.factory` therefore captures whichever factory is current at that
    /// point, so `MetricsSystem.bootstrap(_:)` has to run first.
    public var factory: (any MetricsFactory)?

    /// The labels of the metrics recorded by Valkey. Defaults to OpenTelemetry semantics.
    public var labels: Labels = .init()

    /// The dimensions used on metrics recorded by Valkey. Defaults to OpenTelemetry semantics.
    public var dimensions: Dimensions = .init()

    /// The unit the metrics backend is asked to display operation durations in. Defaults to
    /// `.seconds`, the unit OpenTelemetry semantics specify for `db.client.operation.duration`.
    ///
    /// Durations are always recorded in nanoseconds; this is only a hint, which the backend may ignore.
    public var preferredDisplayUnit: TimeUnit = .seconds

    /// Labels of the metrics recorded by Valkey.
    public struct Labels: Sendable {
        public var operationDuration: String = "db.client.operation.duration"

        /// Creates the default metric labels.
        public init() {}
    }

    /// Dimensions used on metrics recorded by Valkey.
    ///
    /// Each `Key` is the dimension name. A `Value` is provided only for dimensions with a static value;
    /// the others are filled in per operation.
    public struct Dimensions: Sendable {
        /// The dimension identifying the database system.
        public var databaseSystemKey: String = "db.system.name"
        /// The value reported for ``databaseSystemKey``.
        public var databaseSystemValue: String = "valkey"

        /// The dimension carrying the database number the client was configured with.
        public var databaseNamespaceKey: String = "db.namespace"

        /// The dimension carrying the command name, such as `GET`.
        public var databaseOperationKey: String = "db.operation.name"

        /// The dimension carrying the error a failed operation reported. Omitted on success.
        public var errorTypeKey: String = "error.type"
        /// Reported for ``errorTypeKey`` when an error carries no recognisable Valkey error prefix.
        public var otherErrorTypeValue: String = "_OTHER"

        /// Creates the default dimensions.
        public init() {}
    }

    /// Creates a metrics configuration.
    ///
    /// - Parameter factory: The factory the client creates its metrics from. Defaults to `nil`, which
    ///   emits no metrics.
    public init(factory: (any MetricsFactory)? = nil) {
        self.factory = factory
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyClientError {
    /// The value to report as `error.type`, following the conventions' guidance that it match the
    /// Valkey error prefix that would be reported as `db.response.status_code`, or `nil` when the
    /// error carries no recognisable prefix.
    ///
    /// Prefixes are accepted only when they look like a Valkey error code - an upper-case ASCII token
    /// such as `ERR`, `WRONGTYPE` or `CLUSTERDOWN` - so that a server returning unusual text cannot
    /// inflate the cardinality of the metric.
    fileprivate var metricsErrorType: String? {
        if self.errorCode == .timeout {
            return "timeout"
        }
        if self.errorCode == .cancelled || self.errorCode == .connectionClosedDueToCancellation {
            return "cancelled"
        }
        guard self.errorCode == .commandError, let message = self.message else {
            return nil
        }
        let prefix = message.prefix { $0 != " " }
        guard !prefix.isEmpty, prefix.allSatisfy({ $0.isASCII && $0.isUppercase }) else {
            return nil
        }
        return String(prefix)
    }
}

// MARK: - Metric handles

/// Every metric handle a single client records into, all created from the `MetricsFactory` that
/// client was configured with.
///
/// A client creates one instance when it is initialized and holds it for its lifetime: a `Timer`
/// resolves its handler from the factory at creation time, so recreating timers per command would
/// both allocate on the hot path and go through the factory's own lookup each time.
///
/// The handles are deliberately never `destroy()`ed. Factories generally return the same handler for
/// a given label and dimension set, so destroying handles as one client shuts down could stop
/// recording for other clients that share the factory.
@available(valkeySwift 1.0, *)
@usableFromInline
final class ValkeyMetrics: Sendable {
    /// Identifies one timer: a command plus the outcome it recorded.
    private struct TimerKey: Hashable {
        let commandName: String
        /// `nil` for a successful operation, where the conventions omit `error.type` entirely.
        let errorType: String?
    }

    /// `db.system.name` and `db.namespace`, carried by every sample.
    private let commonDimensions: [(String, String)]
    private let label: String
    private let preferredDisplayUnit: TimeUnit
    private let dimensions: ValkeyMetricsConfiguration.Dimensions
    private let factory: any MetricsFactory
    private let timers: Mutex<[TimerKey: Timer]>

    /// Creates the handles a client records into, or `nil` when metrics emission is disabled.
    ///
    /// - Parameters:
    ///   - configuration: The client's metrics configuration. Returns `nil` when it has no factory.
    ///   - databaseNumber: The database index reported as `db.namespace`. As the conventions permit,
    ///     this is the index the connection was established with, not one a later `SELECT` moved to.
    init?(configuration: ValkeyMetricsConfiguration, databaseNumber: Int) {
        guard let factory = configuration.factory else { return nil }
        self.factory = factory
        self.label = configuration.labels.operationDuration
        self.preferredDisplayUnit = configuration.preferredDisplayUnit
        self.dimensions = configuration.dimensions
        self.commonDimensions = [
            (configuration.dimensions.databaseSystemKey, configuration.dimensions.databaseSystemValue),
            (configuration.dimensions.databaseNamespaceKey, String(databaseNumber)),
        ]
        self.timers = .init([:])
    }

    /// The instant to measure latency from.
    ///
    /// Callers reach this through `self.valkeyMetrics?.startTiming()`, so the clock goes unread and
    /// the result is `nil` when metrics are disabled.
    @usableFromInline
    func startTiming() -> ContinuousClock.Instant {
        .now
    }

    /// Record a latency sample for a command if metrics timing was started.
    ///
    /// - Parameters:
    ///   - commandName: The command name, reported as `db.operation.name`.
    ///   - start: The instant returned by ``startTiming()``, or `nil` when timing never started.
    ///   - error: The error the command failed with, or `nil` when it succeeded.
    @usableFromInline
    func record(_ commandName: String, start: ContinuousClock.Instant?, error: ValkeyClientError?) {
        guard let start else { return }
        let elapsed = ContinuousClock.now - start
        let errorType = error.map { $0.metricsErrorType ?? self.dimensions.otherErrorTypeValue }
        self.timer(for: commandName, errorType: errorType).recordNanoseconds(elapsed.nanosecondsClamped)
    }

    /// The timer for a command and outcome, created from the client's factory on first use.
    private func timer(for commandName: String, errorType: String?) -> Timer {
        let key = TimerKey(commandName: commandName, errorType: errorType)
        return self.timers.withLock { timers in
            if let cached = timers[key] {
                return cached
            }
            var timerDimensions = self.commonDimensions
            timerDimensions.reserveCapacity(self.commonDimensions.count + 2)
            timerDimensions.append((self.dimensions.databaseOperationKey, commandName))
            if let errorType {
                timerDimensions.append((self.dimensions.errorTypeKey, errorType))
            }
            let timer = Timer(
                label: self.label,
                dimensions: timerDimensions,
                preferredDisplayUnit: self.preferredDisplayUnit,
                factory: self.factory
            )
            timers[key] = timer
            return timer
        }
    }
}

@available(valkeySwift 1.0, *)
extension Duration {
    /// The duration in nanoseconds, saturating rather than trapping on overflow.
    fileprivate var nanosecondsClamped: Int64 {
        let components = self.components
        let (seconds, secondsOverflowed) = components.seconds.multipliedReportingOverflow(by: 1_000_000_000)
        guard !secondsOverflowed else { return components.seconds > 0 ? .max : .min }
        let (total, totalOverflowed) = seconds.addingReportingOverflow(components.attoseconds / 1_000_000_000)
        return totalOverflowed ? (seconds > 0 ? .max : .min) : total
    }
}

#endif
