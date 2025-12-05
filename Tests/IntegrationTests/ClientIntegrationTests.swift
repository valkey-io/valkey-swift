//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
import Logging
import NIOCore
import Testing
import Valkey

@testable import Valkey

@Suite("Client Integration Tests")
struct ClientIntegratedTests {
    let valkeyHostname = ProcessInfo.processInfo.environment["VALKEY_HOSTNAME"] ?? "localhost"

    @available(valkeySwift 1.0, *)
    func withKey<Value>(connection: some ValkeyClientProtocol, _ operation: (ValkeyKey) async throws -> Value) async throws -> Value {
        let key = ValkeyKey(UUID().uuidString)
        let value: Value
        do {
            value = try await operation(key)
        } catch {
            _ = try? await connection.del(keys: [key])
            throw error
        }
        _ = try await connection.del(keys: [key])
        return value
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

    @available(valkeySwift 1.0, *)
    func withValkeyConnection(
        _ address: ValkeyServerAddress,
        configuration: ValkeyClientConfiguration = .init(),
        logger: Logger,
        operation: @escaping @Sendable (ValkeyConnection) async throws -> Void
    ) async throws {
        try await withValkeyClient(address, configuration: configuration, logger: logger) { client in
            try await client.withConnection {
                try await operation($0)
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testValkeyCommand() async throws {
        struct GET: ValkeyCommand {
            typealias Response = String?
            static let name = "GET"

            var key: ValkeyKey

            init(key: ValkeyKey) {
                self.key = key
            }

            func encode(into commandEncoder: inout ValkeyCommandEncoder) {
                commandEncoder.encodeArray("GET", key)
            }
        }
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                try await connection.set(key, value: "Hello")
                let response = try await connection.execute(GET(key: key))
                #expect(response == "Hello")
            }
        }
    }

    @Test("Test ValkeyConnection.withConnection()")
    @available(valkeySwift 1.0, *)
    func testWithConnectionSetGet() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await ValkeyConnection.withConnection(address: .hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                try await connection.set(key, value: "Hello")
                let response = try await connection.get(key).map { String($0) }
                #expect(response == "Hello")
                let response2 = try await connection.get("sdf65fsdf").map { String($0) }
                #expect(response2 == nil)
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testSetGet() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                try await connection.set(key, value: "Hello")
                let response = try await connection.get(key).map { String($0) }
                #expect(response == "Hello")
                let response2 = try await connection.get("sdf65fsdf").map { String($0) }
                #expect(response2 == nil)
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testClientSetGet() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { valkeyClient in
            try await valkeyClient.set("sdf", value: "Hello")
            let response = try await valkeyClient.get("sdf").map { String($0) }
            #expect(response == "Hello")
            let response2 = try await valkeyClient.get("sdf65fsdf").map { String($0) }
            #expect(response2 == nil)
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testBinarySetGet() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                let buffer = ByteBuffer(repeating: 12, count: 256)
                try await connection.set(key, value: buffer)
                let response = try await connection.get(key)
                #expect(response?.elementsEqual(buffer.readableBytesView) == true)
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testSPOP() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                _ = try await connection.sadd(key, members: (0..<256).map { "test\($0)" })
                let response = try await connection.sscan(key, cursor: 0, count: 32)
                let response2 = try await connection.sscan(key, cursor: response.cursor, count: 32)
                print(try response.elements.decode(as: [String].self))
                print(try response2.elements.decode(as: [String].self))
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testUnixTime() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                try await connection.set(key, value: "Hello", expiration: .unixTimeMilliseconds(.now + 1))
                let response = try await connection.get(key).map { String($0) }
                #expect(response == "Hello")
                try await Task.sleep(for: .seconds(2))
                let response2 = try await connection.get(key)
                #expect(response2 == nil)
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testPipelinedSetGet() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                let responses = await connection.execute(
                    SET(key, value: "Pipelined Hello"),
                    GET(key)
                )
                try #expect(responses.1.get().map { String($0) } == "Pipelined Hello")
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testPipelinedProtocolSetGet() async throws {
        @Sendable func setGet(_ client: some ValkeyClientProtocol, key: ValkeyKey) async throws {
            var commands: [any ValkeyCommand] = []
            commands.append(SET(key, value: "Pipelined Hello"))
            commands.append(GET(key))
            let responses = await client.execute(commands)
            try #expect(responses[1].get().decode(as: String.self) == "Pipelined Hello")
        }
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                try await setGet(connection, key: key)
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testPipelinedSetGetClient() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            try await withKey(connection: client) { key in
                let responses = await client.execute(
                    SET(key, value: "Pipelined Hello"),
                    GET(key)
                )
                try #expect(responses.1.get().map { String($0) } == "Pipelined Hello")
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testAlternativePipelinedSetGet() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                var commands: [any ValkeyCommand] = []
                commands.append(SET(key, value: "Pipelined Hello"))
                commands.append(GET(key))
                let responses = await connection.execute(commands)
                let value = try responses[1].get().decode(as: String.self)
                #expect(value == "Pipelined Hello")
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testAlternativePipelinedSetGetClient() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            try await withKey(connection: client) { key in
                var commands: [any ValkeyCommand] = []
                commands.append(SET(key, value: "Pipelined Hello"))
                commands.append(GET(key))
                let responses = await client.execute(commands)
                let value = try responses[1].get().decode(as: String.self)
                #expect(value == "Pipelined Hello")
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testTransactionSetIncrGet() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            try await withKey(connection: client) { key in
                let responses = try await client.transaction(
                    SET(key, value: "100"),
                    INCR(key),
                    GET(key)
                )
                #expect(try responses.2.get().map { String($0) } == "101")
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testInvalidTransactionSetIncrGet() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            try await withKey(connection: client) { key in
                try await client.set(key, value: "100")
                let responses = try await client.transaction(
                    LPUSH(key, elements: ["Hello"]),
                    INCR(key),
                    GET(key)
                )
                let lpushError = #expect(throws: ValkeyClientError.self) {
                    _ = try responses.0.get()
                }
                #expect(lpushError?.errorCode == .commandError)
                #expect(lpushError?.message?.hasPrefix("WRONGTYPE") == true)
                let result = try responses.2.get().map { String($0) }
                #expect(result == "101")
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testInvalidTransactionExecError() async throws {
        // Invalid command that'll cause the transaction to fail
        struct INVALID: ValkeyCommand {
            static var name: String { "INVALID" }

            func encode(into commandEncoder: inout Valkey.ValkeyCommandEncoder) {
                commandEncoder.encodeArray("INVALID")
            }
        }
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            let error = await #expect(throws: ValkeyTransactionError.self) {
                try await client.transaction(
                    GET("test"),
                    INVALID()
                )
            }
            guard case .some(.transactionErrors(let results, _)) = error else {
                Issue.record("Expected a transaction error")
                return
            }
            guard case .success = results[0] else {
                Issue.record("Queuing GET should be successful")
                return
            }
            guard case .failure = results[1] else {
                Issue.record("Queuing INVALID should be unsuccessful")
                return
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testWatch() async throws {
        let logger = {
            var logger = Logger(label: "Valkey")
            logger.logLevel = .trace
            return logger
        }()
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        let (stream2, cont2) = AsyncStream.makeStream(of: Void.self)
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection2 in
                try await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask {
                        try await connection.watch(keys: ["testWatch"])
                        cont2.yield()
                        await stream.first { _ in true }
                        let error = await #expect(throws: ValkeyTransactionError.self) {
                            _ = try await connection.transaction(
                                SET("testWatch", value: "value2")
                            )
                        }
                        guard case .transactionAborted = error else {
                            Issue.record("Unexpected error")
                            return
                        }
                    }
                    group.addTask {
                        await stream2.first { _ in true }
                        try await connection2.set("testWatch", value: "value1")
                        cont.yield()
                    }
                    try await group.waitForAll()
                }
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testSingleElementArray() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                try await connection.rpush(key, elements: ["Hello"])
                try await connection.rpush(key, elements: ["Good", "Bye"])
                let values = try await connection.lrange(key, start: 0, stop: -1).decode(as: [String].self)
                #expect(values == ["Hello", "Good", "Bye"])
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testCommandWithMoreThan9Strings() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                let count = try await connection.rpush(key, elements: ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"])
                #expect(count == 10)
                let values = try await connection.lrange(key, start: 0, stop: -1).decode(as: [String].self)
                #expect(values == ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"])
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testSort() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                try await connection.lpush(key, elements: ["a"])
                try await connection.lpush(key, elements: ["c"])
                try await connection.lpush(key, elements: ["b"])
                let list = try await connection.sort(key, sorting: true).decode(as: [String].self)
                #expect(list == ["a", "b", "c"])
            }
        }
    }

    @available(valkeySwift 1.0, *)
    @Test("Test command error is thrown")
    func testCommandError() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .trace
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                try await connection.set(key, value: "Hello")
                await #expect(throws: ValkeyClientError.self) { try await connection.rpop(key) }
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testMultiplexing() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withThrowingTaskGroup(of: Void.self) { group in
                for _ in 0..<100 {
                    group.addTask {
                        try await withKey(connection: connection) { key in
                            try await connection.set(key, value: key)
                            let response = try await connection.get(key).map { ValkeyKey($0) }
                            #expect(response == key)
                        }
                    }
                }
                try await group.waitForAll()
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testMultiplexingPipelinedRequests() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withThrowingTaskGroup(of: Void.self) { group in
                try await withKey(connection: connection) { key in
                    // Add 100 requests get and setting the same key
                    for _ in 0..<100 {
                        group.addTask {
                            let value = UUID().uuidString
                            let responses = await connection.execute(
                                SET(key, value: value),
                                GET(key)
                            )
                            try #expect(responses.1.get().map { String($0) } == value)
                        }
                    }
                }
                try await group.waitForAll()
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testAuthentication() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname), logger: logger) { connection in
            try await connection.aclSetuser(username: "johnsmith", rules: ["on", ">3guygsf43", "+ACL|WHOAMI"])
        }
        try await withValkeyConnection(
            .hostname(valkeyHostname),
            configuration: .init(authentication: .init(username: "johnsmith", password: "3guygsf43")),
            logger: logger
        ) { connection in
            let user = try await connection.aclWhoami()
            #expect(String(user) == "johnsmith")
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testAuthenticationFailure() async throws {
        var logger = Logger(label: "testAuthenticationFailure")
        logger.logLevel = .trace
        try await withValkeyConnection(.hostname(valkeyHostname), logger: logger) { connection in
            try await connection.aclSetuser(username: "johnsmith", rules: ["on", ">3guygsf43", "+ACL|WHOAMI"])
        }
        await #expect(throws: ValkeyClientError(.commandError, message: "WRONGPASS invalid username-password pair or user is disabled.")) {
            _ = try await ValkeyConnection.connect(
                address: .hostname(valkeyHostname),
                connectionID: 1,
                configuration: .init(authentication: .init(username: "johnsmith", password: "3guygsf433")),
                logger: logger
            )
        }
    }

    /// Test subscriptions and sending command on same connection works
    @Test
    @available(valkeySwift 1.0, *)
    func testLoadsOfConnections() async throws {
        var logger = Logger(label: "testLoadsOfConnections")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { valkeyClient in
            try await withThrowingTaskGroup(of: Void.self) { group in
                let key = ValkeyKey("TestLoadsOfConnections")
                try await withThrowingTaskGroup(of: Void.self) { group in
                    _ = try await valkeyClient.withConnection { connection in
                        try await connection.set(key, value: "0")
                    }
                    for _ in 0..<1000 {
                        group.addTask {
                            _ = try await valkeyClient.withConnection { connection in
                                try await connection.incr(key)
                            }
                        }
                    }
                    try await group.waitForAll()
                    try await valkeyClient.withConnection { connection in
                        let value = try await connection.get(key).map { String($0) }
                        #expect(value == "1000")
                        try await connection.del(keys: [key])
                    }
                }
                group.cancelAll()
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testBlockingCommandTimeout() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .trace
        try await withValkeyConnection(
            .hostname(valkeyHostname, port: 6379),
            configuration: .init(
                commandTimeout: .milliseconds(200),
                blockingCommandTimeout: .milliseconds(500)
            ),
            logger: logger
        ) { connection in
            let time = ContinuousClock().now
            await #expect(throws: ValkeyClientError(.timeout)) {
                _ = try await connection.brpop(keys: ["testBlockingCommandTimeout"], timeout: 10000)
            }
            let took = ContinuousClock().now - time
            #expect(.milliseconds(500) <= took && took < .seconds(1))
        }
    }

    @available(valkeySwift 1.0, *)
    @Test
    func testClientInfo() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            let clients = String(try await client.clientList())
            #expect(clients.firstRange(of: "lib-name=\(valkeySwiftLibraryName)") != nil)
            #expect(clients.firstRange(of: "lib-ver=\(valkeySwiftLibraryVersion)") != nil)
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testMultipleDB() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        // Test all default enabled databases in range {0,15}
        for dbNum in 0...15 {
            let clientConfig: ValkeyClientConfiguration = .init(databaseNumber: dbNum)
            try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), configuration: clientConfig, logger: logger) { connection in
                // Verify ClientInfo contains dbNum
                let clientInfo = String(try await connection.clientInfo())
                #expect(clientInfo.contains("db=\(dbNum)"))

                // Verify via setting and getting keys on all the DBs
                let key = "key-\(dbNum)"
                let value = "value-\(dbNum)"
                try await connection.set(ValkeyKey(key), value: value)
                let response = try await connection.get(ValkeyKey(key)).map { String($0) }
                #expect(response == value)

                // Verify key belonging to other DBs don't exist in this DB
                for otherDbNum in 0...15 {
                    let otherKey = "key-\(otherDbNum)"
                    if otherDbNum == dbNum { continue }
                    let otherResponse = try await connection.get(ValkeyKey(otherKey)).map { String($0) }
                    #expect(otherResponse == nil)
                }

                let delCount = try await connection.del(keys: [ValkeyKey(key)])
                #expect(delCount == 1)
            }
        }
    }

}
