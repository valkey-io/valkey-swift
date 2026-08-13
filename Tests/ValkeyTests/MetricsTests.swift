//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

#if MetricsSupport
import Logging
import MetricsTestKit
import Synchronization
import Testing

@testable import Valkey

@Suite
struct MetricsTests {
    private static let primaryAddress = TestStandaloneTopology.Address(host: "127.0.0.1", port: 9100)

    /// Runs `operation` against a client that records into a `TestMetrics` factory created for this
    /// test alone.
    ///
    /// Because the factory is injected rather than bootstrapped into `MetricsSystem`, each test sees
    /// only its own samples and tests can run in parallel.
    ///
    /// - Parameters:
    ///   - mockConnections: The mock servers the client talks to.
    ///   - metricsEnabled: Whether the client is configured to record into the factory at all.
    ///   - logger: Logger.
    ///   - operation: Closure run with the client and the factory it records into.
    @available(valkeySwift 1.0, *)
    private func withClientAndMetricsFactory(
        mockConnections: MockServerConnections,
        metricsEnabled: Bool = true,
        logger: Logger,
        operation: @escaping @Sendable (ValkeyClient, TestMetrics) async throws -> Void
    ) async throws {
        let factory = TestMetrics()
        var clientConfig = ValkeyClientConfiguration()
        clientConfig.metrics.factory = metricsEnabled ? factory : nil
        let client = ValkeyClient(
            .hostname(Self.primaryAddress.host, port: Self.primaryAddress.port),
            customHandler: mockConnections.connectionManagerCustomHandler,
            configuration: clientConfig,
            eventLoopGroup: mockConnections.eventLoop,
            logger: logger
        )
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { await client.run() }
            group.addTask { try await operation(client, factory) }
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
        let logger = Logger(label: "test")
        let topology = await self.makeTopology()
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withClientAndMetricsFactory(mockConnections: mockConnections, logger: logger) { client, factory in
            try await client.set("foo", value: "Bar")
            let value = try await client.get("foo")
            #expect(value.map { String($0) } == "Bar")

            let label = "valkey.command.get.duration"
            #expect(factory.timerSamples(label: label, status: "ok").count == 1)
            #expect(factory.timerSamples(label: label, status: "error").isEmpty)
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testSingleCommandErrorRecordsErrorStatus() async throws {
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
        try await withClientAndMetricsFactory(mockConnections: mockConnections, logger: logger) { client, factory in
            do {
                _ = try await client.get("foo")
                Issue.record("expected error")
            } catch let error as ValkeyClientError {
                // Any RESP error reply, simple or bulk, reaches the caller as `.commandError`.
                #expect(error.errorCode == .commandError)
                #expect(error.message == "ERR boom")
            }

            let label = "valkey.command.get.duration"
            #expect(factory.timerSamples(label: label, status: "error").count == 1)
            #expect(factory.timerSamples(label: label, status: "ok").isEmpty)
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testPipelineRecordsTimerAndSize() async throws {
        let logger = Logger(label: "test")
        let topology = await self.makeTopology()
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withClientAndMetricsFactory(mockConnections: mockConnections, logger: logger) { client, factory in
            _ = await client.execute(GET("foo"), GET("bar"))

            #expect(factory.timerSamples(label: "valkey.pipeline.duration").count == 1)
            #expect(factory.recorderSamples(label: "valkey.pipeline.size") == [2.0])
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testTransactionRecordsTimerAndSize() async throws {
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
        try await withClientAndMetricsFactory(mockConnections: mockConnections, logger: logger) { client, factory in
            _ = try await client.transaction(SET("foo", value: "10"), INCR("foo"))

            #expect(factory.timerSamples(label: "valkey.transaction.duration").count == 1)
            #expect(factory.recorderSamples(label: "valkey.transaction.size") == [2.0])
        }
    }

    /// A client with no ``ValkeyMetricsConfiguration/factory`` must not create a single metric, let
    /// alone record into one.
    @Test
    @available(valkeySwift 1.0, *)
    func testMetricsDisabledSkipsEmission() async throws {
        let logger = Logger(label: "test")
        let topology = await self.makeTopology()
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withClientAndMetricsFactory(mockConnections: mockConnections, metricsEnabled: false, logger: logger) { client, factory in
            try await client.set("foo", value: "Bar")
            _ = try await client.get("foo")
            _ = await client.execute(GET("foo"), GET("foo"))

            #expect(factory.timers.isEmpty)
            #expect(factory.recorders.isEmpty)
        }
    }

    /// Nested suite for cluster-client metrics.
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

        /// Cluster-client counterpart of ``MetricsTests/withClientAndMetricsFactory(mockConnections:metricsEnabled:logger:operation:)``.
        @available(valkeySwift 1.0, *)
        private func withClientAndMetricsFactory(
            mockConnections: MockServerConnections,
            logger: Logger,
            operation: @escaping @Sendable (ValkeyClusterClient, TestMetrics) async throws -> Void
        ) async throws {
            let factory = TestMetrics()
            var clientConfig = ValkeyClientConfiguration(readOnlyCommandNodeSelection: .cycleReplicas)
            clientConfig.metrics.factory = factory
            let client = ValkeyClusterClient(
                nodeDiscovery: ValkeyStaticNodeDiscovery([.init(endpoint: "127.0.0.1", port: 17000)]),
                configuration: .init(client: clientConfig),
                eventLoopGroup: mockConnections.eventLoop,
                logger: logger,
                channelFactory: mockConnections.connectionManagerCustomHandler
            )
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { await client.run() }
                group.addTask { try await operation(client, factory) }
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
            var logger = Logger(label: "Valkey")
            logger.logLevel = .debug
            let cluster = await self.sixNodeHealthyCluster
            let mockConnections = await cluster.mock(logger: logger)
            async let _ = mockConnections.run()
            try await withClientAndMetricsFactory(mockConnections: mockConnections, logger: logger) { client, factory in
                try await client.set("randomKey", value: "before")
                // Migrate the slot for "randomKey" to shard 2 so the next pipeline gets MOVED
                // on shard 0 and the cluster client retries against the new owner.
                let hashSlot = HashSlot(key: "randomKey".utf8).rawValue
                await cluster.migrateSlots(hashSlot...hashSlot, to: 2)

                let results = await client.execute(
                    GET("randomKey"),
                    SET("randomKey", value: "after"),
                    GET("randomKey")
                )
                try #expect(results.0.get().map { String($0) } == "before")
                try #expect(results.2.get().map { String($0) } == "after")

                #expect(factory.timerSamples(label: "valkey.pipeline.duration").count == 1)
                #expect(factory.recorderSamples(label: "valkey.pipeline.size") == [3.0])
            }
        }

        /// Same invariant for transactions: a single user-level transaction call produces exactly one
        /// transaction metric sample regardless of MOVED retries.
        @Test
        @available(valkeySwift 1.0, *)
        func testClusterTransactionWithMovedRetryRecordsOnce() async throws {
            var logger = Logger(label: "Valkey")
            logger.logLevel = .debug
            let cluster = await self.sixNodeHealthyCluster
            let mockConnections = await cluster.mock(logger: logger)
            async let _ = mockConnections.run()
            try await withClientAndMetricsFactory(mockConnections: mockConnections, logger: logger) { client, factory in
                try await client.set("txnKey", value: "before")
                let hashSlot = HashSlot(key: "txnKey".utf8).rawValue
                await cluster.migrateSlots(hashSlot...hashSlot, to: 2)

                _ = try await client.transaction(
                    SET("txnKey", value: "v1"),
                    SET("txnKey", value: "v2")
                )

                #expect(factory.timerSamples(label: "valkey.transaction.duration").count == 1)
                #expect(factory.recorderSamples(label: "valkey.transaction.size") == [2.0])
            }
        }
    }
}

// MARK: - Sample lookup

extension TestMetrics {
    /// Samples recorded by the timer with `label`, optionally qualified by a `status` dimension.
    ///
    /// Returns an empty array when the client never created that timer, so that a test can assert
    /// nothing was recorded without having to distinguish "no samples" from "no such timer".
    fileprivate func timerSamples(label: String, status: String? = nil) -> [Int64] {
        let dimensions = status.map { [("status", $0)] } ?? []
        return (try? self.expectTimer(label, dimensions))?.values ?? []
    }

    /// Samples recorded by the recorder with `label`, or an empty array when it was never created.
    fileprivate func recorderSamples(label: String) -> [Double] {
        (try? self.expectRecorder(label))?.values ?? []
    }
}
#endif
