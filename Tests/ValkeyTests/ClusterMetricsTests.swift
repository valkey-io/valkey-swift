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
import NIOCore
import Testing

@testable import Valkey

@Suite(.serialized)
struct ClusterMetricsTests {
    static let factory: CapturingMetricsFactory = MetricsTests.factory

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
        Self.factory.reset()
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

            Self.factory.reset()
            let results = await client.execute(
                GET("randomKey"),
                SET("randomKey", value: "after"),
                GET("randomKey")
            )
            try #expect(results.0.get().map { String($0) } == "before")
            try #expect(results.2.get().map { String($0) } == "after")

            #expect(Self.factory.timerSamples(label: "valkey.pipeline.duration", status: nil).count == 1)
            #expect(Self.factory.recorderSamples(label: "valkey.pipeline.size") == [3.0])
        }
    }

    /// Same invariant for transactions: a single user-level transaction call produces exactly one
    /// transaction metric sample regardless of MOVED retries.
    @Test
    @available(valkeySwift 1.0, *)
    func testClusterTransactionWithMovedRetryRecordsOnce() async throws {
        Self.factory.reset()
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let cluster = await self.sixNodeHealthyCluster
        let mockConnections = await cluster.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withClient(mockConnections: mockConnections, logger: logger) { client in
            try await client.set("txnKey", value: "before")
            let hashSlot = HashSlot(key: "txnKey".utf8).rawValue
            await cluster.migrateSlots(hashSlot...hashSlot, to: 2)

            Self.factory.reset()
            _ = try await client.transaction(
                SET("txnKey", value: "v1"),
                SET("txnKey", value: "v2")
            )

            #expect(Self.factory.timerSamples(label: "valkey.transaction.duration", status: nil).count == 1)
            #expect(Self.factory.recorderSamples(label: "valkey.transaction.size") == [2.0])
        }
    }
}
#endif
