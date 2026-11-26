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
import Synchronization
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

        mutating func failover() {
            guard let replica = replicas.first else { return }
            replicas[0] = primary
            primary = replica
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

    func failover(name: String) {
        self.namedPrimaries[name]?.failover()
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
        await add(to: mockConnections)
        return mockConnections
    }

    /// Add topology to mock connections
    func add(to mockConnections: MockServerConnections) async {
        for address in self.addressMap.keys {
            await addNode(to: mockConnections, address: address, logger: mockConnections.logger)
        }
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

@Suite("Test ValkeySentinelClient using mock server array")
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
        configuration: ValkeySentinelClientConfiguration = .init(),
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
        clientConfiguration: ValkeyClientConfiguration = .init(),
        sentinelConfiguration: ValkeySentinelClientConfiguration = .init(),
        logger: Logger,
        operation: @escaping @Sendable (ValkeyClient) async throws -> Void
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            let client = ValkeyClient(
                primaryName: primaryName,
                sentinelNodeDiscovery: ValkeyStaticNodeDiscovery([address]),
                customHandler: mockConnections.connectionManagerCustomHandler,
                clientConfiguration: clientConfiguration,
                sentinelConfiguration: sentinelConfiguration,
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

    /// Wait until client returns all the replicas from the ROLE command
    @available(valkeySwift 1.0, *)
    func waitForReplicas(_ client: ValkeyClient, sourceLocation: SourceLocation = #_sourceLocation) async throws -> [ROLE.Response.Primary.Replica] {
        let role = try await client.withConnection(readOnly: false) { connection in
            try await connection.role()
        }
        let primary: ROLE.Response.Primary
        if case .primary(let value) = role {
            primary = value
        } else {
            fatalError("Expected a primary role")
        }

        var replicas = primary.replicas
        var iteration = 0
        while replicas.count > 0 {
            try await client.withConnection(readOnly: true) { connection in
                replicas.removeAll { connection.address == .hostname($0.ip, port: $0.port) }
            }
            try await Task.sleep(for: .milliseconds(10))

            iteration += 1
            if iteration > primary.replicas.count * 10 {
                Issue.record(sourceLocation: sourceLocation)
                return primary.replicas
            }
        }
        return primary.replicas
    }

    @available(valkeySwift 1.0, *)
    func verifyReplicas(_ client: ValkeyClient, replicas: [ROLE.Response.Primary.Replica], function: String = #function) async throws {
        let replicaStrings = Set<String>(replicas.map { "\($0.ip):\($0.port)" })
        // get list of replicas
        var addresses: Set<String> = []
        // run get multiple times to ensure we get both addresses. Since rotating is done
        // based on global value and tests are running in parallel
        for _ in 0..<replicas.count * 4 {
            let address = try #require(await client.get("$address").map { String($0) })
            addresses.insert(String(address))
        }
        #expect(replicaStrings == addresses)
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
    func testDisconnectedSentinel() async throws {
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
            let expectedSentinelsSet = Set([ValkeyServerAddress.hostname("127.0.0.1", port: 16000), .hostname("127.0.0.1", port: 16002)])
            let sentinels = try await client.getSentinelClientsForPrimarySelection()
            switch sentinels {
            case .all(let sentinels):
                #expect(Set(sentinels.map { $0.serverAddress }) == expectedSentinelsSet)
            case .chosen(let sentinel):
                #expect(expectedSentinelsSet.contains(sentinel.serverAddress))
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testShutdownChosenSentinel() async throws {
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
            var sentinels = try await client.getSentinelClientsForPrimarySelection()
            let nodeDescription: ValkeyNodeDescription
            switch sentinels {
            case .all:
                Issue.record()
                return
            case .chosen(let sentinel):
                nodeDescription = sentinel.serverAddress.nodeDescription
                await topology.shutdownNode(address: .init(host: nodeDescription.endpoint, port: nodeDescription.port))
                await mockConnections.shutdownServer(sentinel.serverAddress)
            }
            _ = try await client.getNodes()
            sentinels = try await client.getSentinelClientsForPrimarySelection()
            switch sentinels {
            case .all:
                Issue.record()
            case .chosen(let sentinel):
                #expect(sentinel.serverAddress.nodeDescription != nodeDescription)
            }
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

    /// Test we get a primary node from sentinel
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

    /// Test we get the replicas from sentinel, and verify the list is the same as is returned by ROLE
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
            clientConfiguration: .init(readOnlyCommandNodeSelection: .cycleReplicas),
            logger: logger
        ) { client in
            let replicas = try await self.waitForReplicas(client)
            try await self.verifyReplicas(client, replicas: replicas)
        }
    }

    /// Test topology is updated when the primary node goes down
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

    /// Test replicas after a failover
    @Test
    @available(valkeySwift 1.0, *)
    func testClientFailover() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let topology = await self.healthyThreeSentinelOnePrimaryTwoReplicas
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeyClient(
            primaryName: "TestPrimary",
            address: .init(endpoint: "127.0.0.1", port: 16000),
            mockConnections: mockConnections,
            clientConfiguration: .init(readOnlyCommandNodeSelection: .cycleReplicas),
            logger: logger
        ) { client in
            var replicas = try await self.waitForReplicas(client)
            try await self.verifyReplicas(client, replicas: replicas)
            // when sentinel performs a failover it also closes any connections to the primary
            await topology.failover(name: "TestPrimary")
            await mockConnections.closeConnections(.hostname("127.0.0.1", port: 9000))
            replicas = try await self.waitForReplicas(client)
            try await self.verifyReplicas(client, replicas: replicas)
        }
    }

    /// Test client fails on an unknown primary name, within circuitBreakerTripAfter
    @Test
    @available(valkeySwift 1.0, *)
    func testClientUnknownPrimaryName() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let topology = await self.healthyThreeSentinelOnePrimaryTwoReplicas
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeyClient(
            primaryName: "UnknownPrimary",
            address: .init(endpoint: "127.0.0.1", port: 16000),
            mockConnections: mockConnections,
            clientConfiguration: .init(connectionPool: .init(circuitBreakerTripAfter: .seconds(1))),
            logger: logger
        ) { client in
            let error = await #expect(throws: ValkeyClientError.self) {
                _ = try await client.get("$address").map { String($0) }
            }
            #expect(error?.errorCode == .connectionCreationCircuitBreakerTripped)
        }
    }

    /// Test sentinel fails on an unavailable sentinel address. (Currently failure happens within
    /// sentinel circuitBreakerTripAfter and not client circuitBreakerTripAfter)
    @Test
    @available(valkeySwift 1.0, *)
    func testClientUnavailableSentinel() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let topology = await self.healthyThreeSentinelOnePrimaryTwoReplicas
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeyClient(
            primaryName: "TestPrimary",
            address: .init(endpoint: "127.0.0.1", port: 16999),
            mockConnections: mockConnections,
            clientConfiguration: .init(connectionPool: .init(circuitBreakerTripAfter: .seconds(1))),
            sentinelConfiguration: .init(connectionPool: .init(circuitBreakerTripAfter: .seconds(1))),
            logger: logger
        ) { client in
            let error = await #expect(throws: ValkeyClientError.self) {
                _ = try await client.get("$address").map { String($0) }
            }
            #expect(error?.errorCode == .connectionCreationCircuitBreakerTripped)
        }
    }

    /// Test we get a successful connection if sentinel comes online before circuitBreakerTripAfter
    @Test
    @available(valkeySwift 1.0, *)
    func testClientSentinelAvailableBeforeCircuitTrip() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let mockConnections = MockServerConnections(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeyClient(
            primaryName: "TestPrimary",
            address: .init(endpoint: "127.0.0.1", port: 16000),
            mockConnections: mockConnections,
            clientConfiguration: .init(connectionPool: .init(circuitBreakerTripAfter: .seconds(30))),
            sentinelConfiguration: .init(connectionPool: .init(circuitBreakerTripAfter: .seconds(30))),
            logger: logger
        ) { client in
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    await #expect(throws: Never.self) {
                        _ = try await client.get("$address").map { String($0) }
                    }
                }
                group.addTask {
                    try await Task.sleep(for: .seconds(2))
                    await self.healthyThreeSentinelOnePrimaryTwoReplicas.add(to: mockConnections)
                }
                try await group.waitForAll()
            }
        }
    }

    /// Test sentinel failover works during a high load
    @Test
    @available(valkeySwift 1.0, *)
    func testClientWithHighLoad() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let topology = await self.healthyThreeSentinelOnePrimaryTwoReplicas
        let mockConnections = await topology.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeyClient(
            primaryName: "TestPrimary",
            address: .init(endpoint: "127.0.0.1", port: 16000),
            mockConnections: mockConnections,
            clientConfiguration: .init(readOnlyCommandNodeSelection: .cycleReplicas),
            logger: logger
        ) { client in
            let waiter = AsyncStream.makeStream(of: Void.self)
            try await withThrowingTaskGroup(of: Void.self) { group in
                let count = SentinelTestCounter(0)
                for i in 0..<500 {
                    group.addTask {
                        let key = ValkeyKey("key\(i)")
                        try await client.set(key, value: "\(i)")
                        let value = try await client.get(key).map { String($0) }
                        #expect(value == "\(i)")
                        // after having processed 100 task trigger a failover
                        if count.value.add(1, ordering: .relaxed).newValue == 100 {
                            waiter.continuation.yield()
                        }
                    }
                }
                await waiter.stream.first { _ in true }
                await topology.failover(name: "TestPrimary")
                await mockConnections.closeConnections(.hostname("127.0.0.1", port: 9000))
                try await group.waitForAll()
            }
        }
    }
}

// TODO: Need this class for compilation on 6.3 and earlier, remove when we no longer support 6.3
@available(valkeySwift 1.0, *)
private final class SentinelTestCounter: Sendable {
    let value: Atomic<Int>

    init(_ value: Int) {
        self.value = .init(value)
    }
}
