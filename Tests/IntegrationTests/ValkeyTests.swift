//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey open source project
//
// Copyright (c) 2025 Apple Inc. and the swift-valkey project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-valkey project authors
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
    func withKey<Value>(connection: ValkeyConnection, _ operation: (ValkeyKey) async throws -> Value) async throws -> Value {
        let key = ValkeyKey(rawValue: UUID().uuidString)
        let value: Value
        do {
            value = try await operation(key)
        } catch {
            _ = try? await connection.del(key: [key])
            throw error
        }
        _ = try await connection.del(key: [key])
        return value
    }

    func withValkeyConnection(
        _ address: ServerAddress,
        configuration: ValkeyClientConfiguration = .init(),
        logger: Logger,
        operation: @escaping @Sendable (ValkeyConnection) async throws -> Void
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            let client = ValkeyClient(address, configuration: configuration, logger: logger)
            group.addTask {
                try await client.run()
            }
            group.addTask {
                try await client.withConnection {
                    try await operation($0)
                }
            }
            try await group.next()
            group.cancelAll()
        }
    }
    @Test
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
                _ = try await connection.set(key: key, value: "Hello")
                let response = try await connection.send(command: GET(key: key))
                #expect(response == "Hello")
            }
        }
    }

    @Test
    func testSetGet() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                _ = try await connection.set(key: key, value: "Hello")
                let response = try await connection.get(key: key)?.decode(as: String.self)
                #expect(response == "Hello")
                let response2 = try await connection.get(key: "sdf65fsdf")?.decode(as: String.self)
                #expect(response2 == nil)
            }
        }
    }

    @Test
    func testBinarySetGet() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                let buffer = ByteBuffer(repeating: 12, count: 256)
                _ = try await connection.set(key: key, value: buffer)
                let response = try await connection.get(key: key)?.decode(as: ByteBuffer.self)
                #expect(response == buffer)
            }
        }
    }

    @Test
    func testUnixTime() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                _ = try await connection.set(key: key, value: "Hello", expiration: .unixTimeMilliseconds(.now + 1))
                let response = try await connection.get(key: key)?.decode(as: String.self)
                #expect(response == "Hello")
                try await Task.sleep(for: .seconds(2))
                let response2 = try await connection.get(key: key)
                #expect(response2 == nil)
            }
        }
    }

    @Test
    func testPipelinedSetGet() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                let responses = await connection.pipeline(
                    SET(key: key, value: "Pipelined Hello"),
                    GET(key: key)
                )
                try #expect(responses.1.get()?.decode(as: String.self) == "Pipelined Hello")
            }
        }
    }

    @Test
    func testSingleElementArray() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                _ = try await connection.rpush(key: key, element: ["Hello"])
                _ = try await connection.rpush(key: key, element: ["Good", "Bye"])
                let values = try await connection.lrange(key: key, start: 0, stop: -1).decode(as: [String].self)
                #expect(values == ["Hello", "Good", "Bye"])
            }
        }
    }

    @Test
    func testCommandWithMoreThan9Strings() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                let count = try await connection.rpush(key: key, element: ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"])
                #expect(count == 10)
                let values = try await connection.lrange(key: key, start: 0, stop: -1).decode(as: [String].self)
                #expect(values == ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"])
            }
        }
    }

    @Test
    func testSort() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                _ = try await connection.lpush(key: key, element: ["a"])
                _ = try await connection.lpush(key: key, element: ["c"])
                _ = try await connection.lpush(key: key, element: ["b"])
                let list = try await connection.sort(key: key, sorting: true).decode(as: [String].self)
                #expect(list == ["a", "b", "c"])
            }
        }
    }

    @Test("Array with count using LMPOP")
    func testArrayWithCount() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .trace
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                try await withKey(connection: connection) { key2 in
                    _ = try await connection.lpush(key: key, element: ["a"])
                    _ = try await connection.lpush(key: key2, element: ["b"])
                    let rt1 = try await connection.lmpop(key: [key, key2], where: .left)!.decode(as: [RESPToken].self)
                    let keyReturned1 = try ValkeyKey(fromRESP: rt1[0])
                    let values1 = try [String](fromRESP: rt1[1])
                    #expect(keyReturned1 == key)
                    #expect(values1.first == "a")
                    let rt2 = try await connection.lmpop(key: [key, key2], where: .left)!.decode(as: [RESPToken].self)
                    let keyReturned2 = try ValkeyKey(fromRESP: rt2[0])
                    let values2 = try [String](fromRESP: rt2[1])
                    #expect(keyReturned2 == key2)
                    #expect(values2.first == "b")
                }
            }
        }
    }

    @Test("Test command error is thrown")
    func testCommandError() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .trace
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                _ = try await connection.set(key: key, value: "Hello")
                await #expect(throws: ValkeyClientError.self) { _ = try await connection.rpop(key: key) }
            }
        }
    }

    @Test
    func testMultiplexing() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withThrowingTaskGroup(of: Void.self) { group in
                for _ in 0..<100 {
                    group.addTask {
                        try await withKey(connection: connection) { key in
                            _ = try await connection.set(key: key, value: key.rawValue)
                            let response = try await connection.get(key: key)?.decode(as: String.self)
                            #expect(response == key.rawValue)
                        }
                    }
                }
                try await group.waitForAll()
            }
        }
    }

    @Test
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
                                SET(key: key, value: value),
                                GET(key: key)
                            )
                            try #expect(responses.1.get()?.decode(as: String.self) == value)
                        }
                    }
                }
                try await group.waitForAll()
            }
        }
    }
    /*
        @Test
        func testClientName() async throws {
            var logger = Logger(label: "Valkey")
            logger.logLevel = .debug
            let valkeyClient = ValkeyClient(.hostname(valkeyHostname), logger: logger)
            try await valkeyClient.withConnection(name: "phileasfogg", logger: logger) { connection in
                let name = try await connection.clientGetname()
                #expect(try name?.decode() == "phileasfogg")
            }
        }*/

    @Test
    func testAuthentication() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyConnection(.hostname(valkeyHostname), logger: logger) { connection in
            _ = try await connection.aclSetuser(username: "johnsmith", rule: ["on", ">3guygsf43", "+ACL|WHOAMI"])
        }
        try await withValkeyConnection(
            .hostname(valkeyHostname),
            configuration: .init(authentication: .init(username: "johnsmith", password: "3guygsf43")),
            logger: logger
        ) { connection in
            let user = try await connection.aclWhoami()
            #expect(try user.decode() == "johnsmith")
        }
    }

    @Test
    func testSubscriptions() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        try await withThrowingTaskGroup(of: Void.self) { group in
            var logger = Logger(label: "Subscriptions")
            logger.logLevel = .trace
            group.addTask {
                try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
                    try await connection.subscribe(to: "testSubscriptions") { subscription in
                        cont.finish()
                        var iterator = subscription.makeAsyncIterator()
                        await #expect(throws: Never.self) { try await iterator.next()?.message == "hello" }
                        await #expect(throws: Never.self) { try await iterator.next()?.message == "goodbye" }
                    }
                    try await connection.channel.eventLoop.submit {
                        #expect(connection.channelHandler.value.subscriptions.isEmpty)
                    }.get()
                }
            }
            try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
                await stream.first { _ in true }
                _ = try await connection.publish(channel: "testSubscriptions", message: "hello")
                _ = try await connection.publish(channel: "testSubscriptions", message: "goodbye")
            }
            try await group.waitForAll()
        }
    }

    /// Test two different subscriptions to the same channel both receive messages and that when one ends the other still
    /// receives messages
    @Test
    func testDoubleSubscription() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        try await withThrowingTaskGroup(of: Void.self) { group in
            var logger = Logger(label: "DoubleSubscription")
            logger.logLevel = .trace
            group.addTask {
                try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
                    try await connection.subscribe(to: "testDoubleSubscription") { stream in
                        var iterator = stream.makeAsyncIterator()
                        try await connection.subscribe(to: "testDoubleSubscription") { stream2 in
                            var iterator2 = stream2.makeAsyncIterator()
                            cont.yield()
                            await #expect(throws: Never.self) { try await iterator.next()?.message == "hello" }
                            await #expect(throws: Never.self) { try await iterator2.next()?.message == "hello" }
                            // ensure we only see the message once, by waiting for second message.
                            await #expect(throws: Never.self) { try await iterator.next()?.message == "world" }
                            await #expect(throws: Never.self) { try await iterator2.next()?.message == "world" }
                        }
                        cont.yield()
                        await #expect(throws: Never.self) { try await iterator.next()?.message == "!" }
                    }
                    try await connection.channel.eventLoop.submit {
                        #expect(connection.channelHandler.value.subscriptions.isEmpty)
                    }.get()
                }
            }
            try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
                await stream.first { _ in true }
                _ = try await connection.publish(channel: "testDoubleSubscription", message: "hello")
                _ = try await connection.publish(channel: "testDoubleSubscription", message: "world")
                _ = try await connection.publish(channel: "testDoubleSubscription", message: "!")
            }
            try await group.waitForAll()
        }
    }

    /// Test two different subscriptions to two different channels both receive messages
    @Test
    func testTwoDifferentSubscriptions() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        try await withThrowingTaskGroup(of: Void.self) { group in
            var logger = Logger(label: "TwoDifferentSubscriptions")
            logger.logLevel = .trace
            group.addTask {
                try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
                    try await connection.subscribe(to: "testTwoDifferentSubscriptions") { stream in
                        try await connection.subscribe(to: "testTwoDifferentSubscriptions2") { stream2 in
                            var iterator = stream.makeAsyncIterator()
                            var iterator2 = stream2.makeAsyncIterator()
                            cont.finish()
                            await #expect(throws: Never.self) { try await iterator.next()?.message == "hello" }
                            await #expect(throws: Never.self) { try await iterator2.next()?.message == "goodbye" }
                        }
                    }
                    try await connection.channel.eventLoop.submit {
                        #expect(connection.channelHandler.value.subscriptions.isEmpty)
                    }.get()
                }
            }
            try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
                await stream.first { _ in true }
                _ = try await connection.publish(channel: "testTwoDifferentSubscriptions", message: "hello")
                _ = try await connection.publish(channel: "testTwoDifferentSubscriptions2", message: "goodbye")
            }
            try await group.waitForAll()
        }
    }

    /// Test multiple subscriptions in one command all receive messages
    @Test
    func testMultipleSubscriptions() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        try await withThrowingTaskGroup(of: Void.self) { group in
            var logger = Logger(label: "MultipleSubscriptions")
            logger.logLevel = .trace
            group.addTask {
                try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
                    try await connection.subscribe(to: "multi1", "multi2", "multi3") { stream in
                        var iterator = stream.makeAsyncIterator()
                        cont.yield()
                        await #expect(throws: Never.self) { try await iterator.next()?.message == "1" }
                        await #expect(throws: Never.self) { try await iterator.next()?.message == "2" }
                        await #expect(throws: Never.self) { try await iterator.next()?.message == "3" }
                    }
                    try await connection.channel.eventLoop.submit {
                        #expect(connection.channelHandler.value.subscriptions.isEmpty)
                    }.get()
                }
            }
            try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
                _ = await stream.first { _ in true }
                _ = try await connection.publish(channel: "multi1", message: "1")
                _ = try await connection.publish(channel: "multi2", message: "2")
                _ = try await connection.publish(channel: "multi3", message: "3")
            }
            try await group.waitForAll()
        }
    }

    /// Test subscribing to a channel pattern works
    @Test
    func testPatternSubscriptions() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        try await withThrowingTaskGroup(of: Void.self) { group in
            var logger = Logger(label: "PatternSubscriptions")
            logger.logLevel = .trace
            group.addTask {
                try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
                    try await connection.psubscribe(to: "pattern.*") { stream in
                        cont.finish()
                        var iterator = stream.makeAsyncIterator()
                        try #expect(await iterator.next() == .init(channel: "pattern.1", message: "hello"))
                        try #expect(await iterator.next() == .init(channel: "pattern.abc", message: "goodbye"))
                    }
                    try await connection.channel.eventLoop.submit {
                        #expect(connection.channelHandler.value.subscriptions.isEmpty)
                    }.get()
                }
            }
            try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
                await stream.first { _ in true }
                _ = try await connection.publish(channel: "pattern.1", message: "hello")
                _ = try await connection.publish(channel: "pattern.abc", message: "goodbye")
            }
            try await group.waitForAll()
        }
    }

    /// Test we can run both pattern and normal channel subscriptions on the same connection
    @Test
    func testPatternChannelSubscriptions() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        try await withThrowingTaskGroup(of: Void.self) { group in
            var logger = Logger(label: "PatternChannelSubscriptions")
            logger.logLevel = .trace
            group.addTask {
                try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
                    try await connection.subscribe(to: "PatternChannelSubscriptions1") { stream in
                        try await connection.psubscribe(to: "PatternChannelSubscriptions*") { stream2 in
                            var iterator = stream.makeAsyncIterator()
                            var iterator2 = stream2.makeAsyncIterator()
                            cont.finish()
                            try #expect(await iterator.next() == .init(channel: "PatternChannelSubscriptions1", message: "hello"))
                            try #expect(await iterator2.next() == .init(channel: "PatternChannelSubscriptions1", message: "hello"))
                            try #expect(await iterator2.next() == .init(channel: "PatternChannelSubscriptions2", message: "goodbye"))
                        }
                    }
                    try await connection.channel.eventLoop.submit {
                        #expect(connection.channelHandler.value.subscriptions.isEmpty)
                    }.get()
                }
            }
            try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
                await stream.first { _ in true }
                _ = try await connection.publish(channel: "PatternChannelSubscriptions1", message: "hello")
                _ = try await connection.publish(channel: "PatternChannelSubscriptions2", message: "goodbye")
            }
            try await group.waitForAll()
        }
    }

    @Test
    func testShardSubscriptions() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        try await withThrowingTaskGroup(of: Void.self) { group in
            var logger = Logger(label: "ShardSubscriptions")
            logger.logLevel = .trace
            group.addTask {
                try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
                    try await connection.ssubscribe(to: "shard") { stream in
                        cont.finish()
                        var iterator = stream.makeAsyncIterator()
                        try #expect(await iterator.next() == .init(channel: "shard", message: "hello"))
                        try #expect(await iterator.next() == .init(channel: "shard", message: "goodbye"))
                    }
                    try await connection.channel.eventLoop.submit {
                        #expect(connection.channelHandler.value.subscriptions.isEmpty)
                    }.get()
                }
            }
            try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
                await stream.first { _ in true }
                _ = try await connection.spublish(shardchannel: "shard", message: "hello")
                _ = try await connection.spublish(shardchannel: "shard", message: "goodbye")
            }
            try await group.waitForAll()
        }
    }

    /// Test subscriptions and sending command on same connection works
    @Test
    func testSubscriptionAndCommandOnSameConnection() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        try await withThrowingTaskGroup(of: Void.self) { group in
            var logger = Logger(label: "Subscriptions")
            logger.logLevel = .trace
            let valkeyClient = ValkeyClient(
                .hostname(valkeyHostname, port: 6379),
                logger: logger
            )
            group.addTask {
                try await valkeyClient.run()
            }
            group.addTask {
                try await valkeyClient.withConnection { connection in
                    try await connection.subscribe(to: "testSubscriptions") { subscription in
                        cont.finish()
                        var iterator = subscription.makeAsyncIterator()
                        await #expect(throws: Never.self) { try await iterator.next()?.message == "hello" }
                        // test we can send commands on subscription connection
                        try await withKey(connection: connection) { key in
                            _ = try await connection.set(key: key, value: "Hello")
                            let response = try await connection.get(key: key)
                            #expect(try response?.decode() == "Hello")
                        }

                        await #expect(throws: Never.self) { try await iterator.next()?.message == "goodbye" }
                    }
                    try await connection.channel.eventLoop.submit {
                        #expect(connection.channelHandler.value.subscriptions.isEmpty)
                    }.get()
                }
            }
            try await valkeyClient.withConnection { connection in
                await stream.first { _ in true }
                _ = try await connection.publish(channel: "testSubscriptions", message: "hello")
                _ = try await connection.publish(channel: "testSubscriptions", message: "goodbye")
            }
            try await group.next()
            group.cancelAll()
        }
    }

    @Test
    func testKeyspaceSubscription() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .trace
        try await withValkeyConnection(.hostname(valkeyHostname, port: 6379), logger: logger) { connection in
            try await withKey(connection: connection) { key in
                _ = try await connection.configSet(data: [.init(parameter: "notify-keyspace-events", value: "KE$")])
                try await connection.subscribe(to: ["__keyspace@0__:\(key)"]) { subscription in
                    _ = try await connection.set(key: key, value: "1")
                    _ = try await connection.incrby(key: key, increment: 20)
                    var iterator = subscription.makeAsyncIterator()
                    var value = try await iterator.next()
                    #expect(value?.channel == "__keyspace@0__:\(key)")
                    #expect(value?.message == "set")
                    value = try await iterator.next()
                    #expect(value?.channel == "__keyspace@0__:\(key)")
                    #expect(value?.message == "incrby")
                }
            }
        }
    }
}
