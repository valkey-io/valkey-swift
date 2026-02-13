//
// This source file is part of the valkey-swift project
// Copyright (c) 2025-2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
import Logging
import NIOCore
import Testing
import XCTest

@testable import Valkey

@Suite(
    "Cluster Integration Tests",
    .serialized,
    .disabled(if: clusterFirstNodeHostname == nil, "VALKEY_NODE1_HOSTNAME environment variable is not set.")
)
struct ClusterIntegrationTests {
    @Test
    @available(valkeySwift 1.0, *)
    func testSetGet() async throws {
        var logger = Logger(label: "ValkeyCluster")
        logger.logLevel = .trace
        let firstNodeHostname = clusterFirstNodeHostname!
        let firstNodePort = clusterFirstNodePort ?? 6379
        try await Self.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) { client in
            try await Self.withKey(connection: client) { key in
                try await client.set(key, value: "Hello")

                let response = try await client.get(key)
                #expect(response.map { String($0) } == "Hello")
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testWithConnection() async throws {
        var logger = Logger(label: "ValkeyCluster")
        logger.logLevel = .trace
        let firstNodeHostname = clusterFirstNodeHostname!
        let firstNodePort = clusterFirstNodePort ?? 6379
        try await Self.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) { client in
            try await Self.withKey(connection: client) { key in
                try await client.withConnection(forKeys: [key]) { connection in
                    _ = try await connection.set(key, value: "Hello")
                    let response = try await connection.get(key)
                    #expect(response.map { String($0) } == "Hello")
                }
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testWithReadOnlyConnection() async throws {
        var logger = Logger(label: "ValkeyCluster")
        logger.logLevel = .trace
        let firstNodeHostname = clusterFirstNodeHostname!
        let firstNodePort = clusterFirstNodePort ?? 6379
        try await Self.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) { client in
            try await Self.withKey(connection: client) { key in
                try await client.set(key, value: "Hello")
                try await client.withConnection(forKeys: [key], readOnly: true) { connection in
                    let response = try await connection.get(key)
                    #expect(response.map { String($0) } == "Hello")
                }
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testFailover() async throws {
        var logger = Logger(label: "ValkeyCluster")
        logger.logLevel = .trace
        let firstNodeHostname = clusterFirstNodeHostname!
        let firstNodePort = clusterFirstNodePort ?? 6379
        try await Self.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) { clusterClient in
            try await Self.withKey(connection: clusterClient) { key in
                try await clusterClient.set(key, value: "bar")
                let cluster = try await clusterClient.clusterShards()
                let shard = try #require(
                    cluster.shards.first { shard in
                        let hashSlot = HashSlot(key: key)
                        return shard.slots.reduce(into: false) { $0 = $0 || ($1.lowerBound <= hashSlot && $1.upperBound >= hashSlot) }
                    }
                )
                let replica = try #require(shard.nodes.first { $0.role == .replica })
                let port = try #require(replica.port)
                // connect to replica and call CLUSTER FAILOVER
                try await Self.withValkeyClient(.hostname(replica.endpoint, port: port), logger: logger) { client in
                    try await client.clusterFailover()
                }
                // will receive a MOVED error as the primary has moved to a replica
                try await clusterClient.set(key, value: "baz")
                let response = try await clusterClient.get(key)
                #expect(response.map { String($0) } == "baz")
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testHashSlotMigrationAndAskRedirection() async throws {
        var logger = Logger(label: "ValkeyCluster")
        logger.logLevel = .trace
        let firstNodeHostname = clusterFirstNodeHostname!
        let firstNodePort = clusterFirstNodePort ?? 6379
        try await Self.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) { client in
            let keySuffix = "{\(UUID().uuidString)}"
            try await Self.withKey(connection: client, suffix: keySuffix) { key in
                let hashSlot = HashSlot(key: key)
                try await client.set(key, value: "Testing before import")

                try await Self.testMigratingHashSlot(hashSlot, client: client) {
                    // key still uses nodeA
                    let value = try await client.set(key, value: "Testing during import", get: true).map { String($0) }
                    #expect(value == "Testing before import")
                } afterMigrate: {
                    // key has been migrated to nodeB so will receive an ASK error
                    let value = try await client.set(key, value: "After migrate", get: true).map { String($0) }
                    #expect(value == "Testing during import")
                } finished: {
                    let value = try await client.set(key, value: "Testing after import", get: true).map { String($0) }
                    #expect(value == "After migrate")
                }
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testHashSlotMigrationAndTryAgain() async throws {
        var logger = Logger(label: "ValkeyCluster")
        logger.logLevel = .trace
        let firstNodeHostname = clusterFirstNodeHostname!
        let firstNodePort = clusterFirstNodePort ?? 6379
        try await Self.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) { client in
            let keySuffix = "{\(UUID().uuidString)}"
            try await Self.withKey(connection: client, suffix: keySuffix) { key in
                try await Self.withKey(connection: client, suffix: keySuffix) { key2 in
                    let hashSlot = HashSlot(key: key)
                    try await client.lpush(key, elements: ["testing"])

                    try await Self.testMigratingHashSlot(hashSlot, client: client) {
                    } duringMigrate: {
                        try await client.rpoplpush(source: key, destination: key2)
                    }
                }
            }
        }
    }
    @Test
    @available(valkeySwift 1.0, *)
    func testClusterClientSubscriptions() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        var logger = Logger(label: "Subscriptions")
        logger.logLevel = .trace
        let firstNodeHostname = clusterFirstNodeHostname!
        let firstNodePort = clusterFirstNodePort ?? 6379
        try await Self.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) { client in
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await client.subscribe(to: "testSubscriptions") { subscription in
                        cont.finish()
                        var iterator = subscription.makeAsyncIterator()
                        await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "hello" }
                        await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "goodbye" }
                    }
                }
                await stream.first { _ in true }
                try await Task.sleep(for: .milliseconds(100))
                _ = try await client.publish(channel: "testSubscriptions", message: "hello")
                _ = try await client.publish(channel: "testSubscriptions", message: "goodbye")
                try await group.waitForAll()
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testClientSubscriptionsTwice() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        var logger = Logger(label: "Subscriptions")
        logger.logLevel = .trace
        let firstNodeHostname = clusterFirstNodeHostname!
        let firstNodePort = clusterFirstNodePort ?? 6379
        try await Self.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) { client in
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await client.subscribe(to: "testSubscriptions") { subscription in
                        cont.yield()
                        var iterator = subscription.makeAsyncIterator()
                        await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "hello" }
                        await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "goodbye" }
                    }
                    try await client.subscribe(to: "testSubscriptions") { subscription in
                        cont.finish()
                        var iterator = subscription.makeAsyncIterator()
                        await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "hello" }
                        await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "goodbye" }
                    }
                }
                await stream.first { _ in true }
                try await Task.sleep(for: .milliseconds(10))
                _ = try await client.publish(channel: "testSubscriptions", message: "hello")
                _ = try await client.publish(channel: "testSubscriptions", message: "goodbye")
                await stream.first { _ in true }
                try await Task.sleep(for: .milliseconds(10))
                _ = try await client.publish(channel: "testSubscriptions", message: "hello")
                _ = try await client.publish(channel: "testSubscriptions", message: "goodbye")
                try await group.waitForAll()
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testClientMultipleSubscriptions() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        var logger = Logger(label: "Subscriptions")
        logger.logLevel = .trace
        let firstNodeHostname = clusterFirstNodeHostname!
        let firstNodePort = clusterFirstNodePort ?? 6379
        try await Self.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) { client in
            try await withThrowingTaskGroup(of: Void.self) { group in
                let count = 50
                for i in 0..<count {
                    group.addTask {
                        try await client.subscribe(to: ["sub\(i)", "sub\(i+1)"]) { subscription in
                            cont.yield()
                            var iterator = subscription.makeAsyncIterator()
                            await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "\(i)" }
                            client.logger.info("Received \(i): \(i)")
                            await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "\(i+1)" }
                            client.logger.info("Received \(i): \(i+1)")
                        }
                    }
                }
                var iterator = stream.makeAsyncIterator()
                for _ in 0..<count {
                    await iterator.next()
                }

                try await Task.sleep(for: .milliseconds(200))
                for i in 0..<(count + 1) {
                    try await client.publish(channel: "sub\(i)", message: "\(i)")
                    client.logger.info("Published \(i)")
                }
                try await group.waitForAll()
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testClientCancelSubscription() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        var logger = Logger(label: "Subscriptions")
        logger.logLevel = .trace
        let firstNodeHostname = clusterFirstNodeHostname!
        let firstNodePort = clusterFirstNodePort ?? 6379
        try await Self.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) { client in
            await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await client.subscribe(to: "testCancelSubscriptions") { subscription in
                        cont.finish()
                        for try await _ in subscription {
                        }
                    }
                }
                await stream.first { _ in true }
                group.cancelAll()
            }
        }
    }

    @available(valkeySwift 1.0, *)
    static func testMigratingHashSlot(
        _ hashSlot: HashSlot,
        client: ValkeyClusterClient,
        beforeMigrate: () async throws -> Void,
        duringMigrate: sending () async throws -> Void = {},
        afterMigrate: () async throws -> Void = {},
        finished: () async throws -> Void = {}
    ) async throws {
        let nodeAClient = try await client.nodeClient(for: [hashSlot], nodeSelection: .primary)
        // find another shard
        var nodeBClient: ValkeyNodeClient
        repeat {
            nodeBClient = try await client.nodeClient(for: [HashSlot(rawValue: Int.random(in: 0..<16384))!], nodeSelection: .primary)
        } while nodeAClient === nodeBClient

        guard let (hostnameA, portA) = nodeAClient.serverAddress.getHostnameAndPort() else { return }
        guard let (hostnameB, portB) = nodeBClient.serverAddress.getHostnameAndPort() else { return }
        let clientAID = try await nodeAClient.execute(CLUSTER.MYID())
        let clientBID = try await nodeBClient.execute(CLUSTER.MYID())

        let result: Result<Void, any Error>
        do {
            // start migration by setting hash slot state
            client.logger.info("SETSLOT importing")
            _ = try await nodeBClient.execute(CLUSTER.SETSLOT(slot: numericCast(hashSlot.rawValue), subcommand: .importing(clientAID)))
            _ = try await nodeAClient.execute(CLUSTER.SETSLOT(slot: numericCast(hashSlot.rawValue), subcommand: .migrating(clientBID)))

            async let duringMigrateTask: Void = duringMigrate()

            try await beforeMigrate()

            // get keys associated with slot and migrate them
            client.logger.info("MIGRATE")
            let keys = try await nodeAClient.execute(CLUSTER.GETKEYSINSLOT(slot: numericCast(hashSlot.rawValue), count: 100))
            // key doesnt exist on nodeA anymore, so we receive an ASK error
            _ = try await nodeAClient.execute(
                MIGRATE(host: hostnameB, port: portB, keySelector: .emptyString, destinationDb: 0, timeout: 5000, keys: keys)
            )

            try await afterMigrate()

            // finalise migration
            client.logger.info("SETSLOT node")
            _ = try await nodeAClient.execute(CLUSTER.SETSLOT(slot: numericCast(hashSlot.rawValue), subcommand: .node(clientBID)))
            _ = try await nodeBClient.execute(CLUSTER.SETSLOT(slot: numericCast(hashSlot.rawValue), subcommand: .node(clientBID)))

            // wait for during migrate
            try await duringMigrateTask

            try await finished()
            result = .success(())
        } catch {
            result = .failure(error)
        }
        // revert everything
        _ = try await nodeBClient.execute(CLUSTER.SETSLOT(slot: numericCast(hashSlot.rawValue), subcommand: .migrating(clientAID)))
        _ = try await nodeAClient.execute(CLUSTER.SETSLOT(slot: numericCast(hashSlot.rawValue), subcommand: .importing(clientBID)))
        let keys2 = try await nodeBClient.execute(CLUSTER.GETKEYSINSLOT(slot: numericCast(hashSlot.rawValue), count: 100))
        _ = try await nodeBClient.execute(
            MIGRATE(host: hostnameA, port: portA, keySelector: .emptyString, destinationDb: 0, timeout: 5000, keys: keys2)
        )
        _ = try await nodeAClient.execute(CLUSTER.SETSLOT(slot: numericCast(hashSlot.rawValue), subcommand: .node(clientAID)))
        _ = try await nodeBClient.execute(CLUSTER.SETSLOT(slot: numericCast(hashSlot.rawValue), subcommand: .node(clientAID)))

        try result.get()
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testClusterLinks() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await Self.withValkeyCluster([(host: clusterFirstNodeHostname!, port: clusterFirstNodePort ?? 36001)], logger: logger) { client in
            let clusterLinks = try await client.clusterLinks()
            #expect(!clusterLinks.isEmpty && clusterLinks.count > 0)
            for clusterLink in clusterLinks {
                #expect(clusterLink.direction == .from || clusterLink.direction == .to)
                #expect(!clusterLink.node.isEmpty)
                #expect(clusterLink.createTime > 0)
                #expect(!clusterLink.events.isEmpty)
                #expect(clusterLink.sendBufferAllocated >= 0)
                #expect(clusterLink.sendBufferUsed >= 0)
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testClusterSlotStats() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug

        try await Self.withValkeyCluster([(host: clusterFirstNodeHostname!, port: clusterFirstNodePort ?? 36001)], logger: logger) { client in
            let slotStats = try await client.clusterSlotStats(
                filter: .orderby(
                    CLUSTER.SLOTSTATS.FilterOrderby(
                        metric: "key-count",
                        limit: 10,
                        order: .desc
                    )
                )
            )
            #expect(!slotStats.isEmpty && slotStats.count == 10)
            for slotStat in slotStats {
                // slot is a required field, other fields are optional
                #expect(slotStat.slot >= 0 && slotStat.slot <= 16383)
                if let keyCount = slotStat.keyCount {
                    #expect(keyCount >= 0)
                }
                if let cpuUsec = slotStat.cpuUsec {
                    #expect(cpuUsec >= 0)
                }
                if let networkBytesIn = slotStat.networkBytesIn {
                    #expect(networkBytesIn >= 0)
                }
                if let networkBytesOut = slotStat.networkBytesOut {
                    #expect(networkBytesOut >= 0)
                }
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testClusterSlots() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await Self.withValkeyCluster([(host: clusterFirstNodeHostname!, port: clusterFirstNodePort ?? 36001)], logger: logger) { client in
            let clusterSlots = try await client.clusterSlots()
            for clusterSlot in clusterSlots {
                #expect(clusterSlot.startSlot >= 0 && clusterSlot.startSlot <= 16383)
                #expect(clusterSlot.endSlot >= 0 && clusterSlot.endSlot <= 16383)
                for node in clusterSlot.nodes {
                    #expect(!node.ip.isEmpty)
                    #expect(node.port >= 0 && node.port <= 65535)
                    #expect(!node.nodeId.isEmpty)
                }
            }
        }
    }

    @Suite("Pipelining Tests")
    struct Pipeline {
        @Test
        @available(valkeySwift 1.0, *)
        func testNodePipeline() async throws {
            var logger = Logger(label: "ValkeyCluster")
            logger.logLevel = .trace
            let firstNodeHostname = clusterFirstNodeHostname!
            let firstNodePort = clusterFirstNodePort ?? 6379
            try await ClusterIntegrationTests.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) {
                client in
                try await ClusterIntegrationTests.withKey(connection: client, suffix: "{foo}") { key in
                    let node = try await client.nodeClient(for: [HashSlot(key: key)], nodeSelection: .primary)
                    var commands: [any ValkeyCommand] = .init()
                    commands.append(SET(key, value: "cluster pipeline test"))
                    commands.append(GET(key))
                    let results = try await client.execute(node: node, commands: commands)
                    let response = try results[1].get().decode(as: String.self)
                    #expect(response == "cluster pipeline test")
                }
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testNodePipelineMultipleHashKeysSameShard() async throws {
            var logger = Logger(label: "ValkeyCluster")
            logger.logLevel = .trace
            let firstNodeHostname = clusterFirstNodeHostname!
            let firstNodePort = clusterFirstNodePort ?? 6379
            try await ClusterIntegrationTests.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) {
                client in
                try await ClusterIntegrationTests.withKey(connection: client, suffix: "{foo}") { key in
                    let hashSlot = HashSlot(key: key)
                    let node = try await client.nodeClient(for: [hashSlot], nodeSelection: .primary)
                    // get a key from same node
                    let key2 = try await {
                        while true {
                            let key2 = ValkeyKey(UUID().uuidString)
                            let hashSlot2 = HashSlot(key: key2)
                            let node2 = try await client.nodeClient(for: [hashSlot2], nodeSelection: .primary)
                            if node2.serverAddress == node.serverAddress {
                                return key2
                            }
                        }
                    }()
                    var commands: [any ValkeyCommand] = .init()
                    commands.append(SET(key, value: "cluster pipeline test"))
                    commands.append(GET(key))
                    commands.append(SET(key2, value: "cluster pipeline test"))
                    commands.append(GET(key2))
                    commands.append(DEL(keys: [key]))
                    let results = try await client.execute(node: node, commands: commands)
                    let response = try results[1].get().decode(as: String.self)
                    #expect(response == "cluster pipeline test")
                }
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testNodePipelineMultipleHashKeysDifferentShards() async throws {
            // this will receive MOVED errors and deal with them
            var logger = Logger(label: "ValkeyCluster")
            logger.logLevel = .trace
            let firstNodeHostname = clusterFirstNodeHostname!
            let firstNodePort = clusterFirstNodePort ?? 6379
            try await ClusterIntegrationTests.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) {
                client in
                try await ClusterIntegrationTests.withKey(connection: client, suffix: "{foo}") { key in
                    let hashSlot = HashSlot(key: key)
                    let node = try await client.nodeClient(for: [hashSlot], nodeSelection: .primary)
                    let key2 = try await {
                        while true {
                            let key2 = ValkeyKey(UUID().uuidString)
                            let hashSlot2 = HashSlot(key: key2)
                            let node2 = try await client.nodeClient(for: [hashSlot2], nodeSelection: .primary)
                            if node2.serverAddress != node.serverAddress {
                                return key2
                            }
                        }
                    }()
                    var commands: [any ValkeyCommand] = .init()
                    commands.append(SET(key, value: "cluster pipeline test"))
                    commands.append(GET(key))
                    commands.append(GET(key2))
                    let results = try await client.execute(node: node, commands: commands)
                    let response = try results[1].get().decode(as: String.self)
                    #expect(response == "cluster pipeline test")
                }
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testNodePipelineWithErrorsNotZeroBasedArray() async throws {
            // this will receive MOVED errors and deal with them. The collection passed into the execute
            // function has a non-zero start index
            var logger = Logger(label: "ValkeyCluster")
            logger.logLevel = .trace
            let firstNodeHostname = clusterFirstNodeHostname!
            let firstNodePort = clusterFirstNodePort ?? 6379
            try await ClusterIntegrationTests.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) {
                client in
                try await ClusterIntegrationTests.withKey(connection: client, suffix: "{foo}") { key in
                    let hashSlot = HashSlot(key: key)
                    let node = try await client.nodeClient(for: [hashSlot], nodeSelection: .primary)
                    let key2 = try await {
                        while true {
                            let key2 = ValkeyKey(UUID().uuidString)
                            let hashSlot2 = HashSlot(key: key2)
                            let node2 = try await client.nodeClient(for: [hashSlot2], nodeSelection: .primary)
                            if node2.serverAddress != node.serverAddress {
                                return key2
                            }
                        }
                    }()
                    var commands: [any ValkeyCommand] = .init()
                    commands.append(ECHO(message: "ignore"))
                    commands.append(SET(key, value: "cluster pipeline test"))
                    commands.append(GET(key))
                    commands.append(SET(key2, value: "cluster pipeline test"))
                    commands.append(GET(key2))
                    commands.append(DEL(keys: [key2]))
                    let results = try await client.execute(node: node, commands: commands.dropFirst())
                    let response = try results[3].get().decode(as: String.self)
                    #expect(response == "cluster pipeline test")
                }
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testNodePipelineWithFailover() async throws {
            var logger = Logger(label: "ValkeyCluster")
            logger.logLevel = .trace
            let firstNodeHostname = clusterFirstNodeHostname!
            let firstNodePort = clusterFirstNodePort ?? 6379
            try await ClusterIntegrationTests.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) {
                clusterClient in
                try await ClusterIntegrationTests.withKey(connection: clusterClient) { key in
                    let node = try await clusterClient.nodeClient(for: [HashSlot(key: key)], nodeSelection: .primary)
                    try await clusterClient.set(key, value: "bar")
                    let cluster = try await clusterClient.clusterShards()
                    let shard = try #require(
                        cluster.shards.first { shard in
                            let hashSlot = HashSlot(key: key)
                            return shard.slots.reduce(into: false) { $0 = ($0 || ($1.lowerBound <= hashSlot && $1.upperBound >= hashSlot)) }
                        }
                    )
                    let replica = try #require(shard.nodes.first { $0.role == .replica })
                    let port = try #require(replica.port)
                    // connect to replica and call CLUSTER FAILOVER
                    try await ClusterIntegrationTests.withValkeyClient(.hostname(replica.endpoint, port: port), logger: logger) { client in
                        try await client.clusterFailover()
                    }
                    // will receive a MOVED errors for SET, INCR as the primary has moved to a replica
                    var commands: [any ValkeyCommand] = .init()
                    commands.append(SET(key, value: "100"))
                    commands.append(INCR(key))
                    commands.append(ECHO(message: "Test non moved command"))
                    let results = try await clusterClient.execute(node: node, commands: commands)
                    #expect(try results[0].get().decode(as: String.self) == "OK")
                    #expect(try results[1].get().decode(as: String.self) == "101")
                    let response2 = try results[2].get().decode(as: String.self)
                    #expect(response2 == "Test non moved command")
                    let getResponse = try await clusterClient.get(key).map { String($0) }
                    #expect(getResponse == "101")
                }
            }
        }

        @available(valkeySwift 1.0, *)
        @Test
        func testNodePipelineWithHashSlotMigrationAndAskRedirection() async throws {
            var logger = Logger(label: "ValkeyCluster")
            logger.logLevel = .trace
            let firstNodeHostname = clusterFirstNodeHostname!
            let firstNodePort = clusterFirstNodePort ?? 6379
            try await ClusterIntegrationTests.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) {
                client in
                let keySuffix = "{\(UUID().uuidString)}"
                try await ClusterIntegrationTests.withKey(connection: client, suffix: keySuffix) { key in
                    let hashSlot = HashSlot(key: key)
                    let node = try await client.nodeClient(for: [hashSlot], nodeSelection: .primary)
                    try await client.set(key, value: "Testing before import")

                    try await ClusterIntegrationTests.testMigratingHashSlot(hashSlot, client: client) {
                        // key still uses nodeA
                        let value = try await client.set(key, value: "Testing during import", get: true).map { String($0) }
                        #expect(value == "Testing before import")
                    } afterMigrate: {
                        // key has been migrated to nodeB so will receive an ASK error
                        var commands: [any ValkeyCommand] = .init()
                        commands.append(SET(key, value: "After migrate", get: true))
                        commands.append(GET(key))
                        let results = try await client.execute(node: node, commands: commands)
                        #expect(try results[0].get().decode(as: String.self) == "Testing during import")
                        #expect(try results[1].get().decode(as: String.self) == "After migrate")
                    } finished: {
                        let value = try await client.set(key, value: "Testing after import", get: true).map { String($0) }
                        #expect(value == "After migrate")
                    }
                }
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testNodePipelineWithHashSlotMigrationAndTryAgain() async throws {
            var logger = Logger(label: "ValkeyCluster")
            logger.logLevel = .trace
            let firstNodeHostname = clusterFirstNodeHostname!
            let firstNodePort = clusterFirstNodePort ?? 6379
            try await ClusterIntegrationTests.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) {
                client in
                let keySuffix = "{\(UUID().uuidString)}"
                try await ClusterIntegrationTests.withKey(connection: client, suffix: keySuffix) { key in
                    try await ClusterIntegrationTests.withKey(connection: client, suffix: keySuffix) { key2 in
                        let hashSlot = HashSlot(key: key)
                        let node = try await client.nodeClient(for: [hashSlot], nodeSelection: .primary)
                        try await client.lpush(key, elements: ["testing1"])

                        try await ClusterIntegrationTests.testMigratingHashSlot(hashSlot, client: client) {
                        } duringMigrate: {
                            // LPUSH will succeed, as node is on
                            var commands: [any ValkeyCommand] = .init()
                            commands.append(LPUSH(key, elements: ["testing2"]))
                            commands.append(RPOPLPUSH(source: key, destination: key2))
                            let results = try await client.execute(node: node, commands: commands)
                            let count = try results[0].get().decode(as: Int.self)
                            #expect(count == 2)
                            let value = try results[1].get().decode(as: String.self)
                            #expect(value == "testing1")
                        }
                    }
                }
            }
        }

        @Test(arguments: [
            // verify an array of commands with no keys all go to the same node
            (commands: [LOLWUT(), LOLWUT(), LOLWUT()], selection: [[0, 1, 2]]),
            // verify an array of commands which starts with entries with no keys all go to the same node as the
            // first that does affect a key
            (commands: [any ValkeyCommand](commands: LOLWUT(), LOLWUT(), GET("foo")), selection: [[0, 1, 2]]),
            // verify that commands that affect keys in different shards get broken up. This test makes the assumption that
            // foo and baz are in different shards
            (commands: [any ValkeyCommand](commands: LOLWUT(), GET("foo"), GET("baz")), selection: [[0, 1], [2]]),
            // verify that a command has no key that follows a command that does goes to the same node
            (commands: [any ValkeyCommand](commands: GET("foo"), LOLWUT(), GET("baz"), LOLWUT()), selection: [[0, 1], [2, 3]]),
            // verify that commands that affect same node go to the same regardless of order
            (commands: [any ValkeyCommand](commands: GET("foo"), GET("baz"), GET("foo")), selection: [[0, 2], [1]]),
        ])
        @available(valkeySwift 1.0, *)
        func testNodeSelection(values: (commands: [any ValkeyCommand], selection: [[Int]])) async throws {
            var logger = Logger(label: "ValkeyCluster")
            logger.logLevel = .trace
            let firstNodeHostname = clusterFirstNodeHostname!
            let firstNodePort = clusterFirstNodePort ?? 6379
            try await ClusterIntegrationTests.withValkeyCluster(
                [(host: firstNodeHostname, port: firstNodePort)],
                logger: logger
            ) { client in
                let nodeSelections: [ValkeyNodeSelection] = [.primary, .cycleReplicas(234)]
                for selection in nodeSelections {
                    let nodesAndIndices = try await client.splitCommandsAcrossNodes(commands: values.commands, nodeSelection: selection)
                    #expect(nodesAndIndices.count == values.selection.count)
                    let sortedNodeAndIndics = nodesAndIndices.sorted { $0.commandIndices[0] < $1.commandIndices[0] }
                    var iterator = sortedNodeAndIndics.makeIterator()
                    var expectedIterator = values.selection.makeIterator()
                    while let result = iterator.next() {
                        #expect(result.commandIndices == expectedIterator.next())
                    }
                }
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testClientPipeline() async throws {
            var logger = Logger(label: "ValkeyCluster")
            logger.logLevel = .trace
            let firstNodeHostname = clusterFirstNodeHostname!
            let firstNodePort = clusterFirstNodePort ?? 6379
            try await ClusterIntegrationTests.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) {
                client in
                try await ClusterIntegrationTests.withKey(connection: client, suffix: "{foo}") { key in
                    var commands: [any ValkeyCommand] = .init()
                    commands.append(SET(key, value: "cluster pipeline test"))
                    commands.append(GET(key))
                    let results = await client.execute(commands)
                    let response = try results[1].get().decode(as: String.self)
                    #expect(response == "cluster pipeline test")
                }
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testClientPipelineMultipleNodes() async throws {
            var logger = Logger(label: "ValkeyCluster")
            logger.logLevel = .trace
            let firstNodeHostname = clusterFirstNodeHostname!
            let firstNodePort = clusterFirstNodePort ?? 6379
            try await ClusterIntegrationTests.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) {
                client in
                var commands: [any ValkeyCommand] = .init()
                for i in 0..<100 {
                    let key = ValkeyKey("Test\(i)")
                    commands.append(SET(key, value: String(i)))
                    commands.append(GET(key))
                    commands.append(DEL(keys: [key]))
                }
                let results = await client.execute(commands)
                let response = try results[1].get().decode(as: String.self)
                #expect(response == "0")
                let response2 = try results[7].get().decode(as: String.self)
                #expect(response2 == "2")
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testClientPipelineMultipleNodesReadonly() async throws {
            var logger = Logger(label: "ValkeyCluster")
            logger.logLevel = .trace
            let firstNodeHostname = clusterFirstNodeHostname!
            let firstNodePort = clusterFirstNodePort ?? 6379
            try await ClusterIntegrationTests.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) {
                client in
                let keys = (0..<100).map { ValkeyKey("Test\($0)") }
                var setCommands: [any ValkeyCommand] = .init()
                for key in keys {
                    setCommands.append(SET(key, value: key.description))
                }
                _ = await client.execute(setCommands)
                var getCommands: [any ValkeyCommand] = .init()
                for i in 0..<100 {
                    let key = ValkeyKey("Test\(i)")
                    getCommands.append(GET(key))
                }
                let results = await client.execute(getCommands)
                let response = try results[0].get().decode(as: String.self)
                #expect(response == "Test0")
                let response2 = try results[2].get().decode(as: String.self)
                #expect(response2 == "Test2")

                var delCommands: [any ValkeyCommand] = .init()
                for key in keys {
                    delCommands.append(DEL(keys: [key]))
                }
                _ = await client.execute(delCommands)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testClientPipelineMultipleNodesParameterPack() async throws {
            var logger = Logger(label: "ValkeyCluster")
            logger.logLevel = .trace
            let firstNodeHostname = clusterFirstNodeHostname!
            let firstNodePort = clusterFirstNodePort ?? 6379
            try await ClusterIntegrationTests.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) {
                client in
                let results = await client.execute(
                    SET("test1", value: "1"),
                    GET("test1"),
                    DEL(keys: ["test1"]),
                    SET("test2", value: "2"),
                    GET("test2"),
                    DEL(keys: ["test2"]),
                    SET("test3", value: "3"),
                    GET("test3"),
                    DEL(keys: ["test3"])
                )
                let response = try results.1.get().map { String($0) }
                #expect(response == "1")
                let response2 = try results.7.get().map { String($0) }
                #expect(response2 == "3")
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testClientTransaction() async throws {
            var logger = Logger(label: "ValkeyCluster")
            logger.logLevel = .trace
            let firstNodeHostname = clusterFirstNodeHostname!
            let firstNodePort = clusterFirstNodePort ?? 6379
            try await ClusterIntegrationTests.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) {
                client in
                try await ClusterIntegrationTests.withKey(connection: client, suffix: "{foo}") { key in
                    var commands: [any ValkeyCommand] = .init()
                    commands.append(SET(key, value: "cluster pipeline test"))
                    commands.append(GET(key))
                    let results = try await client.transaction(commands)
                    let response = try results[1].get().decode(as: String.self)
                    #expect(response == "cluster pipeline test")
                }
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testClientTransactionWithFailover() async throws {
            var logger = Logger(label: "ValkeyCluster")
            logger.logLevel = .trace
            let firstNodeHostname = clusterFirstNodeHostname!
            let firstNodePort = clusterFirstNodePort ?? 6379
            try await ClusterIntegrationTests.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) {
                clusterClient in
                try await ClusterIntegrationTests.withKey(connection: clusterClient) { key in
                    try await clusterClient.set(key, value: "bar")
                    let cluster = try await clusterClient.clusterShards()
                    let shard = try #require(
                        cluster.shards.first { shard in
                            let hashSlot = HashSlot(key: key)
                            return shard.slots.reduce(into: false) { $0 = ($0 || ($1.lowerBound <= hashSlot && $1.upperBound >= hashSlot)) }
                        }
                    )
                    let replica = try #require(shard.nodes.first { $0.role == .replica })
                    let port = try #require(replica.port)
                    // connect to replica and call CLUSTER FAILOVER
                    try await ClusterIntegrationTests.withValkeyClient(.hostname(replica.endpoint, port: port), logger: logger) { client in
                        try await client.clusterFailover()
                    }
                    // will receive a MOVED errors for SET, INCR and GET as the primary has moved to a replica
                    var commands: [any ValkeyCommand] = .init()
                    commands.append(SET(key, value: "100"))
                    commands.append(INCR(key))
                    commands.append(ECHO(message: "Test non moved command"))
                    commands.append(GET(key))
                    let results = try await clusterClient.transaction(commands)
                    let response2 = try results[2].get().decode(as: String.self)
                    #expect(response2 == "Test non moved command")
                    let response3 = try results[3].get().decode(as: String.self)
                    #expect(response3 == "101")
                }
            }
        }

        @available(valkeySwift 1.0, *)
        @Test
        func testClientTransactionWithHashSlotMigrationAndAskRedirection() async throws {
            var logger = Logger(label: "ValkeyCluster")
            logger.logLevel = .trace
            let firstNodeHostname = clusterFirstNodeHostname!
            let firstNodePort = clusterFirstNodePort ?? 6379
            try await ClusterIntegrationTests.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) {
                client in
                let keySuffix = "{\(UUID().uuidString)}"
                try await ClusterIntegrationTests.withKey(connection: client, suffix: keySuffix) { key in
                    let hashSlot = HashSlot(key: key)
                    try await client.set(key, value: "Testing before import")

                    try await ClusterIntegrationTests.testMigratingHashSlot(hashSlot, client: client) {
                        // key still uses nodeA
                        let value = try await client.set(key, value: "Testing during import", get: true).map { String($0) }
                        #expect(value == "Testing before import")
                    } afterMigrate: {
                        // key has been migrated to nodeB so will receive an ASK error
                        var commands: [any ValkeyCommand] = .init()
                        commands.append(SET(key, value: "After migrate", get: true))
                        commands.append(GET(key))
                        let results = try await client.transaction(commands)
                        #expect(try results[0].get().decode(as: String.self) == "Testing during import")
                        #expect(try results[1].get().decode(as: String.self) == "After migrate")
                    } finished: {
                        let value = try await client.set(key, value: "Testing after import", get: true).map { String($0) }
                        #expect(value == "After migrate")
                    }
                }
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testClientTransactionWithHashSlotMigrationAndTryAgain() async throws {
            var logger = Logger(label: "ValkeyCluster")
            logger.logLevel = .trace
            let firstNodeHostname = clusterFirstNodeHostname!
            let firstNodePort = clusterFirstNodePort ?? 6379
            try await ClusterIntegrationTests.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort)], logger: logger) {
                client in
                let keySuffix = "{\(UUID().uuidString)}"
                try await ClusterIntegrationTests.withKey(connection: client, suffix: keySuffix) { key in
                    try await ClusterIntegrationTests.withKey(connection: client, suffix: keySuffix) { key2 in
                        let hashSlot = HashSlot(key: key)
                        try await client.lpush(key, elements: ["testing1"])

                        try await ClusterIntegrationTests.testMigratingHashSlot(hashSlot, client: client) {
                        } duringMigrate: {
                            // LPUSH will succeed, as node is on
                            var commands: [any ValkeyCommand] = .init()
                            commands.append(LPUSH(key, elements: ["testing2"]))
                            commands.append(RPOPLPUSH(source: key, destination: key2))
                            let results = try await client.transaction(commands)
                            let count = try results[0].get().decode(as: Int.self)
                            #expect(count == 2)
                            let value = try results[1].get().decode(as: String.self)
                            #expect(value == "testing1")
                        }
                    }
                }
            }
        }
    }

    @available(valkeySwift 1.0, *)
    static func withKey<Value>(
        connection: some ValkeyClientProtocol,
        suffix: String = "",
        _ operation: (ValkeyKey) async throws -> Value
    ) async throws -> Value {
        let key = ValkeyKey(UUID().uuidString + suffix)
        let result: Result<Value, any Error>
        do {
            result = try await .success(operation(key))
        } catch {
            result = .failure(error)
        }
        try await connection.del(keys: [key])
        return try result.get()
    }

    @available(valkeySwift 1.0, *)
    static func withValkeyCluster<T>(
        _ nodeAddresses: [(host: String, port: Int)],
        configuration: ValkeyClusterClientConfiguration = .init(client: .init(readOnlyCommandNodeSelection: .cycleReplicas)),
        logger: Logger,
        _ body: (ValkeyClusterClient) async throws -> sending T
    ) async throws -> T {
        let client = ValkeyClusterClient(
            nodeDiscovery: ValkeyStaticNodeDiscovery(nodeAddresses.map { .init(endpoint: $0.host, port: $0.port) }),
            configuration: configuration,
            logger: logger
        )

        let result = await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await client.run()
            }

            let result: Result<T, any Error>
            do {
                result = try await .success(body(client))
            } catch {
                result = .failure(error)
            }

            group.cancelAll()
            return result
        }

        return try result.get()
    }

    @available(valkeySwift 1.0, *)
    static func withValkeyClient(
        _ address: ValkeyServerAddress,
        configuration: ValkeyClientConfiguration = .init(),
        logger: Logger,
        operation: @escaping @Sendable (ValkeyClient) async throws -> Void
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            let client = ValkeyClient(address, configuration: configuration, logger: logger)
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
}

private let clusterFirstNodeHostname: String? = ProcessInfo.processInfo.environment["VALKEY_NODE1_HOSTNAME"]
private let clusterFirstNodePort: Int? = ProcessInfo.processInfo.environment["VALKEY_NODE1_PORT"].flatMap { Int($0) }

extension ValkeyServerAddress {
    func getHostnameAndPort() -> (String, Int)? {
        switch self.value {
        case .hostname(let hostname, let port):
            (hostname, port)
        case .unixDomainSocket:
            nil
        }
    }
}
