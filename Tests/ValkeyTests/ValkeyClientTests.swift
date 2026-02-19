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

@Suite("Test ValkeyClient using mock server array")
struct ValkeyClientTests {
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

    func getStandaloneMock(logger: Logger) async -> MockServerConnections {
        let mockConnections = MockServerConnections(logger: logger)
        await mockConnections.addValkeyServer(.hostname("127.0.0.1", port: 6379)) { command in
            switch command.first {
            case "GET":
                #expect(command[1] == "foo")
                return .bulkString("primary")
            case "SET":
                #expect(command[1] == "foo")
                #expect(command[2] == "bar")
                return .simpleString("OK")
            case "ROLE":
                return .array([
                    .bulkString("master"),
                    .number(10),
                    .array([
                        .array([
                            .bulkString("127.0.0.1"),
                            .bulkString("6380"),
                            .bulkString("1"),
                        ]),
                        .array([
                            .bulkString("127.0.0.1"),
                            .bulkString("6381"),
                            .bulkString("1"),
                        ]),
                    ]),
                ])

            default:
                return nil
            }
        }
        await mockConnections.addValkeyServer(.hostname("127.0.0.1", port: 6380)) { command in
            switch command.first {
            case "GET":
                #expect(command[1] == "foo")
                return .bulkString("replica")
            case "SET":
                #expect(command[1] == "foo")
                #expect(command[2] == "bar")
                return .bulkError("REDIRECT 127.0.0.1:6379")
            case "ROLE":
                return .array([
                    .bulkString("slave"),
                    .bulkString("127.0.0.1"),
                    .number(6379),
                    .bulkString("connected"),
                    .number(1),
                ])

            default:
                return nil
            }
        }
        await mockConnections.addValkeyServer(.hostname("127.0.0.1", port: 6381)) { command in
            switch command.first {
            case "GET":
                #expect(command[1] == "foo")
                return .bulkString("replica")
            case "SET":
                #expect(command[1] == "foo")
                #expect(command[2] == "bar")
                return .bulkError("REDIRECT 127.0.0.1:6379")
            case "ROLE":
                return .array([
                    .bulkString("slave"),
                    .bulkString("127.0.0.1"),
                    .number(6379),
                    .bulkString("connected"),
                    .number(1),
                ])

            default:
                return nil
            }
        }
        return mockConnections
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testClient() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let mockConnections = await getStandaloneMock(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeyClient(.hostname("127.0.0.1"), mockConnections: mockConnections, logger: logger) { client in
            let value = try await client.get("foo")
            #expect(value.map { String($0) } == "primary")
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testReadFromReplica() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let mockConnections = await getStandaloneMock(logger: logger)
        async let _ = mockConnections.run()

        try await withValkeyClient(
            .hostname("127.0.0.1", port: 6379),
            mockConnections: mockConnections,
            configuration: .init(readOnlyCommandNodeSelection: .cycleReplicas),
            logger: logger
        ) { client in
            // wait for primary to get replicas
            try await self.waitForReplicas(client)
            let value = try await client.get("foo")
            #expect(value.map { String($0) } == "replica")
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testRedirectFromReplica() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let mockConnections = await getStandaloneMock(logger: logger)
        async let _ = mockConnections.run()

        try await withValkeyClient(
            .hostname("127.0.0.1", port: 6380),
            mockConnections: mockConnections,
            configuration: .init(readOnlyCommandNodeSelection: .cycleReplicas),
            logger: logger
        ) { client in
            // wait for address to change to primary
            try await self.waitForReplicas(client)
            // wait for primary to get replicas
            try await self.waitForReplicas(client)
            try await client.set("foo", value: "bar")
            let value = try await client.get("foo")
            #expect(value.map { String($0) } == "replica")
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testRedirectError() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let mockConnections = await getStandaloneMock(logger: logger)
        async let _ = mockConnections.run()

        try await withValkeyClient(
            .hostname("127.0.0.1", port: 6380),
            mockConnections: mockConnections,
            configuration: .init(readOnlyCommandNodeSelection: .cycleReplicas, connectingToReplica: true),
            logger: logger
        ) { client in
            try await client.set("foo", value: "bar")
            // wait for primary to get replicas
            try await self.waitForReplicas(client)
            let value = try await client.get("foo")
            #expect(value.map { String($0) } == "replica")
        }
    }
}
