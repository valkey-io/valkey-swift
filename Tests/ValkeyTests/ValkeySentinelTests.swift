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
actor TestSentinelTopology {
    enum Role {
        case primary
        case replica
        case sentinel
    }
    struct Address: Hashable, CustomStringConvertible {
        let host: String
        let port: Int

        var description: String { "\(host):\(port)" }
    }
    struct Node {
        var flags: Set<SentinelInstance.Flag>
        let address: Address

        var respValue: RESP3Value {
            .map([
                .bulkString("ip"): .bulkString(self.address.host),
                .bulkString("port"): .bulkString(String(self.address.port)),
                .bulkString("flags"): .bulkString(self.flags.map { $0.rawValue }.joined(separator: ",")),
            ])
        }
    }
    struct Topology {
        var sentinels: [Node]
        var primary: Node
        var replicas: [Node]
        var keyValueMap: [String: String]

        mutating func editNode(address: Address, operation: (inout Node) -> Void) {
            for index in self.sentinels.indices {
                if self.sentinels[index].address == address {
                    operation(&self.sentinels[index])
                }
            }
            if self.primary.address == address {
                operation(&self.primary)
            }
            for index in self.replicas.indices {
                if self.replicas[index].address == address {
                    operation(&self.replicas[index])
                }
            }
        }

        mutating func removeNode(address: Address) {
            for index in self.sentinels.indices {
                if self.sentinels[index].address == address {
                    self.sentinels[index].flags.insert(.disconnected)
                }
            }

            if self.primary.address == address {
                if var replica = self.replicas.first {
                    replica.flags.insert(.primary)
                    replica.flags.remove(.replica)
                    self.primary = replica
                    self.replicas = Array(self.replicas.dropFirst())
                }
            }
            for index in self.replicas.indices {
                if self.replicas[index].address == address {
                    self.replicas[index].flags.insert(.disconnected)
                }
            }
        }
    }

    var namedPrimaries: [String: Topology]
    private(set) var addressMap: [Address: (role: Role, name: String, flags: Set<SentinelInstance.Flag>)]

    init(_ primaries: [String: (sentinels: [Address], primary: Address, replicas: [Address])]) async {
        self.namedPrimaries = primaries.mapValues {
            .init(
                sentinels: $0.sentinels.map { .init(flags: [.sentinel], address: $0) },
                primary: .init(flags: [.primary], address: $0.primary),
                replicas: $0.replicas.map { .init(flags: [.replica], address: $0) },
                keyValueMap: [:]
            )
        }
        self.addressMap = [:]
        self.updateAddressMap()
    }

    func updateAddressMap() {
        self.addressMap = [:]
        for (key, value) in namedPrimaries {
            for sentinel in value.sentinels {
                self.addressMap[sentinel.address] = (role: .sentinel, name: key, flags: sentinel.flags)
            }
            self.addressMap[value.primary.address] = (role: .primary, name: key, flags: value.primary.flags)
            for replica in value.replicas {
                self.addressMap[replica.address] = (role: .replica, name: key, flags: replica.flags)
            }
        }
    }

    func shutdownNode(address: Address) {
        guard let details = self.addressMap[address] else { return }
        self.namedPrimaries[details.name]?.removeNode(address: address)
        self.updateAddressMap()
    }

    func setKey(primary: String, key: String, value: String) {
        self.namedPrimaries[primary]?.keyValueMap[key] = value
    }

    func getKey(primary: String, key: String) -> String? {
        self.namedPrimaries[primary]?.keyValueMap[key]
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
    func addNode(to mockConnections: MockServerConnections, address: Address, logger: Logger) async {
        guard let addressDetails = self.addressMap[address] else { return }
        guard addressDetails.flags.intersection([.disconnected, .s_down]).isEmpty else { return }

        switch addressDetails.role {
        case .primary:
            await mockConnections.addValkeyServer(.hostname(address.host, port: address.port)) { command in
                await self.processCommands(command: command, name: addressDetails.name, address: address, logger: logger)
            }
        case .replica:
            await mockConnections.addValkeyServer(.hostname(address.host, port: address.port)) { command in
                await self.processCommands(command: command, name: addressDetails.name, address: address, logger: logger)
            }
        case .sentinel:
            await mockConnections.addValkeyServer(.hostname(address.host, port: address.port)) { command in
                await self.processSentinelCommands(command: command, address: address, logger: logger)
            }
        }
    }

    func processSentinelCommands(command: [String], address: Address, logger: Logger) async -> RESP3Value? {
        var iterator = command.makeIterator()
        switch iterator.next() {
        case "SENTINEL":
            switch iterator.next() {
            case "SENTINELS":
                guard let name = iterator.next() else { return .bulkError("ERR invalid command") }
                guard let topology = self.namedPrimaries[name] else { return .bulkError("ERR No such master with that name") }
                return .array(topology.sentinels.filter { $0.address != address }.map { $0.respValue })
            case "GET-PRIMARY-ADDR-BY-NAME":
                guard let name = iterator.next() else { return .bulkError("ERR invalid command") }
                guard let topology = self.namedPrimaries[name] else { return .null }
                return .array([.bulkString(topology.primary.address.host), .bulkString(String(topology.primary.address.port))])
            case "REPLICAS":
                guard let name = iterator.next() else { return .bulkError("ERR invalid command") }
                guard let topology = self.namedPrimaries[name] else { return .bulkError("ERR No such master with that name") }
                return .array(topology.replicas.filter { $0.address != address }.map { $0.respValue })
            default:
                return nil
            }
        default:
            return nil
        }
    }
    func processCommands(command: [String], name: String, address: Address, logger: Logger) async -> RESP3Value? {
        var iterator = command.makeIterator()
        switch iterator.next() {
        case "GET":
            guard let key = iterator.next() else { return .bulkError("ERR invalid command") }
            // Keys with $address prefix are special as they return the address of the node
            if key.hasPrefix("$address") {
                return .bulkString(address.description)
            }
            return self.getKey(primary: name, key: key).map { .bulkString($0) } ?? .null

        case "SET":
            guard let key = iterator.next() else { return .bulkError("ERR invalid command") }
            guard let value = iterator.next() else { return .bulkError("ERR invalid command") }
            if let primaryAddress = self.namedPrimaries[name]?.primary.address, primaryAddress != address {
                return .bulkError("REDIRECT \(primaryAddress)")
            }
            // Keys with $address prefix are special as they return the address of the node
            if key.hasPrefix("$address") {
                return .bulkString(address.description)
            }
            self.setKey(primary: name, key: key, value: value)
            return .simpleString("OK")
        case "ROLE":
            guard let topology = self.namedPrimaries[name] else {
                return .bulkError("ERR internal error")
            }
            if topology.primary.address == address {
                return .array([
                    .bulkString("master"),
                    .number(1001),
                    .array(
                        topology.replicas.map {
                            RESP3Value.array([
                                .bulkString($0.address.host),
                                .bulkString("\($0.address.port)"),
                                .bulkString("1001"),
                            ])
                        }
                    ),
                ])
            } else {
                return .array([
                    .bulkString("slave"),
                    .bulkString(topology.primary.address.host),
                    .number(Int64(topology.primary.address.port)),
                    .bulkString("connected"),
                    .number(1001),
                ])
            }
        default:
            return nil
        }
    }
}

@Suite("Test ValkeySentinelClient using mock server array", .serialized)
struct ValkeySentinelTests {
    var healthyThreeSentinelOnePrimaryTwoReplicas: TestSentinelTopology {
        get async {
            await .init(
                [
                    "TestPrimary": (
                        sentinels: [
                            .init(host: "127.0.0.1", port: 16000),
                            .init(host: "127.0.0.1", port: 16001),
                            .init(host: "127.0.0.1", port: 16002),
                        ],
                        primary: .init(host: "127.0.0.1", port: 9000),
                        replicas: [.init(host: "127.0.0.1", port: 9001), .init(host: "127.0.0.1", port: 9002)]
                    ),
                    "TestPrimary2": (
                        sentinels: [
                            .init(host: "127.0.0.1", port: 16010),
                            .init(host: "127.0.0.1", port: 16011),
                            .init(host: "127.0.0.1", port: 16012),
                        ],
                        primary: .init(host: "127.0.0.1", port: 9100),
                        replicas: [.init(host: "127.0.0.1", port: 9101), .init(host: "127.0.0.1", port: 9102)]
                    ),
                ]
            )
        }
    }

    @available(valkeySwift 1.0, *)
    func withValkeySentinelClient(
        primaryName: String,
        address: ValkeyStaticNodeDiscovery.NodeDescription,
        mockConnections: MockServerConnections,
        configuration: ValkeySentinelClientConfiguration = .init(clientConfiguration: .init()),
        logger: Logger,
        operation: @escaping @Sendable (ValkeySentinelClient) async throws -> Void
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            let client = ValkeySentinelClient(
                primaryName: primaryName,
                nodeDiscovery: ValkeyStaticNodeDiscovery([address]),
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

    @available(valkeySwift 1.0, *)
    func withValkeyClient(
        primaryName: String,
        address: ValkeyStaticNodeDiscovery.NodeDescription,
        mockConnections: MockServerConnections,
        configuration: ValkeyClientConfiguration = .init(),
        logger: Logger,
        operation: @escaping @Sendable (ValkeyClient) async throws -> Void
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            let client = ValkeyClient(
                primaryName: primaryName,
                sentinelNodeDiscovery: ValkeyStaticNodeDiscovery([address]),
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

    @Test
    @available(valkeySwift 1.0, *)
    func testGetNodes() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let topology = await self.healthyThreeSentinelOnePrimaryTwoReplicas
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeySentinelClient(
            primaryName: "TestPrimary",
            address: .init(endpoint: "127.0.0.1", port: 16000),
            mockConnections: mockConnections,
            logger: logger
        ) { client in
            let nodes = try await client.getNodes()
            #expect(nodes.primary == .hostname("127.0.0.1", port: 9000))
            #expect(nodes.replicas == [.hostname("127.0.0.1", port: 9001), .hostname("127.0.0.1", port: 9002)])
        }
        try await withValkeySentinelClient(
            primaryName: "TestPrimary2",
            address: .init(endpoint: "127.0.0.1", port: 16000),
            mockConnections: mockConnections,
            logger: logger
        ) { client in
            let nodes = try await client.getNodes()
            #expect(nodes.primary == .hostname("127.0.0.1", port: 9100))
            #expect(nodes.replicas == [.hostname("127.0.0.1", port: 9101), .hostname("127.0.0.1", port: 9102)])
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testGetNodesInvalidName() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let topology = await self.healthyThreeSentinelOnePrimaryTwoReplicas
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeySentinelClient(
            primaryName: "UnknownPrimary",
            address: .init(endpoint: "127.0.0.1", port: 16000),
            mockConnections: mockConnections,
            logger: logger
        ) { client in
            await #expect(throws: ValkeySentinelError.sentinelUnknownPrimary) {
                _ = try await client.getNodes()
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testTwoSentinels() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let topology = await TestSentinelTopology([
            "TwoSentinels": (
                sentinels: [.init(host: "127.0.0.1", port: 16000), .init(host: "127.0.0.1", port: 16001)],
                primary: .init(host: "127.0.0.1", port: 9000),
                replicas: []
            )
        ])
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeySentinelClient(
            primaryName: "TwoSentinels",
            address: .init(endpoint: "127.0.0.1", port: 16000),
            mockConnections: mockConnections,
            logger: logger
        ) { client in
            let nodes = try await client.getNodes()
            #expect(nodes.primary == .hostname("127.0.0.1", port: 9000))
            #expect(nodes.replicas == [])
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testOneSentinel() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let topology = await TestSentinelTopology([
            "OneSentinel": (
                sentinels: [.init(host: "127.0.0.1", port: 16000)],
                primary: .init(host: "127.0.0.1", port: 9000),
                replicas: []
            )
        ])
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeySentinelClient(
            primaryName: "OneSentinel",
            address: .init(endpoint: "127.0.0.1", port: 16000),
            mockConnections: mockConnections,
            logger: logger
        ) { client in
            let nodes = try await client.getNodes()
            #expect(nodes.primary == .hostname("127.0.0.1", port: 9000))
            #expect(nodes.replicas == [])
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testShutdownSentinel() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let topology = await self.healthyThreeSentinelOnePrimaryTwoReplicas
        await topology.shutdownNode(address: .init(host: "127.0.0.1", port: 16001))
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeySentinelClient(
            primaryName: "TestPrimary",
            address: .init(endpoint: "127.0.0.1", port: 16000),
            mockConnections: mockConnections,
            logger: logger
        ) { client in
            let nodes = try await client.getNodes()
            #expect(nodes.primary == .hostname("127.0.0.1", port: 9000))
            #expect(nodes.replicas == [.hostname("127.0.0.1", port: 9001), .hostname("127.0.0.1", port: 9002)])
            let sentinels = try await client.getSentinelClients()
            #expect(Set(sentinels.map { $0.serverAddress }) == Set([.hostname("127.0.0.1", port: 16000), .hostname("127.0.0.1", port: 16002)]))
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testShutdownReplica() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let topology = await self.healthyThreeSentinelOnePrimaryTwoReplicas
        await topology.shutdownNode(address: .init(host: "127.0.0.1", port: 9001))
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeySentinelClient(
            primaryName: "TestPrimary",
            address: .init(endpoint: "127.0.0.1", port: 16000),
            mockConnections: mockConnections,
            logger: logger
        ) { client in
            let nodes = try await client.getNodes()
            #expect(nodes.primary == .hostname("127.0.0.1", port: 9000))
            #expect(nodes.replicas == [.hostname("127.0.0.1", port: 9002)])
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testClientGetPrimary() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let topology = await self.healthyThreeSentinelOnePrimaryTwoReplicas
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeyClient(
            primaryName: "TestPrimary",
            address: .init(endpoint: "127.0.0.1", port: 16000),
            mockConnections: mockConnections,
            logger: logger
        ) { client in
            try await client.set("key", value: "value")
            let value = try await client.get("key").map { String($0) }
            #expect(value == "value")
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testClientGetReplicas() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let topology = await self.healthyThreeSentinelOnePrimaryTwoReplicas
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeyClient(
            primaryName: "TestPrimary",
            address: .init(endpoint: "127.0.0.1", port: 16000),
            mockConnections: mockConnections,
            configuration: .init(readOnlyCommandNodeSelection: .cycleReplicas),
            logger: logger
        ) { client in
            let role = try await client.role()
            let replicas: Set<String>
            if case .primary(let primary) = role {
                replicas = .init(primary.replicas.map { "\($0.ip):\($0.port)" })
            } else {
                Issue.record("Expected a primary role")
                return
            }
            try await client.set("key", value: "value")
            // get list of replicas
            var addresses: Set<String> = []
            // run get multiple times to ensure we get both addresses. Since rotating is done
            // based on global value and tests are running in parallel
            for _ in 0..<8 {
                let address = try #require(await client.get("$address").map { String($0) })
                addresses.insert(String(address))
            }
            #expect(replicas == addresses)
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testClientRefresh() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let topology = await self.healthyThreeSentinelOnePrimaryTwoReplicas
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeyClient(
            primaryName: "TestPrimary",
            address: .init(endpoint: "127.0.0.1", port: 16000),
            mockConnections: mockConnections,
            configuration: .init(connectionPool: .init(circuitBreakerTripAfter: .seconds(1))),
            logger: logger
        ) { client in
            var value = try await client.get("$address").map { String($0) }
            #expect(value == "127.0.0.1:9000")
            await topology.shutdownNode(address: .init(host: "127.0.0.1", port: 9000))
            await mockConnections.shutdownServer(.hostname("127.0.0.1", port: 9000))
            value = try await client.get("$address").map { String($0) }
            #expect(value == "127.0.0.1:9001")
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testClientRefreshWithPipeline() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let topology = await self.healthyThreeSentinelOnePrimaryTwoReplicas
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeyClient(
            primaryName: "TestPrimary",
            address: .init(endpoint: "127.0.0.1", port: 16000),
            mockConnections: mockConnections,
            configuration: .init(connectionPool: .init(circuitBreakerTripAfter: .seconds(1))),
            logger: logger
        ) { client in
            let value = try await client.get("$address").map { String($0) }
            #expect(value == "127.0.0.1:9000")
            await topology.shutdownNode(address: .init(host: "127.0.0.1", port: 9000))
            await mockConnections.shutdownServer(.hostname("127.0.0.1", port: 9000))
            let values = await client.execute(
                SET("test", value: "This"),
                GET("$address")
            )
            try #expect(values.1.get().map { String($0) } == "127.0.0.1:9001")
        }
    }
}
