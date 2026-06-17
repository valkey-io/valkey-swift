//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

#if MetricsSupport
import Foundation
import Logging
import Metrics
import NIOCore
import NIOEmbedded
import NIOPosix
import Testing

@testable import Valkey

@Suite(.serialized)
struct MetricsTests {
    static let factory: CapturingMetricsFactory = {
        let factory = CapturingMetricsFactory()
        MetricsSystem.bootstrap(factory)
        return factory
    }()

    @Test
    @available(valkeySwift 1.0, *)
    func testSingleCommandSuccessRecordsTimer() async throws {
        let factory = Self.factory
        factory.reset()
        var config = ValkeyConnectionConfiguration()
        config.metrics.enabled = true

        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: config, logger: logger)
        try await channel.processHello()

        async let fooResult = connection.get("foo").map { String($0) }
        _ = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        try await channel.writeInbound(RESPToken(.bulkString("Bar")).base)
        #expect(try await fooResult == "Bar")

        let label = "valkey.command.get.duration"
        let samples = factory.timerSamples(label: label, status: "ok")
        #expect(samples.count == 1)
        #expect((samples.first ?? 0) >= 0)
        #expect(factory.timerSamples(label: label, status: "error").isEmpty)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testSingleCommandErrorRecordsErrorStatus() async throws {
        let factory = Self.factory
        factory.reset()
        var config = ValkeyConnectionConfiguration()
        config.metrics.enabled = true

        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: config, logger: logger)
        try await channel.processHello()

        async let fooResult = connection.get("foo")
        _ = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        try await channel.writeInbound(RESPToken(.simpleError("ERR Error!")).base)

        do {
            _ = try await fooResult
            Issue.record("expected error")
        } catch let error as ValkeyClientError {
            #expect(error.errorCode == .commandError)
        }

        let label = "valkey.command.get.duration"
        #expect(factory.timerSamples(label: label, status: "error").count == 1)
        #expect(factory.timerSamples(label: label, status: "ok").isEmpty)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testPipelineRecordsTimerAndSize() async throws {
        let factory = Self.factory
        factory.reset()
        var config = ValkeyConnectionConfiguration()
        config.metrics.enabled = true

        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: config, logger: logger)
        try await channel.processHello()

        async let results = connection.execute(GET("foo"), GET("bar"))
        _ = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        try await channel.writeInbound(RESPToken(.bulkString("a")).base)
        try await channel.writeInbound(RESPToken(.bulkString("b")).base)
        _ = await results

        let durationSamples = factory.timerSamples(label: "valkey.pipeline.duration", status: nil)
        #expect(durationSamples.count == 1)
        let sizeSamples = factory.recorderSamples(label: "valkey.pipeline.size")
        #expect(sizeSamples == [2.0])
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testTransactionRecordsTimerAndSize() async throws {
        let factory = Self.factory
        factory.reset()
        var config = ValkeyConnectionConfiguration()
        config.metrics.enabled = true

        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: config, logger: logger)
        try await channel.processHello()

        async let results = connection.transaction(
            SET("foo", value: "10"),
            INCR("foo")
        )
        _ = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        try await channel.writeInbound(RESPToken(.simpleString("OK")).base)
        try await channel.writeInbound(RESPToken(.simpleString("QUEUED")).base)
        try await channel.writeInbound(RESPToken(.simpleString("QUEUED")).base)
        try await channel.writeInbound(RESPToken(.array([.simpleString("OK"), .number(11)])).base)
        _ = try await results

        let durationSamples = factory.timerSamples(label: "valkey.transaction.duration", status: nil)
        #expect(durationSamples.count == 1)
        let sizeSamples = factory.recorderSamples(label: "valkey.transaction.size")
        #expect(sizeSamples == [2.0])
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testMetricsDisabledSkipsEmission() async throws {
        let factory = Self.factory
        factory.reset()
        var config = ValkeyConnectionConfiguration()
        config.metrics.enabled = false

        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: config, logger: logger)
        try await channel.processHello()

        async let fooResult = connection.get("foo").map { String($0) }
        _ = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        try await channel.writeInbound(RESPToken(.bulkString("Bar")).base)
        _ = try await fooResult

        let label = "valkey.command.get.duration"
        #expect(factory.timerSamples(label: label, status: "ok").isEmpty)
        #expect(factory.timerSamples(label: label, status: "error").isEmpty)
    }
}

// MARK: - In-memory metrics factory

final class CapturingMetricsFactory: MetricsFactory, @unchecked Sendable {
    struct TimerKey: Hashable {
        let label: String
        let dimensions: [String: String]
    }

    private let lock = NSLock()
    private var timers: [TimerKey: CapturingTimerHandler] = [:]
    private var recorders: [String: CapturingRecorderHandler] = [:]

    func makeCounter(label: String, dimensions: [(String, String)]) -> any CounterHandler {
        NoOpCounter()
    }

    func makeFloatingPointCounter(label: String, dimensions: [(String, String)]) -> any FloatingPointCounterHandler {
        NoOpFloatingPointCounter()
    }

    func makeMeter(label: String, dimensions: [(String, String)]) -> any MeterHandler {
        NoOpMeter()
    }

    func makeRecorder(label: String, dimensions: [(String, String)], aggregate: Bool) -> any RecorderHandler {
        self.lock.lock()
        defer { self.lock.unlock() }
        if let existing = self.recorders[label] {
            return existing
        }
        let handler = CapturingRecorderHandler()
        self.recorders[label] = handler
        return handler
    }

    func makeTimer(label: String, dimensions: [(String, String)]) -> any TimerHandler {
        let key = TimerKey(label: label, dimensions: Dictionary(uniqueKeysWithValues: dimensions))
        self.lock.lock()
        defer { self.lock.unlock() }
        if let existing = self.timers[key] {
            return existing
        }
        let handler = CapturingTimerHandler()
        self.timers[key] = handler
        return handler
    }

    func destroyCounter(_ handler: any CounterHandler) {}
    func destroyFloatingPointCounter(_ handler: any FloatingPointCounterHandler) {}
    func destroyMeter(_ handler: any MeterHandler) {}
    func destroyRecorder(_ handler: any RecorderHandler) {}
    func destroyTimer(_ handler: any TimerHandler) {}

    func timerSamples(label: String, status: String?) -> [Int64] {
        self.lock.lock()
        defer { self.lock.unlock() }
        for (key, handler) in self.timers {
            guard key.label == label else { continue }
            if let status, key.dimensions["status"] != status { continue }
            if status == nil, !key.dimensions.isEmpty { continue }
            return handler.samples()
        }
        return []
    }

    func recorderSamples(label: String) -> [Double] {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.recorders[label]?.samples() ?? []
    }

    /// Clear all captured samples while keeping the handler instances intact.
    ///
    /// Production code holds long-lived `Timer`/`Recorder` references via the
    /// `ValkeyCommandMetricsHolder` / `ValkeyMetrics` statics, which capture handlers from
    /// this factory at first use. Resetting samples between tests gives each test a clean
    /// slate without invalidating those references.
    func reset() {
        self.lock.lock()
        defer { self.lock.unlock() }
        for handler in self.timers.values {
            handler.reset()
        }
        for handler in self.recorders.values {
            handler.reset()
        }
    }
}

final class CapturingTimerHandler: TimerHandler, @unchecked Sendable {
    private let lock = NSLock()
    private var values: [Int64] = []

    func recordNanoseconds(_ duration: Int64) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.values.append(duration)
    }

    func samples() -> [Int64] {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.values
    }

    func reset() {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.values.removeAll(keepingCapacity: true)
    }
}

final class CapturingRecorderHandler: RecorderHandler, @unchecked Sendable {
    private let lock = NSLock()
    private var values: [Double] = []

    func record(_ value: Int64) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.values.append(Double(value))
    }

    func record(_ value: Double) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.values.append(value)
    }

    func samples() -> [Double] {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.values
    }

    func reset() {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.values.removeAll(keepingCapacity: true)
    }
}

final class NoOpCounter: CounterHandler, Sendable {
    func increment(by: Int64) {}
    func reset() {}
}

final class NoOpFloatingPointCounter: FloatingPointCounterHandler, Sendable {
    func increment(by: Double) {}
    func reset() {}
}

final class NoOpMeter: MeterHandler, Sendable {
    func set(_ value: Int64) {}
    func set(_ value: Double) {}
    func increment(by: Double) {}
    func decrement(by: Double) {}
}
#endif
