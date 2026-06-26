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
import Synchronization
import Testing

@testable import Valkey

@Suite(.serialized)
struct MetricsTests {
    static let factory: CapturingMetricsFactory = {
        let factory = CapturingMetricsFactory()
        MetricsSystem.bootstrap(factory)
        return factory
    }()

    private static let primaryAddress = TestStandaloneTopology.Address(host: "127.0.0.1", port: 9100)

    @available(valkeySwift 1.0, *)
    private func withClient(
        mockConnections: MockServerConnections,
        metricsEnabled: Bool = true,
        logger: Logger,
        operation: @escaping @Sendable (ValkeyClient) async throws -> Void
    ) async throws {
        var clientConfig = ValkeyClientConfiguration()
        clientConfig.metrics.enabled = metricsEnabled
        let client = ValkeyClient(
            .hostname(Self.primaryAddress.host, port: Self.primaryAddress.port),
            customHandler: mockConnections.connectionManagerCustomHandler,
            configuration: clientConfig,
            eventLoopGroup: mockConnections.eventLoop,
            logger: logger
        )
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { await client.run() }
            group.addTask { try await operation(client) }
            try await group.next()
            group.cancelAll()
        }
    }

    @available(valkeySwift 1.0, *)
    private func makeTopology() async -> TestStandaloneTopology {
        await TestStandaloneTopology(primary: Self.primaryAddress, replicas: [])
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testSingleCommandSuccessRecordsTimer() async throws {
        Self.factory.reset()
        let logger = Logger(label: "test")
        let topology = await self.makeTopology()
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withClient(mockConnections: mockConnections, logger: logger) { client in
            try await client.set("foo", value: "Bar")
            let value = try await client.get("foo")
            #expect(value.map { String($0) } == "Bar")
        }

        let label = "valkey.command.get.duration"
        #expect(Self.factory.timerSamples(label: label, status: "ok").count == 1)
        #expect(Self.factory.timerSamples(label: label, status: "error").isEmpty)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testSingleCommandErrorRecordsErrorStatus() async throws {
        Self.factory.reset()
        let logger = Logger(label: "test")
        let mockConnections = MockServerConnections(logger: logger)
        await mockConnections.addValkeyServer(.hostname(Self.primaryAddress.host, port: Self.primaryAddress.port)) { command in
            var iterator = command.makeIterator()
            switch iterator.next() {
            case "GET":
                return .bulkError("ERR boom")
            case "ROLE":
                return .array([
                    .bulkString("master"),
                    .number(1001),
                    .array([]),
                ])
            default:
                return nil
            }
        }
        async let _ = mockConnections.run()
        try await withClient(mockConnections: mockConnections, logger: logger) { client in
            do {
                _ = try await client.get("foo")
                Issue.record("expected error")
            } catch let error as ValkeyClientError {
                #expect(error.errorCode == .commandError)
            }
        }

        let label = "valkey.command.get.duration"
        #expect(Self.factory.timerSamples(label: label, status: "error").count == 1)
        #expect(Self.factory.timerSamples(label: label, status: "ok").isEmpty)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testPipelineRecordsTimerAndSize() async throws {
        Self.factory.reset()
        let logger = Logger(label: "test")
        let topology = await self.makeTopology()
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withClient(mockConnections: mockConnections, logger: logger) { client in
            try await client.set("foo", value: "a")
            try await client.set("bar", value: "b")
            // Reset samples so only the pipeline call is measured below.
            Self.factory.reset()
            _ = await client.execute(GET("foo"), GET("bar"))
        }

        #expect(Self.factory.timerSamples(label: "valkey.pipeline.duration", status: nil).count == 1)
        #expect(Self.factory.recorderSamples(label: "valkey.pipeline.size") == [2.0])
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testTransactionRecordsTimerAndSize() async throws {
        Self.factory.reset()
        let logger = Logger(label: "test")
        let mockConnections = MockServerConnections(logger: logger)
        // The tests open a single connection so a single shared MULTI/EXEC state is sufficient.
        let queuedCount = Mutex<Int>(0)
        let inTransaction = Mutex<Bool>(false)
        await mockConnections.addValkeyServer(.hostname(Self.primaryAddress.host, port: Self.primaryAddress.port)) { command in
            var iterator = command.makeIterator()
            switch iterator.next() {
            case "MULTI":
                inTransaction.withLock { $0 = true }
                queuedCount.withLock { $0 = 0 }
                return .simpleString("OK")
            case "EXEC":
                let count = queuedCount.withLock { value -> Int in
                    let count = value
                    value = 0
                    return count
                }
                inTransaction.withLock { $0 = false }
                return .array(Array(repeating: .simpleString("OK"), count: count))
            case "ROLE":
                return .array([
                    .bulkString("master"),
                    .number(1001),
                    .array([]),
                ])
            default:
                if inTransaction.withLock({ $0 }) {
                    queuedCount.withLock { $0 += 1 }
                    return .simpleString("QUEUED")
                }
                return nil
            }
        }
        async let _ = mockConnections.run()
        try await withClient(mockConnections: mockConnections, logger: logger) { client in
            _ = try await client.transaction(SET("foo", value: "10"), INCR("foo"))
        }

        #expect(Self.factory.timerSamples(label: "valkey.transaction.duration", status: nil).count == 1)
        #expect(Self.factory.recorderSamples(label: "valkey.transaction.size") == [2.0])
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testMetricsDisabledSkipsEmission() async throws {
        Self.factory.reset()
        let logger = Logger(label: "test")
        let topology = await self.makeTopology()
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withClient(mockConnections: mockConnections, metricsEnabled: false, logger: logger) { client in
            try await client.set("foo", value: "Bar")
            _ = try await client.get("foo")
        }

        let label = "valkey.command.get.duration"
        #expect(Self.factory.timerSamples(label: label, status: "ok").isEmpty)
        #expect(Self.factory.timerSamples(label: label, status: "error").isEmpty)
    }

    /// Nested suite for cluster-client metrics. Lives inside `MetricsTests` so it inherits the
    /// outer `.serialized` trait — that single ordering is what keeps cluster and standalone
    /// tests from interleaving on the shared `factory` and the process-wide
    /// `ValkeyMetrics.pipelineMetrics` / `transactionMetrics` handles.
    @Suite
    struct Cluster {
        private var sixNodeHealthyCluster: TestCluster {
            get async {
                await TestCluster(shards: [
                    TestCluster.Shard(
                        hashKeyRanges: [0...5460],
                        primary: .init(host: "127.0.0.1", port: 17000),
                        replicas: [.init(host: "127.0.0.1", port: 17001)]
                    ),
                    TestCluster.Shard(
                        hashKeyRanges: [5461...10922],
                        primary: .init(host: "127.0.0.1", port: 17002),
                        replicas: [.init(host: "127.0.0.1", port: 17003)]
                    ),
                    TestCluster.Shard(
                        hashKeyRanges: [10923...16383],
                        primary: .init(host: "127.0.0.1", port: 17004),
                        replicas: [.init(host: "127.0.0.1", port: 17005)]
                    ),
                ])
            }
        }

        @available(valkeySwift 1.0, *)
        private func withClient(
            mockConnections: MockServerConnections,
            logger: Logger,
            operation: @escaping @Sendable (ValkeyClusterClient) async throws -> Void
        ) async throws {
            var clientConfig = ValkeyClientConfiguration(readOnlyCommandNodeSelection: .cycleReplicas)
            clientConfig.metrics.enabled = true
            let client = ValkeyClusterClient(
                nodeDiscovery: ValkeyStaticNodeDiscovery([.init(endpoint: "127.0.0.1", port: 17000)]),
                configuration: .init(client: clientConfig),
                eventLoopGroup: mockConnections.eventLoop,
                logger: logger,
                channelFactory: mockConnections.connectionManagerCustomHandler
            )
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { await client.run() }
                group.addTask { try await operation(client) }
                try await group.next()
                group.cancelAll()
            }
        }

        /// Pipeline that hits a MOVED redirect (slot migrated to another shard) must produce exactly
        /// one pipeline metric sample per user-level call regardless of the per-node retry happening
        /// inside the cluster client.
        @Test
        @available(valkeySwift 1.0, *)
        func testClusterPipelineWithMovedRetryRecordsOnce() async throws {
            MetricsTests.factory.reset()
            var logger = Logger(label: "Valkey")
            logger.logLevel = .debug
            let cluster = await self.sixNodeHealthyCluster
            let mockConnections = await cluster.mock(logger: logger)
            async let _ = mockConnections.run()
            try await withClient(mockConnections: mockConnections, logger: logger) { client in
                try await client.set("randomKey", value: "before")
                // Migrate the slot for "randomKey" to shard 2 so the next pipeline gets MOVED
                // on shard 0 and the cluster client retries against the new owner.
                let hashSlot = HashSlot(key: "randomKey".utf8).rawValue
                await cluster.migrateSlots(hashSlot...hashSlot, to: 2)

                MetricsTests.factory.reset()
                let results = await client.execute(
                    GET("randomKey"),
                    SET("randomKey", value: "after"),
                    GET("randomKey")
                )
                try #expect(results.0.get().map { String($0) } == "before")
                try #expect(results.2.get().map { String($0) } == "after")

                #expect(MetricsTests.factory.timerSamples(label: "valkey.pipeline.duration", status: nil).count == 1)
                #expect(MetricsTests.factory.recorderSamples(label: "valkey.pipeline.size") == [3.0])
            }
        }

        /// Same invariant for transactions: a single user-level transaction call produces exactly one
        /// transaction metric sample regardless of MOVED retries.
        @Test
        @available(valkeySwift 1.0, *)
        func testClusterTransactionWithMovedRetryRecordsOnce() async throws {
            MetricsTests.factory.reset()
            var logger = Logger(label: "Valkey")
            logger.logLevel = .debug
            let cluster = await self.sixNodeHealthyCluster
            let mockConnections = await cluster.mock(logger: logger)
            async let _ = mockConnections.run()
            try await withClient(mockConnections: mockConnections, logger: logger) { client in
                try await client.set("txnKey", value: "before")
                let hashSlot = HashSlot(key: "txnKey".utf8).rawValue
                await cluster.migrateSlots(hashSlot...hashSlot, to: 2)

                MetricsTests.factory.reset()
                _ = try await client.transaction(
                    SET("txnKey", value: "v1"),
                    SET("txnKey", value: "v2")
                )

                #expect(MetricsTests.factory.timerSamples(label: "valkey.transaction.duration", status: nil).count == 1)
                #expect(MetricsTests.factory.recorderSamples(label: "valkey.transaction.size") == [2.0])
            }
        }
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
