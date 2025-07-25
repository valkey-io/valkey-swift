//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of valkey-swift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import Logging
import NIOCore
import Testing
import Valkey

@testable import Valkey

struct GeneratedCommands {
    let valkeyHostname = ProcessInfo.processInfo.environment["VALKEY_HOSTNAME"] ?? "localhost"
    func withKey<Value>(connection: some ValkeyConnectionProtocol, _ operation: (ValkeyKey) async throws -> Value) async throws -> Value {
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
                let response = try await connection.send(command: GET(key: key))
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
                let response = try await connection.get(key).map { String(buffer: $0) }
                #expect(response == "Hello")
                let response2 = try await connection.get("sdf65fsdf").map { String(buffer: $0) }
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
                let response = try await connection.get(key).map { String(buffer: $0) }
                #expect(response == "Hello")
                let response2 = try await connection.get("sdf65fsdf").map { String(buffer: $0) }
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
            let response = try await valkeyClient.get("sdf").map { String(buffer: $0) }
            #expect(response == "Hello")
            let response2 = try await valkeyClient.get("sdf65fsdf").map { String(buffer: $0) }
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
                #expect(response == buffer)
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
                let response = try await connection.get(key).map { String(buffer: $0) }
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
                let responses = await connection.pipeline(
                    SET(key, value: "Pipelined Hello"),
                    GET(key)
                )
                try #expect(responses.1.get().map { String(buffer: $0) } == "Pipelined Hello")
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
                let responses = await client.pipeline(
                    SET(key, value: "Pipelined Hello"),
                    GET(key)
                )
                try #expect(responses.1.get().map { String(buffer: $0) } == "Pipelined Hello")
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testTransactionSetIncrGet() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                let responses = try await connection.transaction(
                    SET(key, value: "100"),
                    INCR(key),
                    GET(key)
                )
                #expect(try responses.2.get().map { String(buffer: $0) } == "101")
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
                        await #expect(throws: ValkeyClientError(.transactionAborted)) {
                            try await connection.transaction(
                                SET("testWatch", value: "value2")
                            )
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

    @Test
    @available(valkeySwift 1.0, *)
    func testRole() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            let role = try await connection.role()
            switch role {
            case .primary:
                break
            case .replica, .sentinel:
                Issue.record()
            }
        }
    }

    @available(valkeySwift 1.0, *)
    @Test("Array with count using LMPOP")
    func testArrayWithCount() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .trace
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                try await withKey(connection: connection) { key2 in
                    try await connection.lpush(key, elements: ["a"])
                    try await connection.lpush(key2, elements: ["b"])
                    try await connection.lpush(key2, elements: ["c"])
                    try await connection.lpush(key2, elements: ["d"])
                    let rt1 = try await connection.lmpop(keys: [key, key2], where: .right)
                    let (element) = try rt1?.values.decodeElements(as: (String).self)
                    #expect(rt1?.key == key)
                    #expect(element == "a")
                    let rt2 = try await connection.lmpop(keys: [key, key2], where: .right)
                    let elements2 = try rt2?.values.decode(as: [String].self)
                    #expect(rt2?.key == key2)
                    #expect(elements2 == ["b"])
                    let rt3 = try await connection.lmpop(keys: [key, key2], where: .right, count: 2)
                    let elements3 = try rt3?.values.decode(as: [String].self)
                    #expect(rt3?.key == key2)
                    #expect(elements3 == ["c", "d"])
                }
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
                            let responses = await connection.pipeline(
                                SET(key, value: value),
                                GET(key)
                            )
                            try #expect(responses.1.get().map { String(buffer: $0) } == value)
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
            #expect(String(buffer: user) == "johnsmith")
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

    @Test
    @available(valkeySwift 1.0, *)
    func testSubscriptions() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        var logger = Logger(label: "Subscriptions")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await client.withConnection { connection in
                        try await connection.subscribe(to: "testSubscriptions") { subscription in
                            cont.finish()
                            var iterator = subscription.makeAsyncIterator()
                            await #expect(throws: Never.self) { try await iterator.next().map { String(buffer: $0.message) } == "hello" }
                            await #expect(throws: Never.self) { try await iterator.next().map { String(buffer: $0.message) } == "goodbye" }
                        }
                        #expect(await connection.isSubscriptionsEmpty())
                    }
                }
                try await client.withConnection { connection in
                    await stream.first { _ in true }
                    try await connection.publish(channel: "testSubscriptions", message: "hello")
                    try await connection.publish(channel: "testSubscriptions", message: "goodbye")
                }
                try await group.waitForAll()
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testCancelSubscription() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        var logger = Logger(label: "Subscriptions")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await client.withConnection { connection in
                        try await connection.subscribe(to: "testCancelSubscriptions") { subscription in
                            cont.finish()
                            for try await _ in subscription {
                            }
                        }
                        #expect(await connection.isSubscriptionsEmpty())
                    }
                }
                await stream.first { _ in true }
                group.cancelAll()
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testClientSubscriptions() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        var logger = Logger(label: "Subscriptions")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await client.subscribe(to: "testSubscriptions") { subscription in
                        cont.finish()
                        var iterator = subscription.makeAsyncIterator()
                        await #expect(throws: Never.self) { try await iterator.next().map { String(buffer: $0.message) } == "hello" }
                        await #expect(throws: Never.self) { try await iterator.next().map { String(buffer: $0.message) } == "goodbye" }
                    }
                }
                try await client.withConnection { connection in
                    await stream.first { _ in true }
                    _ = try await connection.publish(channel: "testSubscriptions", message: "hello")
                    _ = try await connection.publish(channel: "testSubscriptions", message: "goodbye")
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
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
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

    /// Test two different subscriptions to the same channel both receive messages and that when one ends the other still
    /// receives messages
    @Test
    @available(valkeySwift 1.0, *)
    func testDoubleSubscription() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        var logger = Logger(label: "DoubleSubscription")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await client.withConnection { connection in
                        try await connection.subscribe(to: "testDoubleSubscription") { stream in
                            var iterator = stream.makeAsyncIterator()
                            try await connection.subscribe(to: "testDoubleSubscription") { stream2 in
                                var iterator2 = stream2.makeAsyncIterator()
                                cont.yield()
                                await #expect(throws: Never.self) { try await iterator.next().map { String(buffer: $0.message) } == "hello" }
                                await #expect(throws: Never.self) { try await iterator2.next().map { String(buffer: $0.message) } == "hello" }
                                // ensure we only see the message once, by waiting for second message.
                                await #expect(throws: Never.self) { try await iterator.next().map { String(buffer: $0.message) } == "world" }
                                await #expect(throws: Never.self) { try await iterator2.next().map { String(buffer: $0.message) } == "world" }
                            }
                            cont.yield()
                            await #expect(throws: Never.self) { try await iterator.next().map { String(buffer: $0.message) } == "!" }
                        }
                        #expect(await connection.isSubscriptionsEmpty())
                    }
                }
                try await client.withConnection { connection in
                    await stream.first { _ in true }
                    try await connection.publish(channel: "testDoubleSubscription", message: "hello")
                    try await connection.publish(channel: "testDoubleSubscription", message: "world")
                    try await connection.publish(channel: "testDoubleSubscription", message: "!")
                }
                try await group.waitForAll()
            }
        }
    }

    /// Test two different subscriptions to two different channels both receive messages
    @Test
    @available(valkeySwift 1.0, *)
    func testTwoDifferentSubscriptions() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        var logger = Logger(label: "TwoDifferentSubscriptions")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await client.withConnection { connection in
                        try await connection.subscribe(to: "testTwoDifferentSubscriptions") { stream in
                            try await connection.subscribe(to: "testTwoDifferentSubscriptions2") { stream2 in
                                var iterator = stream.makeAsyncIterator()
                                var iterator2 = stream2.makeAsyncIterator()
                                cont.finish()
                                await #expect(throws: Never.self) { try await iterator.next().map { String(buffer: $0.message) } == "hello" }
                                await #expect(throws: Never.self) { try await iterator2.next().map { String(buffer: $0.message) } == "goodbye" }
                            }
                        }
                        #expect(await connection.isSubscriptionsEmpty())
                    }
                }
                try await client.withConnection { connection in
                    await stream.first { _ in true }
                    try await connection.publish(channel: "testTwoDifferentSubscriptions", message: "hello")
                    try await connection.publish(channel: "testTwoDifferentSubscriptions2", message: "goodbye")
                }
                try await group.waitForAll()
            }
        }
    }

    /// Test multiple subscriptions in one command all receive messages
    @Test
    @available(valkeySwift 1.0, *)
    func testMultipleSubscriptions() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        var logger = Logger(label: "MultipleSubscriptions")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await client.withConnection { connection in
                        try await connection.subscribe(to: "multi1", "multi2", "multi3") { stream in
                            var iterator = stream.makeAsyncIterator()
                            cont.yield()
                            await #expect(throws: Never.self) { try await iterator.next().map { String(buffer: $0.message) } == "1" }
                            await #expect(throws: Never.self) { try await iterator.next().map { String(buffer: $0.message) } == "2" }
                            await #expect(throws: Never.self) { try await iterator.next().map { String(buffer: $0.message) } == "3" }
                        }
                        #expect(await connection.isSubscriptionsEmpty())
                    }
                }
                try await client.withConnection { connection in
                    _ = await stream.first { _ in true }
                    try await connection.publish(channel: "multi1", message: "1")
                    try await connection.publish(channel: "multi2", message: "2")
                    try await connection.publish(channel: "multi3", message: "3")
                }
                try await group.waitForAll()
            }
        }
    }

    /// Test subscribing to a channel pattern works
    @Test
    @available(valkeySwift 1.0, *)
    func testPatternSubscriptions() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        var logger = Logger(label: "PatternSubscriptions")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await client.withConnection { connection in
                        try await connection.psubscribe(to: "pattern.*") { stream in
                            cont.finish()
                            var iterator = stream.makeAsyncIterator()
                            try #expect(await iterator.next() == .init(channel: "pattern.1", message: "hello"))
                            try #expect(await iterator.next() == .init(channel: "pattern.abc", message: "goodbye"))
                        }
                        #expect(await connection.isSubscriptionsEmpty())
                    }
                }
                try await client.withConnection { connection in
                    await stream.first { _ in true }
                    try await connection.publish(channel: "pattern.1", message: "hello")
                    try await connection.publish(channel: "pattern.abc", message: "goodbye")
                }
                try await group.waitForAll()
            }
        }
    }

    /// Test we can run both pattern and normal channel subscriptions on the same connection
    @Test
    @available(valkeySwift 1.0, *)
    func testPatternChannelSubscriptions() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        var logger = Logger(label: "PatternChannelSubscriptions")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await client.withConnection { connection in
                        try await connection.subscribe(to: "PatternChannelSubscriptions1") { stream in
                            try await connection.psubscribe(to: "PatternChannelSubscriptions*") { stream2 in
                                var iterator = stream.makeAsyncIterator()
                                var iterator2 = stream2.makeAsyncIterator()
                                cont.finish()
                                try #expect(
                                    await iterator.next() == .init(channel: "PatternChannelSubscriptions1", message: "hello")
                                )
                                try #expect(await iterator2.next() == .init(channel: "PatternChannelSubscriptions1", message: "hello"))
                                try #expect(await iterator2.next() == .init(channel: "PatternChannelSubscriptions2", message: "goodbye"))
                            }
                        }
                        #expect(await connection.isSubscriptionsEmpty())
                    }
                }
                try await client.withConnection { connection in
                    await stream.first { _ in true }
                    try await connection.publish(channel: "PatternChannelSubscriptions1", message: "hello")
                    try await connection.publish(channel: "PatternChannelSubscriptions2", message: "goodbye")
                }
                try await group.waitForAll()
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testShardSubscriptions() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        var logger = Logger(label: "ShardSubscriptions")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await client.withConnection { connection in
                        try await connection.ssubscribe(to: "shard") { stream in
                            cont.finish()
                            var iterator = stream.makeAsyncIterator()
                            try #expect(await iterator.next() == .init(channel: "shard", message: "hello"))
                            try #expect(await iterator.next() == .init(channel: "shard", message: "goodbye"))
                        }
                        #expect(await connection.isSubscriptionsEmpty())
                    }
                }
                try await client.withConnection { connection in
                    await stream.first { _ in true }
                    try await connection.spublish(shardchannel: "shard", message: "hello")
                    try await connection.spublish(shardchannel: "shard", message: "goodbye")
                }
                try await group.waitForAll()
            }
        }
    }

    /// Test subscriptions and sending command on same connection works
    @Test
    @available(valkeySwift 1.0, *)
    func testSubscriptionAndCommandOnSameConnection() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        var logger = Logger(label: "Subscriptions")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { valkeyClient in
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await valkeyClient.withConnection { connection in
                        try await connection.subscribe(to: "testSubscriptions") { subscription in
                            cont.finish()
                            var iterator = subscription.makeAsyncIterator()
                            await #expect(throws: Never.self) { try await iterator.next().map { String(buffer: $0.message) } == "hello" }
                            // test we can send commands on subscription connection
                            try await withKey(connection: connection) { key in
                                try await connection.set(key, value: "Hello")
                                let response = try await connection.get(key)
                                #expect(response.map { String(buffer: $0) } == "Hello")
                            }

                            await #expect(throws: Never.self) { try await iterator.next().map { String(buffer: $0.message) } == "goodbye" }
                        }
                        #expect(await connection.isSubscriptionsEmpty())
                    }
                }
                try await valkeyClient.withConnection { connection in
                    await stream.first { _ in true }
                    try await connection.publish(channel: "testSubscriptions", message: "hello")
                    try await connection.publish(channel: "testSubscriptions", message: "goodbye")
                }
                try await group.next()
                group.cancelAll()
            }
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
                        let value = try await connection.get(key).map { String(buffer: $0) }
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
    func testKeyspaceSubscription() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .trace
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                _ = try await connection.configSet(data: [.init(parameter: "notify-keyspace-events", value: "KE$")])
                try await connection.subscribe(to: ["__keyspace@0__:\(key)"]) { subscription in
                    try await connection.set(key, value: "1")
                    try await connection.incrby(key, increment: 20)
                    var iterator = subscription.makeAsyncIterator()
                    var value = try await iterator.next()
                    #expect(value?.channel == "__keyspace@0__:\(key)")
                    #expect(value.map { String(buffer: $0.message) } == "set")
                    value = try await iterator.next()
                    #expect(value?.channel == "__keyspace@0__:\(key)")
                    #expect(value.map { String(buffer: $0.message) } == "incrby")
                }
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

    @Test
    @available(valkeySwift 1.0, *)
    func testClientCaching() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        var logger = Logger(label: "Valkey")
        logger.logLevel = .trace
        try await withValkeyConnection(
            .hostname(valkeyHostname, port: 6379),
            logger: logger
        ) { connection in
            try await connection.clientTracking(status: .on)
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await connection.subscribeKeyInvalidations { keys in
                        cont.finish()
                        var iterator = keys.makeAsyncIterator()
                        let key = try await iterator.next()
                        #expect(key == "foo")
                    }
                }
                await stream.first { _ in true }
                _ = try await connection.get("foo")
                try await connection.set("foo", value: "baz")

                try await group.waitForAll()
            }
        }
    }

    @available(valkeySwift 1.0, *)
    @Test
    func testGEOPOS() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .trace
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                let count = try await connection.geoadd(
                    key,
                    data: [.init(longitude: 1.0, latitude: 53.0, member: "Edinburgh"), .init(longitude: 1.4, latitude: 53.5, member: "Glasgow")]
                )
                #expect(count == 2)
                let search = try await connection.geosearch(
                    key,
                    from: .fromlonlat(.init(longitude: 0.0, latitude: 53.0)),
                    by: .circle(.init(radius: 10000, unit: .mi)),
                    withcoord: true,
                    withdist: true,
                    withhash: true
                )
                print(search.map { $0.member })
                try print(search.map { try $0.attributes[0].decode(as: Double.self) })
                try print(search.map { try $0.attributes[1].decode(as: String.self) })
                try print(search.map { try $0.attributes[2].decode(as: GeoCoordinates.self) })
            }
        }
    }
}
