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
}

// MARK: - Metric handles

/// Outcome dimension recorded with every command latency sample.
@available(valkeySwift 1.0, *)
@usableFromInline
enum ValkeyCommandStatus: Sendable {
    case ok
    case error
    case timeout
    case cancelled
}

/// Per-command-type bundle of preconfigured timers, one per ``ValkeyCommandStatus``.
///
/// Holding the four timer instances together lets the hot path resolve the right one with a
/// single switch rather than allocating dimension arrays or building label strings on every
/// command execution.
@available(valkeySwift 1.0, *)
@usableFromInline
final class ValkeyCommandMetrics: Sendable {
    @usableFromInline let ok: Timer
    @usableFromInline let error: Timer
    @usableFromInline let timeout: Timer
    @usableFromInline let cancelled: Timer

    init(commandName: String, factory: any MetricsFactory) {
        let label = "valkey.command.\(commandName.lowercased()).duration"
        self.ok = Timer(label: label, dimensions: [("status", "ok")], factory: factory)
        self.error = Timer(label: label, dimensions: [("status", "error")], factory: factory)
        self.timeout = Timer(label: label, dimensions: [("status", "timeout")], factory: factory)
        self.cancelled = Timer(label: label, dimensions: [("status", "cancelled")], factory: factory)
    }

    @usableFromInline
    func timer(for status: ValkeyCommandStatus) -> Timer {
        switch status {
        case .ok: self.ok
        case .error: self.error
        case .timeout: self.timeout
        case .cancelled: self.cancelled
        }
    }
}

/// Pipeline-level metric pair: latency timer plus batch-size recorder.
@available(valkeySwift 1.0, *)
@usableFromInline
struct ValkeyPipelineMetrics: Sendable {
    @usableFromInline let timer: Timer
    @usableFromInline let sizeRecorder: Recorder

    init(factory: any MetricsFactory) {
        self.timer = Timer(label: "valkey.pipeline.duration", factory: factory)
        self.sizeRecorder = Recorder(label: "valkey.pipeline.size", factory: factory)
    }
}

/// Transaction-level metric pair: latency timer plus batch-size recorder.
///
/// Tracked separately from pipelines because MULTI/EXEC has different semantics and operators
/// usually want to see transaction latency in isolation.
@available(valkeySwift 1.0, *)
@usableFromInline
struct ValkeyTransactionMetrics: Sendable {
    @usableFromInline let timer: Timer
    @usableFromInline let sizeRecorder: Recorder

    init(factory: any MetricsFactory) {
        self.timer = Timer(label: "valkey.transaction.duration", factory: factory)
        self.sizeRecorder = Recorder(label: "valkey.transaction.size", factory: factory)
    }
}

/// Every metric handle a single client records into, all created from the `MetricsFactory` that
/// client was configured with.
///
/// A client creates one store when it is initialized and holds it for its lifetime: `Timer` and
/// `Recorder` resolve their handler from the factory at creation time, so recreating them per
/// command would both allocate on the hot path and go through the factory's own lookup each time.
///
/// The handles are deliberately never `destroy()`ed. Factories generally return the same handler for
/// a given label and dimension set, so destroying handles as one client shuts down could stop
/// recording for other clients that share the factory.
@available(valkeySwift 1.0, *)
@usableFromInline
final class ValkeyMetricsStore: Sendable {
    @usableFromInline let pipeline: ValkeyPipelineMetrics
    @usableFromInline let transaction: ValkeyTransactionMetrics

    private let factory: any MetricsFactory
    /// Per-command-type handles, created on first use of each command and keyed by command name.
    private let commandMetricsCache: Mutex<[String: ValkeyCommandMetrics]>

    init(factory: any MetricsFactory) {
        self.factory = factory
        self.pipeline = ValkeyPipelineMetrics(factory: factory)
        self.transaction = ValkeyTransactionMetrics(factory: factory)
        self.commandMetricsCache = .init([:])
    }

    /// The timers for `Command`, creating them from the store's factory on first use.
    @usableFromInline
    func commandMetrics<Command: ValkeyCommand>(for type: Command.Type) -> ValkeyCommandMetrics {
        self.commandMetricsCache.withLock { cache in
            if let cached = cache[Command.name] {
                return cached
            }
            let metrics = ValkeyCommandMetrics(commandName: Command.name, factory: self.factory)
            cache[Command.name] = metrics
            return metrics
        }
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyMetricsConfiguration {
    /// The metric handles this configuration asks for, or `nil` when metrics emission is disabled.
    ///
    /// Called once per client, at client initialization.
    func initMetricsStore() -> ValkeyMetricsStore? {
        self.factory.map { ValkeyMetricsStore(factory: $0) }
    }
}

// MARK: - Helpers

/// Convert the elapsed `Duration` between two `ContinuousClock` instants to nanoseconds.
@available(valkeySwift 1.0, *)
@usableFromInline
func valkeyElapsedNanoseconds(since start: ContinuousClock.Instant) -> Int64 {
    let elapsed = ContinuousClock.now - start
    let components = elapsed.components
    return components.seconds * 1_000_000_000 + components.attoseconds / 1_000_000_000
}

/// Map a Valkey error to the corresponding metric status.
@available(valkeySwift 1.0, *)
@usableFromInline
func valkeyMetricsStatus(for error: ValkeyClientError) -> ValkeyCommandStatus {
    if error.errorCode == .timeout {
        return .timeout
    }
    if error.errorCode == .cancelled || error.errorCode == .connectionClosedDueToCancellation {
        return .cancelled
    }
    return .error
}

// MARK: - Recording

/// Internal conformance that lets `ValkeyClient` and `ValkeyClusterClient` share a single set of
/// metric recording helpers. Each client exposes the handles it was configured with via
/// ``valkeyMetrics``.
@available(valkeySwift 1.0, *)
@usableFromInline
protocol ValkeyMetricsRecording {
    /// The client's metric handles, or `nil` when metrics emission is disabled.
    var valkeyMetrics: ValkeyMetricsStore? { get }
}

@available(valkeySwift 1.0, *)
extension ValkeyMetricsRecording {
    /// The instant to measure a command's latency from, or `nil` when metrics are disabled.
    ///
    /// Returning an optional keeps the clock unread when nothing will be recorded.
    @usableFromInline
    func startMetricsTiming() -> ContinuousClock.Instant? {
        self.valkeyMetrics != nil ? .now : nil
    }

    /// Record a single-command latency sample if metrics timing was started.
    @usableFromInline
    func recordCommandMetrics<Command: ValkeyCommand>(
        _ type: Command.Type,
        start: ContinuousClock.Instant?,
        status: ValkeyCommandStatus
    ) {
        guard let metrics = self.valkeyMetrics, let start else { return }
        metrics.commandMetrics(for: type).timer(for: status).recordNanoseconds(valkeyElapsedNanoseconds(since: start))
    }

    /// Record a pipeline latency sample plus its batch size if metrics timing was started.
    @usableFromInline
    func recordPipelineMetrics(start: ContinuousClock.Instant?, batchSize: Int) {
        guard let metrics = self.valkeyMetrics, let start else { return }
        metrics.pipeline.timer.recordNanoseconds(valkeyElapsedNanoseconds(since: start))
        metrics.pipeline.sizeRecorder.record(batchSize)
    }

    /// Record a transaction latency sample plus the number of queued commands (excluding MULTI/EXEC).
    @usableFromInline
    func recordTransactionMetrics(start: ContinuousClock.Instant?, batchSize: Int) {
        guard let metrics = self.valkeyMetrics, let start else { return }
        metrics.transaction.timer.recordNanoseconds(valkeyElapsedNanoseconds(since: start))
        metrics.transaction.sizeRecorder.record(batchSize)
    }
}
#endif
