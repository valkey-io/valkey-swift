//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey open source project
//
// Copyright (c) 2025 the swift-valkey project authors
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
import Testing
import Valkey

@testable import Valkey

struct GeneratedCommands {
    let valkeyHostname = ProcessInfo.processInfo.environment["VALKEY_HOSTNAME"] ?? "localhost"
    func withKey<Value>(connection: ValkeyConnection, _ operation: (RESPKey) async throws -> Value) async throws -> Value {
        let key = RESPKey(rawValue: UUID().uuidString)
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

    @Test
    func testValkeyCommand() async throws {
        struct GET: RESPCommand {
            typealias Response = String?

            var key: RESPKey

            init(key: RESPKey) {
                self.key = key
            }

            func encode(into commandEncoder: inout RESPCommandEncoder) {
                commandEncoder.encodeArray("GET", key)
            }
        }
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
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
        try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
            try await withKey(connection: connection) { key in
                _ = try await connection.set(key: key, value: "Hello")
                let response = try await connection.get(key: key)
                #expect(response == "Hello")
            }
        }
    }

    @Test
    func testUnixTime() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
            try await withKey(connection: connection) { key in
                _ = try await connection.set(key: key, value: "Hello", expiration: .unixTimeMilliseconds(.now + 1))
                let response = try await connection.get(key: key)
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
        try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
            try await withKey(connection: connection) { key in
                let responses = await connection.pipeline(
                    SET(key: key, value: "Pipelined Hello"),
                    GET(key: key)
                )
                try #expect(responses.1.get() == "Pipelined Hello")
            }
        }
    }

    @Test
    func testSingleElementArray() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
            try await withKey(connection: connection) { key in
                _ = try await connection.rpush(key: key, element: ["Hello"])
                _ = try await connection.rpush(key: key, element: ["Good", "Bye"])
                let values: [String] = try await connection.lrange(key: key, start: 0, stop: -1).converting()
                #expect(values == ["Hello", "Good", "Bye"])
            }
        }
    }

    @Test
    func testCommandWithMoreThan9Strings() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
            try await withKey(connection: connection) { key in
                let count = try await connection.rpush(key: key, element: ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"])
                #expect(count == 10)
                let values: [String] = try await connection.lrange(key: key, start: 0, stop: -1).converting()
                #expect(values == ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"])
            }
        }
    }

    @Test
    func testSort() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
            try await withKey(connection: connection) { key in
                _ = try await connection.lpush(key: key, element: ["a"])
                _ = try await connection.lpush(key: key, element: ["c"])
                _ = try await connection.lpush(key: key, element: ["b"])
                let list = try await connection.sort(key: key, sorting: true).converting(to: [String].self)
                #expect(list == ["a", "b", "c"])
            }
        }
    }

    @Test("Array with count using LMPOP")
    func testArrayWithCount() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .trace
        try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
            try await withKey(connection: connection) { key in
                try await withKey(connection: connection) { key2 in
                    _ = try await connection.lpush(key: key, element: ["a"])
                    _ = try await connection.lpush(key: key2, element: ["b"])
                    let rt1: [RESPToken] = try await connection.lmpop(key: [key, key2], where: .left)!.converting()
                    let keyReturned1 = try RESPKey(from: rt1[0])
                    let values1 = try [String](from: rt1[1])
                    #expect(keyReturned1 == key)
                    #expect(values1.first == "a")
                    let rt2: [RESPToken] = try await connection.lmpop(key: [key, key2], where: .left)!.converting()
                    let keyReturned2 = try RESPKey(from: rt2[0])
                    let values2 = try [String](from: rt2[1])
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
        try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
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
        try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
            try await withThrowingTaskGroup(of: Void.self) { group in
                for _ in 0..<100 {
                    group.addTask {
                        try await withKey(connection: connection) { key in
                            _ = try await connection.set(key: key, value: key.rawValue)
                            let response = try await connection.get(key: key)
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
        try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
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
                            try #expect(responses.1.get() == value)
                        }
                    }
                }
                try await group.waitForAll()
            }
        }
    }

    /// Test subscribing to a channel works
    @Test
    func testSubscriptions() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        try await withThrowingTaskGroup(of: Void.self) { group in
            var logger = Logger(label: "Subscriptions")
            logger.logLevel = .trace
            group.addTask {
                try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
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
            try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
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
                try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
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
            try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
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
                try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
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
            try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
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
                try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
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
            try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
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
                try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
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
            try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
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
                try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
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
            try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
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
                try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
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
            try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
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
            group.addTask {
                try await ValkeyClient(
                    .hostname(valkeyHostname, port: 6379),
                    configuration: .init(respVersion: .v3),
                    logger: logger
                ).withConnection(logger: logger) { connection in
                    try await connection.subscribe(to: "testSubscriptions") { subscription in
                        cont.finish()
                        var iterator = subscription.makeAsyncIterator()
                        await #expect(throws: Never.self) { try await iterator.next()?.message == "hello" }
                        // test we can send commands on subscription connection
                        try await withKey(connection: connection) { key in
                            _ = try await connection.set(key: key, value: "Hello")
                            let response = try await connection.get(key: key)
                            #expect(response == "Hello")
                        }

                        await #expect(throws: Never.self) { try await iterator.next()?.message == "goodbye" }
                    }
                    try await connection.channel.eventLoop.submit {
                        #expect(connection.channelHandler.value.subscriptions.isEmpty)
                    }.get()
                }
            }
            try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
                await stream.first { _ in true }
                _ = try await connection.publish(channel: "testSubscriptions", message: "hello")
                _ = try await connection.publish(channel: "testSubscriptions", message: "goodbye")
            }
            try await group.waitForAll()
        }
    }

    @Test
    func testKeyspaceSubscription() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .trace
        try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
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
