//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import Logging
import NIOCore
import NIOEmbedded
import Testing
import Valkey

/// Valkey Cluster description
actor Cluster {
    enum Role {
        case primary
        case replica
    }
    struct Address: Hashable, CustomStringConvertible {
        let host: String
        let port: Int

        var description: String { "\(host):\(port)" }
    }
    struct Shard {
        struct Node {
            var address: Address
            var health: ValkeyClusterDescription.Node.Health
        }
        var hashKeyRanges: [ClosedRange<UInt16>]
        var primary: Node
        var replicas: [Node]

        init(
            hashKeyRanges: [ClosedRange<UInt16>],
            primary: Cluster.Address,
            replicas: [Cluster.Address]
        ) {
            self.hashKeyRanges = hashKeyRanges
            self.primary = .init(address: primary, health: .online)
            self.replicas = replicas.map { .init(address: $0, health: .online) }
        }

        mutating func failover() {
            guard let replica = replicas.first else { return }
            replicas[0] = primary
            primary = replica
        }

        mutating func shutdownNode(address: Address) {
            if self.primary.address == address {
                self.primary.health = .fail
                guard self.replicas.count > 0 else { return }
                self.primary = self.replicas.removeLast()
                self.replicas.append(.init(address: address, health: .fail))
                return
            } else {
                for index in self.replicas.indices {
                    if self.replicas[index].address == address {
                        self.replicas[index].health = .fail
                    }
                }
            }
        }

        mutating func removeHashSlotRange(_ slots: ClosedRange<UInt16>) {
            for rangeIndex in self.hashKeyRanges.indices {
                guard self.hashKeyRanges[rangeIndex].contains(slots) else { continue }
                let ranges = hashKeyRanges[rangeIndex].removeRange(slots)
                hashKeyRanges[rangeIndex] = ranges[0]
                if hashKeyRanges.count > 1 {
                    hashKeyRanges.append(contentsOf: hashKeyRanges.dropFirst())
                }
            }
        }

        mutating func addHashSlotRange(_ slots: ClosedRange<UInt16>) {
            self.hashKeyRanges.append(slots)
        }

        /// Shard description for CLUSTER SHARDS
        var respValue: RESP3Value {
            let hashKeyArray: RESP3Value = .array(self.hashKeyRanges.flatMap { [.number(Int64($0.first!)), .number(Int64($0.last!))] })
            var nodes: [RESP3Value] = [
                .map([
                    .bulkString("id"): .bulkString(String(primary.address.hashValue)),
                    .bulkString("port"): .number(Int64(primary.address.port)),
                    .bulkString("ip"): .bulkString(primary.address.host),
                    .bulkString("endpoint"): .bulkString(primary.address.host),
                    .bulkString("role"): .bulkString("master"),
                    .bulkString("replication-offset"): .number(70000),
                    .bulkString("health"): .bulkString(primary.health.rawValue),
                ])
            ]
            for replica in replicas {
                nodes.append(
                    .map([
                        .bulkString("id"): .bulkString(String(replica.address.hashValue)),
                        .bulkString("port"): .number(Int64(replica.address.port)),
                        .bulkString("ip"): .bulkString(replica.address.host),
                        .bulkString("endpoint"): .bulkString(replica.address.host),
                        .bulkString("role"): .bulkString("replica"),
                        .bulkString("replication-offset"): .number(70000),
                        .bulkString("health"): .bulkString(replica.health.rawValue),
                    ])
                )
            }
            return .map([
                .bulkString("slots"): hashKeyArray,
                .bulkString("nodes"): .array(nodes),
            ])

        }
    }
    var shards: [Shard]
    private(set) var addressMap: [Address: (role: Role, shardIndex: Int)]
    var keyValueMap: [String: String]

    init(shards: [Shard]) async {
        self.addressMap = [:]
        self.shards = shards
        self.keyValueMap = [:]
        self.updateAddressMap()
    }

    func updateAddressMap() {
        self.addressMap = [:]
        for index in self.shards.indices {
            let shard = self.shards[index]
            self.addressMap[shard.primary.address] = (.primary, index)
            for replica in shard.replicas {
                self.addressMap[replica.address] = (.replica, index)
            }
        }
    }

    func failover(shardIndex: Int) {
        self.shards[shardIndex].failover()
        self.updateAddressMap()
    }

    func shutdownNode(address: Address) {
        for index in shards.indices {
            shards[index].shutdownNode(address: address)
        }
        self.updateAddressMap()
    }

    func migrateSlots(_ slots: ClosedRange<UInt16>, to shardIndex: Int) {
        for index in shards.indices {
            self.shards[index].removeHashSlotRange(slots)
        }
        self.shards[shardIndex].addHashSlotRange(slots)
        self.updateAddressMap()
    }

    func setKey(_ key: String, value: String) {
        self.keyValueMap[key] = value
    }

    func getKey(_ key: String) -> String? {
        self.keyValueMap[key]
    }

    func getShard(_ hashSlot: HashSlot) -> (index: Int, shard: Shard)? {
        for index in shards.indices {
            for keyRange in self.shards[index].hashKeyRanges {
                if keyRange.contains(hashSlot.rawValue) {
                    return (index, self.shards[index])
                }
            }
        }
        return nil
    }

    /// Create Mock servers for cluster
    func mock(logger: Logger) async -> MockServerConnections {
        let mockConnections = MockServerConnections(logger: logger)
        for address in self.addressMap.keys {
            await addNode(to: mockConnections, address: address, logger: logger)
        }
        return mockConnections
    }

    /// Add shard to cluster and add mock servers for the new shard
    func addShard(_ shard: Shard, to mockConnections: MockServerConnections, logger: Logger) async {
        self.shards.append(shard)
        self.updateAddressMap()
        await self.addNode(to: mockConnections, address: shard.primary.address, logger: logger)
        for replica in shard.replicas {
            await self.addNode(to: mockConnections, address: replica.address, logger: logger)
        }
    }

    /// Add Valkey node to mock connections
    func addNode(to mockConnections: MockServerConnections, address: Cluster.Address, logger: Logger) async {
        await mockConnections.addValkeyServer(.hostname(address.host, port: address.port)) { command in
            var iterator = command.makeIterator()
            switch iterator.next() {
            case "GET":
                guard let key = iterator.next() else { return .bulkError("ERR invalid command") }
                let hashSlot = HashSlot(key: key.utf8)
                guard let shard = await self.getShard(hashSlot) else { return .null }
                let addressDetails = await self.addressMap[address]
                if shard.index != addressDetails?.shardIndex {
                    return .bulkError("MOVED \(hashSlot.rawValue) \(shard.shard.primary.address)")
                }
                // Keys with $address prefix are special as they return the address of the node
                if key.hasPrefix("$address") {
                    return .bulkString(address.description)
                }
                return await self.getKey(key).map { .bulkString($0) } ?? .null

            case "SET":
                guard let key = iterator.next() else { return .bulkError("ERR invalid command") }
                guard let value = iterator.next() else { return .bulkError("ERR invalid command") }
                let hashSlot = HashSlot(key: key.utf8)
                guard let shard = await self.getShard(hashSlot) else { return .null }
                let addressDetails = await self.addressMap[address]
                if shard.index != addressDetails?.shardIndex || addressDetails?.role == .replica {
                    return .bulkError("MOVED \(hashSlot.rawValue) \(shard.shard.primary.address)")
                }
                // Keys with $address prefix are special as they return the address of the node
                if key.hasPrefix("$address") {
                    return .bulkString(address.description)
                }
                await self.setKey(key, value: value)
                return .simpleString("OK")
            case "CLUSTER":
                switch iterator.next() {
                case "SHARDS":
                    return await .array(self.shards.map { $0.respValue })

                default:
                    return nil
                }
            default:
                return nil
            }
        }
    }
}

@Suite("Test ValkeyClusterClient using mock cluster")
struct ValkeyClusterClientTests {
    var sixNodeHealthyCluster: Cluster {
        get async {
            await Cluster(shards: [
                Cluster.Shard(
                    hashKeyRanges: [0...5460],
                    primary: .init(host: "127.0.0.1", port: 16000),
                    replicas: [.init(host: "127.0.0.1", port: 16001)]
                ),
                Cluster.Shard(
                    hashKeyRanges: [5461...10922],
                    primary: .init(host: "127.0.0.1", port: 16002),
                    replicas: [.init(host: "127.0.0.1", port: 16003)]
                ),
                Cluster.Shard(
                    hashKeyRanges: [10923...16383],
                    primary: .init(host: "127.0.0.1", port: 16004),
                    replicas: [.init(host: "127.0.0.1", port: 16005)]
                ),
            ])
        }
    }

    @available(valkeySwift 1.0, *)
    func withValkeyClusterClient(
        _ address: (host: String, port: Int),
        mockConnections: MockServerConnections,
        configuration: ValkeyClusterClientConfiguration = .init(client: .init(readOnlyCommandNodeSelection: .cycleReplicas)),
        logger: Logger,
        operation: @escaping @Sendable (ValkeyClusterClient) async throws -> Void
    ) async throws {
        let client = ValkeyClusterClient(
            nodeDiscovery: ValkeyStaticNodeDiscovery([.init(endpoint: address.host, port: address.port)]),
            configuration: configuration,
            eventLoopGroup: mockConnections.eventLoop,
            logger: logger,
            channelFactory: mockConnections.connectionManagerCustomHandler
        )

        return try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                await client.run()
            }
            group.addTask {
                try await operation(client)
            }
            try await group.next()
            group.cancelAll()
        }
    }

    @available(valkeySwift 1.0, *)
    @Test
    func testGetSet() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let cluster = await self.sixNodeHealthyCluster
        let mockConnections = await cluster.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeyClusterClient((host: "127.0.0.1", port: 16000), mockConnections: mockConnections, logger: logger) { client in
            var value = try await client.get("$address{1}")
            #expect(value.map { String($0) } == "127.0.0.1:16003")
            value = try await client.set("$address{1}", value: "test")
            #expect(value.map { String($0) } == "127.0.0.1:16002")
            value = try await client.get("$address{3}")
            #expect(value.map { String($0) } == "127.0.0.1:16001")
            value = try await client.set("$address{3}", value: "test")
            #expect(value.map { String($0) } == "127.0.0.1:16000")
            value = try await client.get("$address{4}")
            #expect(value.map { String($0) } == "127.0.0.1:16005")
            value = try await client.set("$address{4}", value: "test")
            #expect(value.map { String($0) } == "127.0.0.1:16004")
        }
    }

    @available(valkeySwift 1.0, *)
    @Test
    func testPipeline() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let cluster = await self.sixNodeHealthyCluster
        let mockConnections = await cluster.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeyClusterClient((host: "127.0.0.1", port: 16000), mockConnections: mockConnections, logger: logger) { client in
            let results = await client.execute(
                SET("$address{3}", value: "test"),
                SET("$address{4}", value: "test"),
                SET("$address{1}", value: "test"),
                GET("$address{3}")
            )
            try #expect(results.0.get().map { String($0) } == "127.0.0.1:16000")
            try #expect(results.1.get().map { String($0) } == "127.0.0.1:16004")
            try #expect(results.2.get().map { String($0) } == "127.0.0.1:16002")
            // Pipelining will use the primary if any commands are writable.
            try #expect(results.3.get().map { String($0) } == "127.0.0.1:16000")
        }
    }

    @available(valkeySwift 1.0, *)
    @Test
    func testFailover() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let cluster = await self.sixNodeHealthyCluster
        let mockConnections = await cluster.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeyClusterClient((host: "127.0.0.1", port: 16000), mockConnections: mockConnections, logger: logger) { client in
            let value = try await client.set("$address{3}", value: "test")
            #expect(value.map { String($0) } == "127.0.0.1:16000")

            await cluster.failover(shardIndex: 0)

            // run multiple commands concurrently
            try await withThrowingTaskGroup { group in
                for _ in 0..<16 {
                    group.addTask {
                        try await Task.sleep(for: .milliseconds(.random(in: 0..<500)))
                        let value = try await client.set("$address{3}", value: "test")
                        #expect(value.map { String($0) } == "127.0.0.1:16001")
                    }
                }
                try await group.waitForAll()
            }

        }
    }

    @available(valkeySwift 1.0, *)
    @Test
    func testSlotMigration() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let cluster = await self.sixNodeHealthyCluster
        let mockConnections = await cluster.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeyClusterClient((host: "127.0.0.1", port: 16000), mockConnections: mockConnections, logger: logger) { client in
            let value = try await client.set("$address{3}", value: "test")
            #expect(value.map { String($0) } == "127.0.0.1:16000")

            let hashSlot = HashSlot(key: "$address{3}".utf8).rawValue
            await cluster.migrateSlots(hashSlot...hashSlot, to: 1)

            // run multiple commands concurrently
            try await withThrowingTaskGroup { group in
                for _ in 0..<16 {
                    group.addTask {
                        try await Task.sleep(for: .milliseconds(.random(in: 0..<500)))
                        let value = try await client.set("$address{3}", value: "test")
                        #expect(value.map { String($0) } == "127.0.0.1:16002")
                    }
                }
                try await group.waitForAll()
            }
        }
    }

    @available(valkeySwift 1.0, *)
    @Test
    func testPipelineAfterSlotMigration() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let cluster = await self.sixNodeHealthyCluster
        let mockConnections = await cluster.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeyClusterClient((host: "127.0.0.1", port: 16000), mockConnections: mockConnections, logger: logger) { client in
            try await client.set("randomKey", value: "before")

            let hashSlot = HashSlot(key: "randomKey".utf8).rawValue
            await cluster.migrateSlots(hashSlot...hashSlot, to: 2)

            let results = await client.execute(
                GET("randomKey"),
                SET("randomKey", value: "after"),
                GET("randomKey")
            )
            try #expect(results.0.get().map { String($0) } == "before")
            try #expect(results.2.get().map { String($0) } == "after")
        }
    }

    @available(valkeySwift 1.0, *)
    @Test
    func testAddShardSlotMigration() async throws {
        let logger = {
            var logger = Logger(label: "Valkey")
            logger.logLevel = .trace
            return logger
        }()
        let cluster = await self.sixNodeHealthyCluster
        let mockConnections = await cluster.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeyClusterClient((host: "127.0.0.1", port: 16000), mockConnections: mockConnections, logger: logger) { client in
            let value = try await client.set("$address{3}", value: "test")
            #expect(value.map { String($0) } == "127.0.0.1:16000")

            let hashSlot = HashSlot(key: "$address{3}".utf8).rawValue
            await cluster.addShard(
                Cluster.Shard(
                    hashKeyRanges: [],
                    primary: .init(host: "127.0.0.1", port: 16006),
                    replicas: [.init(host: "127.0.0.1", port: 16007)]
                ),
                to: mockConnections,
                logger: logger
            )
            await cluster.migrateSlots(hashSlot...hashSlot, to: cluster.shards.count - 1)

            // run multiple commands concurrently
            try await withThrowingTaskGroup { group in
                for _ in 0..<16 {
                    group.addTask {
                        try await Task.sleep(for: .milliseconds(.random(in: 0..<250)))
                        let value = try await client.set("$address{3}", value: "test")
                        #expect(value.map { String($0) } == "127.0.0.1:16006")
                    }
                }
                try await group.waitForAll()
            }
        }
    }

    @available(valkeySwift 1.0, *)
    @Test
    func testHardFailover() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let cluster = await self.sixNodeHealthyCluster
        let mockConnections = await cluster.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeyClusterClient(
            (host: "127.0.0.1", port: 16000),
            mockConnections: mockConnections,
            configuration: .init(client: .init(readOnlyCommandNodeSelection: .cycleReplicas), clusterRefreshInterval: .seconds(2)),
            logger: logger
        ) { client in
            var value = try await client.set("$address{3}", value: "test")
            #expect(value.map { String($0) } == "127.0.0.1:16000")

            let primaryAddress = await cluster.shards[0].primary.address
            await mockConnections.shutdownServer(.hostname(primaryAddress.host, port: primaryAddress.port))
            await cluster.shutdownNode(address: primaryAddress)
            value = try await client.set("$address{3}", value: "test")
            #expect(value.map { String($0) } == "127.0.0.1:16001")
        }
    }
}

extension ClosedRange<UInt16> {
    fileprivate func removeRange(_ range: ClosedRange<UInt16>) -> [ClosedRange<UInt16>] {
        let range = range.clamped(to: self)
        guard let first, let last, let rangeFirst = range.first, let rangeLast = range.last else { return [self] }
        var ranges: [ClosedRange<UInt16>] = []
        if first < rangeFirst {
            let leftRange = first...(rangeFirst - 1)
            if !leftRange.isEmpty {
                ranges.append(leftRange)
            }
        }
        if last > rangeLast {
            let rightRange = (rangeLast + 1)...last
            if !rightRange.isEmpty {
                ranges.append(rightRange)
            }
        }
        return ranges
    }
}
