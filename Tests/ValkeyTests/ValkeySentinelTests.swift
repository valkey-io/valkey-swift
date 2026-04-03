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
        self.namedPrimaries[details.name]?.editNode(address: address) { node in
            node.flags.insert(.disconnected)
        }
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
            guard let topology = self.namedPrimaries[addressDetails.name] else { return }
            await mockConnections.addValkeyServer(.hostname(address.host, port: address.port)) { command in
                await self.processPrimaryCommands(command: command, name: addressDetails.name, topology: topology, address: address, logger: logger)
            }
        case .replica:
            guard let topology = self.namedPrimaries[addressDetails.name] else { return }
            await mockConnections.addValkeyServer(.hostname(address.host, port: address.port)) { command in
                await self.processReplicaCommands(command: command, name: addressDetails.name, topology: topology, address: address, logger: logger)
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
    func processPrimaryCommands(command: [String], name: String, topology: Topology, address: Address, logger: Logger) async -> RESP3Value? {
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
            // Keys with $address prefix are special as they return the address of the node
            if key.hasPrefix("$address") {
                return .bulkString(address.description)
            }
            self.setKey(primary: name, key: key, value: value)
            return .simpleString("OK")
        case "ROLE":
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
        default:
            return nil
        }
    }

    func processReplicaCommands(command: [String], name: String, topology: Topology, address: Address, logger: Logger) async -> RESP3Value? {
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
            return .bulkError("REDIRECT \(topology.primary.address)")
        case "ROLE":
            return .array([
                .bulkString("slave"),
                .bulkString(topology.primary.address.host),
                .number(Int64(topology.primary.address.port)),
                .bulkString("connected"),
                .number(1001),
            ])
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
        address: ValkeyServerAddress,
        mockConnections: MockServerConnections,
        configuration: ValkeySentinelClientConfiguration = .init(clientConfiguration: .init()),
        logger: Logger,
        operation: @escaping @Sendable (ValkeySentinelClient) async throws -> Void
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            let client = ValkeySentinelClient(
                primaryName: primaryName,
                nodeDiscovery: ValkeyStaticNodeDiscovery([.init(endpoint: "127.0.0.1", port: 16000)]),
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
            address: .hostname("127.0.0.1", port: 16000),
            mockConnections: mockConnections,
            logger: logger
        ) { client in
            let nodes = try await client.getNodes()
            #expect(nodes.primary == .hostname("127.0.0.1", port: 9000))
            #expect(nodes.replicas == [.hostname("127.0.0.1", port: 9001), .hostname("127.0.0.1", port: 9002)])
        }
        try await withValkeySentinelClient(
            primaryName: "TestPrimary2",
            address: .hostname("127.0.0.1", port: 16000),
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
            address: .hostname("127.0.0.1", port: 16000),
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
            address: .hostname("127.0.0.1", port: 16000),
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
            address: .hostname("127.0.0.1", port: 16000),
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
            address: .hostname("127.0.0.1", port: 16000),
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
            address: .hostname("127.0.0.1", port: 16000),
            mockConnections: mockConnections,
            logger: logger
        ) { client in
            let nodes = try await client.getNodes()
            #expect(nodes.primary == .hostname("127.0.0.1", port: 9000))
            #expect(nodes.replicas == [.hostname("127.0.0.1", port: 9002)])
        }
    }
}
