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

    /// The status to record for a failed command.
    @usableFromInline
    init(error: ValkeyClientError) {
        if error.errorCode == .timeout {
            self = .timeout
        } else if error.errorCode == .cancelled || error.errorCode == .connectionClosedDueToCancellation {
            self = .cancelled
        } else {
            self = .error
        }
    }
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

/// Every metric handle a single client records into, all created from the `MetricsFactory` that
/// client was configured with.
///
/// A client creates one instance when it is initialized and holds it for its lifetime: `Timer` and
/// `Recorder` resolve their handler from the factory at creation time, so recreating them per
/// command would both allocate on the hot path and go through the factory's own lookup each time.
///
/// Transactions are tracked separately from pipelines because MULTI/EXEC has different semantics and
/// operators usually want to see transaction latency in isolation.
///
/// The handles are deliberately never `destroy()`ed. Factories generally return the same handler for
/// a given label and dimension set, so destroying handles as one client shuts down could stop
/// recording for other clients that share the factory.
@available(valkeySwift 1.0, *)
@usableFromInline
final class ValkeyMetrics: Sendable {
    private let pipelineTimer: Timer
    private let pipelineSizeRecorder: Recorder
    private let transactionTimer: Timer
    private let transactionSizeRecorder: Recorder

    private let factory: any MetricsFactory
    /// Per-command-type handles, created on first use of each command and keyed by command name.
    private let commandMetricsCache: Mutex<[String: ValkeyCommandMetrics]>

    /// Creates the handles a client records into, or `nil` when metrics emission is disabled.
    ///
    /// - Parameter factory: The configured factory, or `nil` to emit no metrics.
    init?(factory: (any MetricsFactory)?) {
        guard let factory else { return nil }
        self.factory = factory
        self.pipelineTimer = Timer(label: "valkey.pipeline.duration", factory: factory)
        self.pipelineSizeRecorder = Recorder(label: "valkey.pipeline.size", factory: factory)
        self.transactionTimer = Timer(label: "valkey.transaction.duration", factory: factory)
        self.transactionSizeRecorder = Recorder(label: "valkey.transaction.size", factory: factory)
        self.commandMetricsCache = .init([:])
    }

    /// The instant to measure latency from.
    ///
    /// Callers reach this through `self.valkeyMetrics?.startTiming()`, so the clock goes unread and
    /// the result is `nil` when metrics are disabled.
    @usableFromInline
    func startTiming() -> ContinuousClock.Instant {
        .now
    }

    /// Record a single-command latency sample if metrics timing was started.
    @usableFromInline
    func recordCommand<Command: ValkeyCommand>(
        _ type: Command.Type,
        start: ContinuousClock.Instant?,
        status: ValkeyCommandStatus
    ) {
        guard let start else { return }
        self.commandMetrics(for: type).timer(for: status).recordNanoseconds(self.elapsedNanoseconds(since: start))
    }

    /// Record a pipeline latency sample plus its batch size if metrics timing was started.
    @usableFromInline
    func recordPipeline(start: ContinuousClock.Instant?, batchSize: Int) {
        guard let start else { return }
        self.pipelineTimer.recordNanoseconds(self.elapsedNanoseconds(since: start))
        self.pipelineSizeRecorder.record(batchSize)
    }

    /// Record a transaction latency sample plus the number of queued commands (excluding MULTI/EXEC).
    @usableFromInline
    func recordTransaction(start: ContinuousClock.Instant?, batchSize: Int) {
        guard let start else { return }
        self.transactionTimer.recordNanoseconds(self.elapsedNanoseconds(since: start))
        self.transactionSizeRecorder.record(batchSize)
    }

    /// Nanoseconds elapsed since `start`.
    private func elapsedNanoseconds(since start: ContinuousClock.Instant) -> Int64 {
        let elapsed = ContinuousClock.now - start
        let components = elapsed.components
        return components.seconds * 1_000_000_000 + components.attoseconds / 1_000_000_000
    }

    /// The timers for `Command`, creating them from the client's factory on first use.
    private func commandMetrics<Command: ValkeyCommand>(for type: Command.Type) -> ValkeyCommandMetrics {
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

#endif
