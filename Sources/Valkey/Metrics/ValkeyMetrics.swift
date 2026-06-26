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

/// Outcome dimension recorded with every command latency sample.
@available(valkeySwift 1.0, *)
@usableFromInline
enum ValkeyCommandStatus: Sendable {
    case ok
    case error
    case timeout
    case cancelled

    @usableFromInline
    var dimensionValue: String {
        switch self {
        case .ok: "ok"
        case .error: "error"
        case .timeout: "timeout"
        case .cancelled: "cancelled"
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

    init(commandName: String) {
        let label = "valkey.command.\(commandName.lowercased()).duration"
        self.ok = Timer(label: label, dimensions: [("status", "ok")])
        self.error = Timer(label: label, dimensions: [("status", "error")])
        self.timeout = Timer(label: label, dimensions: [("status", "timeout")])
        self.cancelled = Timer(label: label, dimensions: [("status", "cancelled")])
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

    init() {
        self.timer = Timer(label: "valkey.pipeline.duration")
        self.sizeRecorder = Recorder(label: "valkey.pipeline.size")
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

    init() {
        self.timer = Timer(label: "valkey.transaction.duration")
        self.sizeRecorder = Recorder(label: "valkey.transaction.size")
    }
}

/// Per-command-type metric handles, looked up by command name.
@available(valkeySwift 1.0, *)
@usableFromInline
enum ValkeyCommandMetricsCache {
    static let storage: Mutex<[String: ValkeyCommandMetrics]> = .init([:])

    @usableFromInline
    static func metrics<Command: ValkeyCommand>(for type: Command.Type) -> ValkeyCommandMetrics {
        self.storage.withLock { cache in
            if let cached = cache[Command.name] {
                return cached
            }
            let metrics = ValkeyCommandMetrics(commandName: Command.name)
            cache[Command.name] = metrics
            return metrics
        }
    }
}

/// Static metric handle namespace.
///
/// Pipeline and transaction handles are process-wide singletons because their labels are
/// fixed (`valkey.pipeline.*` / `valkey.transaction.*`). Per-command handles live on
/// ``ValkeyCommandMetricsCache``.
@available(valkeySwift 1.0, *)
@usableFromInline
enum ValkeyMetrics {
    @usableFromInline
    static let pipelineMetrics = ValkeyPipelineMetrics()

    @usableFromInline
    static let transactionMetrics = ValkeyTransactionMetrics()
}

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

/// Internal conformance that lets `ValkeyClient` and `ValkeyClusterClient` share a single set of
/// metric recording helpers. Each client exposes its own metrics configuration via
/// ``metricsConfiguration``.
@available(valkeySwift 1.0, *)
@usableFromInline
protocol ValkeyMetricsRecording {
    var metricsConfiguration: ValkeyMetricsConfiguration { get }
}

@available(valkeySwift 1.0, *)
extension ValkeyMetricsRecording {
    /// Record a single-command latency sample if metrics timing was started.
    @usableFromInline
    func recordCommandMetrics<Command: ValkeyCommand>(
        _ type: Command.Type,
        start: ContinuousClock.Instant?,
        status: ValkeyCommandStatus
    ) {
        guard self.metricsConfiguration.enabled, let start else { return }
        ValkeyCommandMetricsCache.metrics(for: type).timer(for: status).recordNanoseconds(valkeyElapsedNanoseconds(since: start))
    }

    /// Record a pipeline latency sample plus its batch size if metrics timing was started.
    @usableFromInline
    func recordPipelineMetrics(start: ContinuousClock.Instant?, batchSize: Int) {
        guard self.metricsConfiguration.enabled, let start else { return }
        ValkeyMetrics.pipelineMetrics.timer.recordNanoseconds(valkeyElapsedNanoseconds(since: start))
        ValkeyMetrics.pipelineMetrics.sizeRecorder.record(batchSize)
    }

    /// Record a transaction latency sample plus the number of queued commands (excluding MULTI/EXEC).
    @usableFromInline
    func recordTransactionMetrics(start: ContinuousClock.Instant?, batchSize: Int) {
        guard self.metricsConfiguration.enabled, let start else { return }
        ValkeyMetrics.transactionMetrics.timer.recordNanoseconds(valkeyElapsedNanoseconds(since: start))
        ValkeyMetrics.transactionMetrics.sizeRecorder.record(batchSize)
    }
}
#endif
