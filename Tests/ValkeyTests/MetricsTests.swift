//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

#if MetricsSupport
import Logging
import Metrics
import MetricsTestKit
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
    private func withClient(
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
        try await withClient(mockConnections: mockConnections, logger: logger) { client, factory in
            try await client.set("foo", value: "Bar")
            let value = try await client.get("foo")
            #expect(value.map { String($0) } == "Bar")

            // A successful operation carries no `error.type` at all.
            #expect(factory.operationSamples("GET").count == 1)
            #expect(factory.operationSamples("GET", errorType: "ERR").isEmpty)
        }
    }

    /// Durations are displayed in seconds by default, the unit OpenTelemetry semantics specify.
    @Test
    @available(valkeySwift 1.0, *)
    func testDefaultDisplayUnitIsSeconds() async throws {
        let logger = Logger(label: "test")
        let topology = await self.makeTopology()
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withClient(mockConnections: mockConnections, logger: logger) { client, factory in
            _ = try await client.get("foo")

            let timer = try factory.expectTimer(
                "db.client.operation.duration",
                [
                    ("db.system.name", "valkey"),
                    ("db.namespace", "0"),
                    ("db.operation.name", "GET"),
                ]
            )
            #expect(timer.displayUnit == .seconds)
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
        try await withClient(mockConnections: mockConnections, logger: logger) { client, factory in
            do {
                _ = try await client.get("foo")
                Issue.record("expected error")
            } catch let error as ValkeyClientError {
                // Any RESP error reply, simple or bulk, reaches the caller as `.commandError`.
                #expect(error.errorCode == .commandError)
                #expect(error.message == "ERR boom")
            }

            // `error.type` carries the Valkey error prefix from "ERR boom".
            #expect(factory.operationSamples("GET", errorType: "ERR").count == 1)
            #expect(factory.operationSamples("GET").isEmpty)
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
        try await withClient(mockConnections: mockConnections, metricsEnabled: false, logger: logger) { client, factory in
            try await client.set("foo", value: "Bar")
            _ = try await client.get("foo")

            #expect(factory.timers.isEmpty)
            #expect(factory.recorders.isEmpty)
        }
    }

    /// Every label, dimension name, static dimension value and the display unit is overridable, for
    /// users whose backend has its own naming scheme.
    @Test
    @available(valkeySwift 1.0, *)
    func testMetricNamesAreOverridable() async throws {
        let logger = Logger(label: "test")
        let topology = await self.makeTopology()
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()

        let factory = TestMetrics()
        var clientConfig = ValkeyClientConfiguration()
        clientConfig.metrics.factory = factory
        clientConfig.metrics.labels.operationDuration = "custom.duration"
        clientConfig.metrics.dimensionNames.databaseOperationName = "custom.operation"
        clientConfig.metrics.dimensionNames.databaseSystemName = "custom.system"
        clientConfig.metrics.dimensionNames.databaseNamespace = "custom.namespace"
        clientConfig.metrics.dimensionValues.databaseSystem = "my-valkey"
        clientConfig.metrics.preferredDisplayUnit = .microseconds

        let client = ValkeyClient(
            .hostname(Self.primaryAddress.host, port: Self.primaryAddress.port),
            customHandler: mockConnections.connectionManagerCustomHandler,
            configuration: clientConfig,
            eventLoopGroup: mockConnections.eventLoop,
            logger: logger
        )
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { await client.run() }
            group.addTask {
                _ = try await client.get("foo")

                let timer = try #require(
                    try? factory.expectTimer(
                        "custom.duration",
                        [
                            ("custom.system", "my-valkey"),
                            ("custom.namespace", "0"),
                            ("custom.operation", "GET"),
                        ]
                    )
                )
                #expect(timer.values.count == 1)
                #expect(timer.displayUnit == .microseconds)
                // Nothing was recorded under the defaults.
                #expect(factory.operationSamples("GET").isEmpty)
            }
            try await group.next()
            group.cancelAll()
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

        /// Cluster-client counterpart of ``MetricsTests/withClient(mockConnections:metricsEnabled:logger:operation:)``.
        @available(valkeySwift 1.0, *)
        private func withClient(
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

        /// A command that hits a MOVED redirect (slot migrated to another shard) must produce exactly
        /// one metric sample per user-level call regardless of the retry happening inside the cluster
        /// client.
        @Test
        @available(valkeySwift 1.0, *)
        func testClusterCommandWithMovedRetryRecordsOnce() async throws {
            let logger = Logger(label: "Valkey")
            let cluster = await self.sixNodeHealthyCluster
            let mockConnections = await cluster.mock(logger: logger)
            async let _ = mockConnections.run()
            try await withClient(mockConnections: mockConnections, logger: logger) { client, factory in
                try await client.set("randomKey", value: "before")
                // Migrate the slot for "randomKey" to shard 2 so the next GET gets MOVED on shard 0
                // and the cluster client retries against the new owner.
                let hashSlot = HashSlot(key: "randomKey".utf8).rawValue
                await cluster.migrateSlots(hashSlot...hashSlot, to: 2)

                let value = try await client.get("randomKey")
                #expect(value.map { String($0) } == "before")

                #expect(factory.operationSamples("GET").count == 1)
            }
        }
    }
}

// MARK: - Sample lookup

extension TestMetrics {
    /// Samples recorded under the default `db.client.operation.duration` timer for `operationName`,
    /// optionally qualified by an `error.type` dimension.
    ///
    /// Returns an empty array when the client never created that timer, so that a test can assert
    /// nothing was recorded without having to distinguish "no samples" from "no such timer".
    fileprivate func operationSamples(_ operationName: String, errorType: String? = nil, databaseNumber: Int = 0) -> [Int64] {
        var dimensions = [
            ("db.system.name", "valkey"),
            ("db.namespace", String(databaseNumber)),
            ("db.operation.name", operationName),
        ]
        if let errorType {
            dimensions.append(("error.type", errorType))
        }
        return (try? self.expectTimer("db.client.operation.duration", dimensions))?.values ?? []
    }
}
#endif
