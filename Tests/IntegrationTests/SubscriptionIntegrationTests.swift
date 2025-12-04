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
import Synchronization
import Testing
import Valkey

@testable import Valkey

@Suite("PubSub Integration Tests")
struct PubSubIntegratedTests {
    let valkeyHostname = ProcessInfo.processInfo.environment["VALKEY_HOSTNAME"] ?? "localhost"

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
                            await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "hello" }
                            await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "goodbye" }
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
                                await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "hello" }
                                await #expect(throws: Never.self) { try await iterator2.next().map { String($0.message) } == "hello" }
                                // ensure we only see the message once, by waiting for second message.
                                await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "world" }
                                await #expect(throws: Never.self) { try await iterator2.next().map { String($0.message) } == "world" }
                            }
                            cont.yield()
                            await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "!" }
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
                                await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "hello" }
                                await #expect(throws: Never.self) { try await iterator2.next().map { String($0.message) } == "goodbye" }
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
                            await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "1" }
                            await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "2" }
                            await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "3" }
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
                        try await connection.subscribe(to: "testSubscriptionAndCommandOnSameConnection") { subscription in
                            cont.finish()
                            var iterator = subscription.makeAsyncIterator()
                            await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "hello" }
                            // test we can send commands on subscription connection
                            try await withKey(connection: connection) { key in
                                try await connection.set(key, value: "Hello")
                                let response = try await connection.get(key)
                                #expect(response.map { String($0) } == "Hello")
                            }

                            await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "goodbye" }
                        }
                        #expect(await connection.isSubscriptionsEmpty())
                    }
                }
                try await valkeyClient.withConnection { connection in
                    await stream.first { _ in true }
                    try await connection.publish(channel: "testSubscriptionAndCommandOnSameConnection", message: "hello")
                    try await connection.publish(channel: "testSubscriptionAndCommandOnSameConnection", message: "goodbye")
                }
                try await group.next()
                group.cancelAll()
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testClientCaching() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        var logger = Logger(label: "Valkey")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            try await client.withConnection { connection in
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
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testKeyspaceSubscription() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            try await client.withConnection { connection in
                try await withKey(connection: connection) { key in
                    _ = try await connection.configSet(data: [.init(parameter: "notify-keyspace-events", value: "KE$")])
                    try await connection.subscribe(to: ["__keyspace@0__:\(key)"]) { subscription in
                        try await connection.set(key, value: "1")
                        try await connection.incrby(key, increment: 20)
                        var iterator = subscription.makeAsyncIterator()
                        var value = try await iterator.next()
                        #expect(value?.channel == "__keyspace@0__:\(key)")
                        #expect(value.map { String($0.message) } == "set")
                        value = try await iterator.next()
                        #expect(value?.channel == "__keyspace@0__:\(key)")
                        #expect(value.map { String($0.message) } == "incrby")
                    }
                }
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
                        await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "hello" }
                        await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "goodbye" }
                    }
                }
                try await client.withConnection { connection in
                    await stream.first { _ in true }
                    try await Task.sleep(for: .milliseconds(100))
                    _ = try await connection.publish(channel: "testSubscriptions", message: "hello")
                    _ = try await connection.publish(channel: "testSubscriptions", message: "goodbye")
                }
                try await group.waitForAll()
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testClientProtocolSubscriptions() async throws {
        @Sendable func subscribe(_ client: some ValkeyClientProtocol) async throws {
            try await client.subscribe(to: "testSubscriptions") { subscription in
                cont.finish()
                var iterator = subscription.makeAsyncIterator()
                await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "hello" }
                await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "goodbye" }
            }
        }
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        var logger = Logger(label: "Subscriptions")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await client.subscribe(to: "testSubscriptions") { subscription in
                        cont.finish()
                        var iterator = subscription.makeAsyncIterator()
                        await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "hello" }
                        await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "goodbye" }
                    }
                }
                try await client.withConnection { connection in
                    await stream.first { _ in true }
                    try await Task.sleep(for: .milliseconds(100))
                    _ = try await connection.publish(channel: "testSubscriptions", message: "hello")
                    _ = try await connection.publish(channel: "testSubscriptions", message: "goodbye")
                }
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
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await client.subscribe(to: "testSubscriptions") { subscription in
                        cont.yield()
                        var iterator = subscription.makeAsyncIterator()
                        await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "hello" }
                        await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "goodbye" }
                    }
                    client.node.subscriptionConnectionStateMachine.withLock { stateMachine in
                        #expect(stateMachine.isEmpty() == true)
                    }
                    try await client.subscribe(to: "testSubscriptions") { subscription in
                        cont.finish()
                        var iterator = subscription.makeAsyncIterator()
                        await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "hello" }
                        await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "goodbye" }
                    }
                    client.node.subscriptionConnectionStateMachine.withLock { stateMachine in
                        #expect(stateMachine.isEmpty() == true)
                    }
                }
                try await client.withConnection { connection in
                    await stream.first { _ in true }
                    try await Task.sleep(for: .milliseconds(10))
                    _ = try await connection.publish(channel: "testSubscriptions", message: "hello")
                    _ = try await connection.publish(channel: "testSubscriptions", message: "goodbye")
                    await stream.first { _ in true }
                    try await Task.sleep(for: .milliseconds(10))
                    _ = try await connection.publish(channel: "testSubscriptions", message: "hello")
                    _ = try await connection.publish(channel: "testSubscriptions", message: "goodbye")
                }
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
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            try await withThrowingTaskGroup(of: Void.self) { group in
                let count = 50
                for i in 0..<count {
                    group.addTask {
                        try await client.subscribe(to: ["sub\(i)", "sub\(i+1)"]) { subscription in
                            cont.yield()
                            var iterator = subscription.makeAsyncIterator()
                            await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "\(i)" }
                            client.logger.info("Received \(i): \(i)")
                            await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "\(i+1)" }
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
                client.node.subscriptionConnectionStateMachine.withLock { stateMachine in
                    #expect(stateMachine.isEmpty() == true)
                }
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

    @Test
    @available(valkeySwift 1.0, *)
    func testClientCachingRedirect() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            try await withThrowingTaskGroup(of: Void.self) { group in
                let (stream, cont) = AsyncStream.makeStream(of: Int.self)
                group.addTask {
                    try await client.subscribeKeyInvalidations { keys, id in
                        cont.yield(id)
                        var iterator = keys.makeAsyncIterator()
                        let key = try await iterator.next()
                        #expect(key == "foo")
                    }
                }
                let clientId = await stream.first { _ in true }
                try await client.withConnection { connection in
                    try await connection.clientTracking(status: .on, clientId: clientId)
                    _ = try await connection.get("foo")
                    try await connection.set("foo", value: "baz")

                    try await group.waitForAll()
                }
            }
        }
    }
}
