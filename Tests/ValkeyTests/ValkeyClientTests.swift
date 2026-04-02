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

/// Standalone primary replica topology
actor TestStandaloneTopology {
    enum Role {
        case primary
        case replica
    }
    struct Address: Hashable, CustomStringConvertible {
        let host: String
        let port: Int

        var description: String { "\(host):\(port)" }
    }
    struct Node {
        var address: Address
    }
    var primary: Node
    var replicas: [Node]
    private(set) var addressMap: [Address: Role]
    var keyValueMap: [String: String]

    init(primary: Address, replicas: [Address]) async {
        self.primary = .init(address: primary)
        self.replicas = replicas.map { .init(address: $0) }
        self.addressMap = [:]
        self.keyValueMap = [:]
        updateAddressMap()
    }

    func updateAddressMap() {
        self.addressMap = [:]
        self.addressMap[primary.address] = .primary
        for replica in self.replicas {
            self.addressMap[replica.address] = .replica
        }
    }

    func setKey(_ key: String, value: String) {
        self.keyValueMap[key] = value
    }

    func getKey(_ key: String) -> String? {
        self.keyValueMap[key]
    }

    /// Create Mock servers for cluster
    func mock(logger: Logger) async -> MockServerConnections {
        let mockConnections = MockServerConnections(logger: logger)
        for address in self.addressMap.keys {
            await addNode(to: mockConnections, address: address, logger: logger)
        }
        return mockConnections
    }

    /// Add Valkey node to mock connections
    func addNode(to mockConnections: MockServerConnections, address: TestStandaloneTopology.Address, logger: Logger) async {
        await mockConnections.addValkeyServer(.hostname(address.host, port: address.port)) { command in
            var iterator = command.makeIterator()
            switch iterator.next() {
            case "GET":
                guard let key = iterator.next() else { return .bulkError("ERR invalid command") }
                // Keys with $address prefix are special as they return the address of the node
                if key.hasPrefix("$address") {
                    return .bulkString(address.description)
                }
                return await self.getKey(key).map { .bulkString($0) } ?? .null

            case "SET":
                guard let key = iterator.next() else { return .bulkError("ERR invalid command") }
                guard let value = iterator.next() else { return .bulkError("ERR invalid command") }
                let addressDetails = await self.addressMap[address]
                if addressDetails == .replica {
                    return await .bulkError("REDIRECT \(self.primary.address)")
                }
                // Keys with $address prefix are special as they return the address of the node
                if key.hasPrefix("$address") {
                    return .bulkString(address.description)
                }
                await self.setKey(key, value: value)
                return .simpleString("OK")
            case "ROLE":
                let addressDetails = await self.addressMap[address]
                if addressDetails == .primary {
                    return await .array([
                        .bulkString("master"),
                        .number(1001),
                        .array(
                            self.replicas.map {
                                RESP3Value.array([
                                    .bulkString($0.address.host),
                                    .bulkString("\($0.address.port)"),
                                    .bulkString("1001"),
                                ])
                            }
                        ),
                    ])
                } else {
                    return await .array([
                        .bulkString("slave"),
                        .bulkString(self.primary.address.host),
                        .number(Int64(self.primary.address.port)),
                        .bulkString("connected"),
                        .number(1001),
                    ])
                }
            default:
                return nil
            }
        }
    }

}

@Suite("Test ValkeyClient using mock server array", .serialized)
struct ValkeyClientTests {
    var healthyPrimaryWithTwoReplicas: TestStandaloneTopology {
        get async {
            await TestStandaloneTopology(
                primary: .init(host: "127.0.0.1", port: 9000),
                replicas: [
                    .init(host: "127.0.0.1", port: 9001),
                    .init(host: "127.0.0.1", port: 9002),
                ]
            )
        }
    }

    @available(valkeySwift 1.0, *)
    func withValkeyClient(
        _ address: ValkeyServerAddress,
        mockConnections: MockServerConnections,
        configuration: ValkeyClientConfiguration = .init(),
        logger: Logger,
        operation: @escaping @Sendable (ValkeyClient) async throws -> Void
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            let client = ValkeyClient(
                address,
                customHandler: mockConnections.connectionManagerCustomHandler,
                configuration: configuration,
                eventLoopGroup: mockConnections.eventLoop,
                logger: logger
            )
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

    /// Wait until client returns a connection with a different address from the primary
    @available(valkeySwift 1.0, *)
    func waitForReplicas(_ client: ValkeyClient, function: String = #function) async throws {
        let primaryAddress = try await client.withConnection(readOnly: false) { $0.address }
        while true {
            let foundReplica = try await client.withConnection(readOnly: true) { connection in
                if connection.address != primaryAddress {
                    return true
                }
                return false
            }
            if foundReplica {
                break
            }
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testClient() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let topology = await self.healthyPrimaryWithTwoReplicas
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeyClient(.hostname("127.0.0.1", port: 9000), mockConnections: mockConnections, logger: logger) { client in
            try await client.set("foo", value: "bar")
            let value = try await client.get("foo")
            #expect(value.map { String($0) } == "bar")
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testReadFromReplica() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let topology = await self.healthyPrimaryWithTwoReplicas
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()

        try await withValkeyClient(
            .hostname("127.0.0.1", port: 9000),
            mockConnections: mockConnections,
            configuration: .init(readOnlyCommandNodeSelection: .cycleReplicas),
            logger: logger
        ) { client in
            // wait for primary to get replicas
            try await self.waitForReplicas(client)
            var addresses: Set<String> = []
            var address = try #require(await client.get("$address").map { String($0) })
            addresses.insert(String(address))
            address = try #require(await client.get("$address").map { String($0) })
            addresses.insert(String(address))
            #expect(addresses == Set(["127.0.0.1:9002", "127.0.0.1:9001"]))
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testRedirectFromReplica() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let topology = await self.healthyPrimaryWithTwoReplicas
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()

        try await withValkeyClient(
            .hostname("127.0.0.1", port: 9001),
            mockConnections: mockConnections,
            configuration: .init(readOnlyCommandNodeSelection: .cycleReplicas),
            logger: logger
        ) { client in
            // wait for address to change to primary
            try await self.waitForReplicas(client)
            // wait for primary to get replicas
            try await self.waitForReplicas(client)
            let value = try await client.set("$address", value: "bar")
            #expect(value.map { String($0) } == "127.0.0.1:9000")
            let address = try #require(await client.get("$address").map { String($0) })
            #expect(Set(["127.0.0.1:9001", "127.0.0.1:9002"]).contains(String(address)))
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testRedirectError() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let topology = await self.healthyPrimaryWithTwoReplicas
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()

        try await withValkeyClient(
            .hostname("127.0.0.1", port: 9001),
            mockConnections: mockConnections,
            configuration: .init(readOnlyCommandNodeSelection: .cycleReplicas, connectingToReplica: true),
            logger: logger
        ) { client in
            let value = try await client.set("$address", value: "bar")
            #expect(value.map { String($0) } == "127.0.0.1:9000")
            // wait for primary to get replicas
            try await self.waitForReplicas(client)
            let address = try #require(await client.get("$address").map { String($0) })
            #expect(Set(["127.0.0.1:9001", "127.0.0.1:9002"]).contains(String(address)))
        }
    }

    #if compiler(>=6.2)
    @Test
    @available(valkeySwift 1.0, *)
    func testPipelineRedirectError() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let topology = await self.healthyPrimaryWithTwoReplicas
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()

        try await withValkeyClient(
            .hostname("127.0.0.1", port: 9001),
            mockConnections: mockConnections,
            configuration: .init(readOnlyCommandNodeSelection: .cycleReplicas, connectingToReplica: true),
            logger: logger
        ) { client in
            let results = await client.execute(
                SET("$address", value: "bar"),
                SET("foo", value: "bar"),
                GET("$address"),
                GET("foo"),
            )
            try #expect(results.0.get().map { String($0) } == "127.0.0.1:9000")
            // runs on primary, because we have mutating commands in pipeline
            try #expect(results.2.get().map { String($0) } == "127.0.0.1:9000")
            try #expect(results.3.get().map { String($0) } == "bar")
        }
    }
    #endif

    @Test
    @available(valkeySwift 1.0, *)
    func testPipelineCollectionRedirectError() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let topology = await self.healthyPrimaryWithTwoReplicas
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()

        try await withValkeyClient(
            .hostname("127.0.0.1", port: 9001),
            mockConnections: mockConnections,
            configuration: .init(readOnlyCommandNodeSelection: .cycleReplicas, connectingToReplica: true),
            logger: logger
        ) { client in
            let commands: [any ValkeyCommand] = [
                GET("$address"),
                SET("$address", value: "bar"),
                SET("foo", value: "bar"),
                GET("$address"),
                GET("foo"),
            ]
            let results = await client.execute(commands)
            // first GET call runs on replica we first connected to. This command is not retried
            try #expect(results[0].get().decode(as: String.self) == "127.0.0.1:9001")
            // Every command after this is retried because this command was mutating and we were connected to a replica
            try #expect(results[1].get().decode(as: String.self) == "127.0.0.1:9000")
            // runs on primary, because previous command is mutating
            try #expect(results[3].get().decode(as: String.self) == "127.0.0.1:9000")
            try #expect(results[4].get().decode(as: String.self) == "bar")
        }
    }
}
