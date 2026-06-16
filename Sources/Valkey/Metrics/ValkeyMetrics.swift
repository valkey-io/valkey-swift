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

    init(prefix: String, commandName: String) {
        let label = "\(prefix).command.\(commandName.lowercased()).duration"
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
final class ValkeyPipelineMetrics: Sendable {
    @usableFromInline let timer: Timer
    @usableFromInline let sizeRecorder: Recorder

    init(prefix: String) {
        self.timer = Timer(label: "\(prefix).pipeline.duration")
        self.sizeRecorder = Recorder(label: "\(prefix).pipeline.size")
    }
}

/// Transaction-level metric pair: latency timer plus batch-size recorder.
///
/// Tracked separately from pipelines because MULTI/EXEC has different semantics and operators
/// usually want to see transaction latency in isolation.
@available(valkeySwift 1.0, *)
@usableFromInline
final class ValkeyTransactionMetrics: Sendable {
    @usableFromInline let timer: Timer
    @usableFromInline let sizeRecorder: Recorder

    init(prefix: String) {
        self.timer = Timer(label: "\(prefix).transaction.duration")
        self.sizeRecorder = Recorder(label: "\(prefix).transaction.size")
    }
}

/// Process-wide cache of metric handles.
///
/// Cache keys include the configured label prefix so two clients configured with different
/// prefixes do not stomp on each other's handles. The cache is keyed by the command type's
/// ``ObjectIdentifier`` so we never allocate a `String` for the command name on the hot path.
@available(valkeySwift 1.0, *)
@usableFromInline
enum ValkeyMetrics {
    @usableFromInline
    struct CommandKey: Hashable, Sendable {
        @usableFromInline let prefix: String
        @usableFromInline let typeID: ObjectIdentifier
    }

    static let commandCache: Mutex<[CommandKey: ValkeyCommandMetrics]> = .init([:])
    static let pipelineCache: Mutex<[String: ValkeyPipelineMetrics]> = .init([:])
    static let transactionCache: Mutex<[String: ValkeyTransactionMetrics]> = .init([:])

    @usableFromInline
    static func commandMetrics<Command: ValkeyCommand>(
        for type: Command.Type,
        prefix: String
    ) -> ValkeyCommandMetrics {
        let key = CommandKey(prefix: prefix, typeID: ObjectIdentifier(type))
        return self.commandCache.withLock { cache in
            if let cached = cache[key] {
                return cached
            }
            let metrics = ValkeyCommandMetrics(prefix: prefix, commandName: Command.name)
            cache[key] = metrics
            return metrics
        }
    }

    @usableFromInline
    static func pipelineMetrics(prefix: String) -> ValkeyPipelineMetrics {
        self.pipelineCache.withLock { cache in
            if let cached = cache[prefix] {
                return cached
            }
            let metrics = ValkeyPipelineMetrics(prefix: prefix)
            cache[prefix] = metrics
            return metrics
        }
    }

    /// Record a command latency sample.
    ///
    /// - Parameters:
    ///   - type: The command type. Used as the cache key.
    ///   - configuration: The metrics configuration. The call is a no-op if `enabled` is false.
    ///   - status: The outcome of the command, used as the `status` dimension.
    ///   - nanoseconds: The measured latency.
    @usableFromInline
    static func recordCommand<Command: ValkeyCommand>(
        _ type: Command.Type,
        configuration: ValkeyMetricsConfiguration,
        status: ValkeyCommandStatus,
        nanoseconds: Int64
    ) {
        guard configuration.enabled else { return }
        let metrics = self.commandMetrics(for: type, prefix: configuration.labelPrefix)
        metrics.timer(for: status).recordNanoseconds(nanoseconds)
    }

    /// Record a pipeline latency sample plus its batch size.
    @usableFromInline
    static func recordPipeline(
        configuration: ValkeyMetricsConfiguration,
        batchSize: Int,
        nanoseconds: Int64
    ) {
        guard configuration.enabled else { return }
        let metrics = self.pipelineMetrics(prefix: configuration.labelPrefix)
        metrics.timer.recordNanoseconds(nanoseconds)
        metrics.sizeRecorder.record(batchSize)
    }

    @usableFromInline
    static func transactionMetrics(prefix: String) -> ValkeyTransactionMetrics {
        self.transactionCache.withLock { cache in
            if let cached = cache[prefix] {
                return cached
            }
            let metrics = ValkeyTransactionMetrics(prefix: prefix)
            cache[prefix] = metrics
            return metrics
        }
    }

    /// Record a transaction latency sample plus the number of queued commands (excluding MULTI/EXEC).
    @usableFromInline
    static func recordTransaction(
        configuration: ValkeyMetricsConfiguration,
        batchSize: Int,
        nanoseconds: Int64
    ) {
        guard configuration.enabled else { return }
        let metrics = self.transactionMetrics(prefix: configuration.labelPrefix)
        metrics.timer.recordNanoseconds(nanoseconds)
        metrics.sizeRecorder.record(batchSize)
    }
}

/// Convert the elapsed `Duration` between two `ContinuousClock` instants to nanoseconds.
@available(valkeySwift 1.0, *)
@usableFromInline
func valkeyElapsedNanoseconds(since start: ContinuousClock.Instant) -> Int64 {
    let elapsed = ContinuousClock.now - start
    let components = elapsed.components
    return components.seconds &* 1_000_000_000 &+ (components.attoseconds / 1_000_000_000)
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
#endif
