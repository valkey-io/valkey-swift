//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
import Logging
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
        try await Self.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort, tls: false)], logger: logger) { client in
            try await Self.withKey(connection: client) { key in
                try await client.set(key, value: "Hello")

                let response = try await client.get(key)
                #expect(response.map { String(buffer: $0) } == "Hello")
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
        try await Self.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort, tls: false)], logger: logger) { client in
            try await Self.withKey(connection: client) { key in
                try await client.withConnection(forKeys: [key]) { connection in
                    _ = try await connection.set(key, value: "Hello")
                    let response = try await connection.get(key)
                    #expect(response.map { String(buffer: $0) } == "Hello")
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
        try await Self.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort, tls: false)], logger: logger) { clusterClient in
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
                try await withValkeyClient(.hostname(replica.endpoint, port: port), logger: logger) { client in
                    try await client.clusterFailover()
                }
                try await clusterClient.set(key, value: "baz")
                let response = try await clusterClient.get(key)
                #expect(response.map { String(buffer: $0) } == "baz")
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
        try await Self.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort, tls: false)], logger: logger) { client in
            let keySuffix = "{\(UUID().uuidString)}"
            try await Self.withKey(connection: client, suffix: keySuffix) { key in
                let hashSlot = HashSlot(key: key)
                try await client.set(key, value: "Testing before import")

                try await testMigratingHashSlot(hashSlot, client: client) {
                    // key still uses nodeA
                    let value = try await client.set(key, value: "Testing during import", get: true).map { String(buffer: $0) }
                    #expect(value == "Testing before import")
                } afterMigrate: {
                    // key has been migrated to nodeB so will receive an ASK error
                    let value = try await client.set(key, value: "After migrate", get: true).map { String(buffer: $0) }
                    #expect(value == "Testing during import")
                } finished: {
                    let value = try await client.set(key, value: "Testing after import", get: true).map { String(buffer: $0) }
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
        try await Self.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort, tls: false)], logger: logger) { client in
            let keySuffix = "{\(UUID().uuidString)}"
            try await Self.withKey(connection: client, suffix: keySuffix) { key in
                try await Self.withKey(connection: client, suffix: keySuffix) { key2 in
                    let hashSlot = HashSlot(key: key)
                    try await client.lpush(key, elements: ["testing"])

                    try await testMigratingHashSlot(hashSlot, client: client) {
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
        try await Self.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort, tls: false)], logger: logger) { client in
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await client.subscribe(to: "testSubscriptions") { subscription in
                        cont.finish()
                        var iterator = subscription.makeAsyncIterator()
                        await #expect(throws: Never.self) { try await iterator.next().map { String(buffer: $0.message) } == "hello" }
                        await #expect(throws: Never.self) { try await iterator.next().map { String(buffer: $0.message) } == "goodbye" }
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
        try await Self.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort, tls: false)], logger: logger) { client in
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await client.subscribe(to: "testSubscriptions") { subscription in
                        cont.yield()
                        var iterator = subscription.makeAsyncIterator()
                        await #expect(throws: Never.self) { try await iterator.next().map { String(buffer: $0.message) } == "hello" }
                        await #expect(throws: Never.self) { try await iterator.next().map { String(buffer: $0.message) } == "goodbye" }
                    }
                    try await client.subscribe(to: "testSubscriptions") { subscription in
                        cont.finish()
                        var iterator = subscription.makeAsyncIterator()
                        await #expect(throws: Never.self) { try await iterator.next().map { String(buffer: $0.message) } == "hello" }
                        await #expect(throws: Never.self) { try await iterator.next().map { String(buffer: $0.message) } == "goodbye" }
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
        try await Self.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort, tls: false)], logger: logger) { client in
            try await withThrowingTaskGroup(of: Void.self) { group in
                let count = 50
                for i in 0..<count {
                    group.addTask {
                        try await client.subscribe(to: ["sub\(i)", "sub\(i+1)"]) { subscription in
                            cont.yield()
                            var iterator = subscription.makeAsyncIterator()
                            await #expect(throws: Never.self) { try await iterator.next().map { String(buffer: $0.message) } == "\(i)" }
                            client.logger.info("Received \(i): \(i)")
                            await #expect(throws: Never.self) { try await iterator.next().map { String(buffer: $0.message) } == "\(i+1)" }
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
        try await Self.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort, tls: false)], logger: logger) { client in
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
    func testMigratingHashSlot(
        _ hashSlot: HashSlot,
        client: ValkeyClusterClient,
        beforeMigrate: () async throws -> Void,
        duringMigrate: sending () async throws -> Void = {},
        afterMigrate: () async throws -> Void = {},
        finished: () async throws -> Void = {}
    ) async throws {
        let nodeAClient = try await client.nodeClient(for: [hashSlot])
        // find another shard
        var nodeBClient: ValkeyNodeClient
        repeat {
            nodeBClient = try await client.nodeClient(for: [HashSlot(rawValue: Int.random(in: 0..<16384))!])
        } while nodeAClient === nodeBClient

        guard let (hostnameA, portA) = nodeAClient.serverAddress.getHostnameAndPort() else { return }
        guard let (hostnameB, portB) = nodeBClient.serverAddress.getHostnameAndPort() else { return }
        let clientAID = try await nodeAClient.execute(CLUSTER.MYID())
        let clientBID = try await nodeBClient.execute(CLUSTER.MYID())

        let result: Result<Void, Error>
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
        _ nodeAddresses: [(host: String, port: Int, tls: Bool)],
        nodeClientConfiguration: ValkeyClientConfiguration = .init(),
        logger: Logger,
        _ body: (ValkeyClusterClient) async throws -> sending T
    ) async throws -> T {
        let client = ValkeyClusterClient(
            clientConfiguration: nodeClientConfiguration,
            nodeDiscovery: ValkeyStaticNodeDiscovery(nodeAddresses.map { .init(host: $0.host, port: $0.port) }),
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
    func withValkeyClient(
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
