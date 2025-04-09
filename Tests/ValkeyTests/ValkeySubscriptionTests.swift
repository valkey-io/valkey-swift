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

import Logging
import NIOCore
import NIOEmbedded
import Testing

@testable import Valkey

@Suite
struct SubscriptionTests {
    @Test
    func testSubscribe() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await connection.subscribe(to: "test") { subscription in
                    let message = try await subscription.first { _ in true }
                    #expect(message == .init(channel: "test", message: "Testing!"))
                }
            }
            group.addTask {
                var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect SUBSCRIBE command
                #expect(String(buffer: outbound) == "*2\r\n$9\r\nSUBSCRIBE\r\n$4\r\ntest\r\n")
                // push subscribe
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$9\r\nsubscribe\r\n$4\r\ntest\r\n:1\r\n"))
                // push message
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$7\r\nmessage\r\n$4\r\ntest\r\n$8\r\nTesting!\r\n"))
                // expect UNSUBSCRIBE command
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(String(buffer: outbound) == "*2\r\n$11\r\nUNSUBSCRIBE\r\n$4\r\ntest\r\n")
                // push UNSUBSCRIBE message
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$11\r\nunsubscribe\r\n$4\r\ntest\r\n:0\r\n"))
            }
            try await group.waitForAll()
        }
        try await connection.channel.eventLoop.submit {
            #expect(connection.channelHandler.value.subscriptions.subscriptionIDMap.count == 0)
        }.get()
    }

    /// Test a single subscription can subscribe to multiple channels
    @Test
    func testSubscribeMultipleChannels() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await connection.subscribe(to: "test1", "test2", "test3") { subscription in
                    var iterator = subscription.makeAsyncIterator()
                    try #expect(await iterator.next() == .init(channel: "test1", message: "1"))
                    try #expect(await iterator.next() == .init(channel: "test2", message: "1"))
                    try #expect(await iterator.next() == .init(channel: "test3", message: "1"))
                }
            }
            group.addTask {
                var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect SUBSCRIBE command
                #expect(String(buffer: outbound) == "*4\r\n$9\r\nSUBSCRIBE\r\n$5\r\ntest1\r\n$5\r\ntest2\r\n$5\r\ntest3\r\n")
                // push 3 subscribes (one for each channel)
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$9\r\nsubscribe\r\n$5\r\ntest1\r\n:1\r\n"))
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$9\r\nsubscribe\r\n$5\r\ntest2\r\n:2\r\n"))
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$9\r\nsubscribe\r\n$5\r\ntest3\r\n:3\r\n"))
                // push 3 messages (one on each channel)
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$7\r\nmessage\r\n$5\r\ntest1\r\n$1\r\n1\r\n"))
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$7\r\nmessage\r\n$5\r\ntest2\r\n$1\r\n1\r\n"))
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$7\r\nmessage\r\n$5\r\ntest3\r\n$1\r\n1\r\n"))
                // expect UNSUBSCRIBE command
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(String(buffer: outbound) == "*4\r\n$11\r\nUNSUBSCRIBE\r\n$5\r\ntest1\r\n$5\r\ntest2\r\n$5\r\ntest3\r\n")
                // push UNSUBSCRIBE message
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$11\r\nunsubscribe\r\n$5\r\ntest1\r\n:0\r\n"))
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$11\r\nunsubscribe\r\n$5\r\ntest2\r\n:0\r\n"))
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$11\r\nunsubscribe\r\n$5\r\ntest3\r\n:0\r\n"))
            }
            try await group.waitForAll()
        }
        try await connection.channel.eventLoop.submit {
            #expect(connection.channelHandler.value.subscriptions.subscriptionIDMap.count == 0)
        }.get()
    }

    /// Test you can have multiple subscriptions running on one connection
    @Test
    func testMultipleSubscriptions() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await connection.subscribe(to: "test1", "test2") { subscription in
                    cont.finish()
                    var iterator = subscription.makeAsyncIterator()
                    try #expect(await iterator.next() == .init(channel: "test1", message: "1"))
                    try #expect(await iterator.next() == .init(channel: "test2", message: "2"))
                }
            }
            group.addTask {
                await stream.first { _ in true }
                try await connection.subscribe(to: "test2", "test3") { subscription in
                    var iterator = subscription.makeAsyncIterator()
                    let value = try await iterator.next()
                    #expect(value == .init(channel: "test2", message: "2"))
                    try #expect(await iterator.next() == .init(channel: "test3", message: "3"))
                }
            }
            group.addTask {
                var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect SUBSCRIBE from task 1
                #expect(String(buffer: outbound) == "*3\r\n$9\r\nSUBSCRIBE\r\n$5\r\ntest1\r\n$5\r\ntest2\r\n")
                // push 2 subscribes
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$9\r\nsubscribe\r\n$5\r\ntest1\r\n:1\r\n"))
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$9\r\nsubscribe\r\n$5\r\ntest2\r\n:2\r\n"))
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect SUBSCRIBE from task 2
                #expect(String(buffer: outbound) == "*3\r\n$9\r\nSUBSCRIBE\r\n$5\r\ntest2\r\n$5\r\ntest3\r\n")
                // push 2 subscribes
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$9\r\nsubscribe\r\n$5\r\ntest2\r\n:2\r\n"))
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$9\r\nsubscribe\r\n$5\r\ntest3\r\n:2\r\n"))

                // push 2 messages
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$7\r\nmessage\r\n$5\r\ntest1\r\n$1\r\n1\r\n"))
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$7\r\nmessage\r\n$5\r\ntest2\r\n$1\r\n2\r\n"))
                // expect UNSUBSCRIBE from task 1
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(String(buffer: outbound) == "*2\r\n$11\r\nUNSUBSCRIBE\r\n$5\r\ntest1\r\n")
                // push UNSUBSCRIBE message
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$11\r\nunsubscribe\r\n$5\r\ntest1\r\n:0\r\n"))

                // push 1 message
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$7\r\nmessage\r\n$5\r\ntest3\r\n$1\r\n3\r\n"))
                // expect UNSUBSCRIBE from task 2
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(String(buffer: outbound) == "*3\r\n$11\r\nUNSUBSCRIBE\r\n$5\r\ntest2\r\n$5\r\ntest3\r\n")
                // push unsubscribe
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$11\r\nunsubscribe\r\n$5\r\ntest2\r\n:0\r\n"))
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$11\r\nunsubscribe\r\n$5\r\ntest3\r\n:0\r\n"))
            }
            try await group.waitForAll()
        }
        try await connection.channel.eventLoop.submit {
            #expect(connection.channelHandler.value.subscriptions.subscriptionIDMap.count == 0)
        }.get()
    }

    /// Test we can unsubscribe from one subscription while the other still continues to receive messages
    @Test
    func testMultipleSubscriptionsDontAffectEachOther() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await connection.subscribe(to: "test1") { subscription in
                    var iterator = subscription.makeAsyncIterator()
                    try #expect(await iterator.next() == .init(channel: "test1", message: "1"))
                }
                cont.finish()
            }
            group.addTask {
                try await connection.subscribe(to: "test1") { subscription in
                    var iterator = subscription.makeAsyncIterator()
                    try #expect(await iterator.next() == .init(channel: "test1", message: "1"))
                    try #expect(await iterator.next() == .init(channel: "test1", message: "2"))
                }
            }
            group.addTask {
                var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect SUBSCRIBE from task 1
                #expect(String(buffer: outbound) == "*2\r\n$9\r\nSUBSCRIBE\r\n$5\r\ntest1\r\n")
                // push subscribes
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$9\r\nsubscribe\r\n$5\r\ntest1\r\n:1\r\n"))
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect SUBSCRIBE from task 2
                #expect(String(buffer: outbound) == "*2\r\n$9\r\nSUBSCRIBE\r\n$5\r\ntest1\r\n")
                // push subscribes
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$9\r\nsubscribe\r\n$5\r\ntest1\r\n:2\r\n"))

                // push message and wait and push another
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$7\r\nmessage\r\n$5\r\ntest1\r\n$1\r\n1\r\n"))
                await stream.first { _ in true }
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$7\r\nmessage\r\n$5\r\ntest1\r\n$1\r\n2\r\n"))
                // expect UNSUBSCRIBE
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(String(buffer: outbound) == "*2\r\n$11\r\nUNSUBSCRIBE\r\n$5\r\ntest1\r\n")
                // push UNSUBSCRIBE message
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$11\r\nunsubscribe\r\n$5\r\ntest1\r\n:0\r\n"))
            }
            try await group.waitForAll()
        }
        try await connection.channel.eventLoop.submit {
            #expect(connection.channelHandler.value.subscriptions.subscriptionIDMap.count == 0)
        }.get()
    }

    @Test
    func testCloseFinishesSubscriptionWithError() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await connection.subscribe(to: "test") { subscription in
                    var iterator = subscription.makeAsyncIterator()
                    let message = try await iterator.next()
                    #expect(message == .init(channel: "test", message: "Testing!"))
                    await #expect(throws: ValkeyClientError(.connectionClosed)) {
                        try await iterator.next() == nil
                    }
                }
            }
            group.addTask {
                let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect SUBSCRIBE command
                #expect(String(buffer: outbound) == "*2\r\n$9\r\nSUBSCRIBE\r\n$4\r\ntest\r\n")
                // push SUBSCRIBE channel
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$9\r\nsubscribe\r\n$4\r\ntest\r\n:1\r\n"))
                // push SUBSCRIBE message
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$7\r\nmessage\r\n$4\r\ntest\r\n$8\r\nTesting!\r\n"))
                // close
                try await channel.close()
            }
            try await group.waitForAll()
        }
        try await connection.channel.eventLoop.submit {
            #expect(connection.channelHandler.value.subscriptions.subscriptionIDMap.count == 0)
        }.get()
    }

    @Test
    func testRemoveSubscriptionOnCancellation() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await connection.subscribe(to: "test") { subscription in
                    for try await message in subscription {
                        #expect(message == .init(channel: "test", message: "Testing!"))
                    }
                }
            }
            group.addTask {
                let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect SUBSCRIBE command
                #expect(String(buffer: outbound) == "*2\r\n$9\r\nSUBSCRIBE\r\n$4\r\ntest\r\n")
                // push SUBSCRIBE channel
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$9\r\nsubscribe\r\n$4\r\ntest\r\n:1\r\n"))
                // push SUBSCRIBE message
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$7\r\nmessage\r\n$4\r\ntest\r\n$8\r\nTesting!\r\n"))
            }
            try await group.next()

            group.cancelAll()

            // add task that won't get cancelled
            try await Task {
                // expect UNSUBSCRIBE command
                let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(String(buffer: outbound) == "*2\r\n$11\r\nUNSUBSCRIBE\r\n$4\r\ntest\r\n")
                // push UNSUBSCRIBE message
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$11\r\nunsubscribe\r\n$4\r\ntest\r\n:0\r\n"))
            }.value
        }
        try await connection.channel.eventLoop.submit {
            #expect(connection.channelHandler.value.subscriptions.subscriptionIDMap.count == 0)
        }.get()
    }

    @Test
    func testPSubscribe() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await connection.psubscribe(to: "test*") { subscription in
                    var iterator = subscription.makeAsyncIterator()
                    try #expect(await iterator.next() == .init(channel: "test1", message: "1"))
                    try #expect(await iterator.next() == .init(channel: "test2", message: "2"))
                    try #expect(await iterator.next() == .init(channel: "test3", message: "3"))
                }
            }
            group.addTask {
                var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect SUBSCRIBE command
                #expect(String(buffer: outbound) == "*2\r\n$10\r\nPSUBSCRIBE\r\n$5\r\ntest*\r\n")
                // push psubscribe
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$10\r\npsubscribe\r\n$5\r\ntest*\r\n:1\r\n"))
                // push 3 messages (one on each channel)
                try await channel.writeInbound(ByteBuffer(string: ">4\r\n$8\r\npmessage\r\n$5\r\ntest*\r\n$5\r\ntest1\r\n$1\r\n1\r\n"))
                try await channel.writeInbound(ByteBuffer(string: ">4\r\n$8\r\npmessage\r\n$5\r\ntest*\r\n$5\r\ntest2\r\n$1\r\n2\r\n"))
                try await channel.writeInbound(ByteBuffer(string: ">4\r\n$8\r\npmessage\r\n$5\r\ntest*\r\n$5\r\ntest3\r\n$1\r\n3\r\n"))
                // expect PUNSUBSCRIBE command
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(String(buffer: outbound) == "*2\r\n$12\r\nPUNSUBSCRIBE\r\n$5\r\ntest*\r\n")
                // push PUNSUBSCRIBE message
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$12\r\npunsubscribe\r\n$5\r\ntest*\r\n:0\r\n"))
            }
            try await group.waitForAll()
        }
        try await connection.channel.eventLoop.submit {
            #expect(connection.channelHandler.value.subscriptions.subscriptionIDMap.count == 0)
        }.get()
    }

    @Test
    func testPSubscribeAndSubscribeOnOneChanel() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await connection.psubscribe(to: "test*") { subscription in
                    try await connection.subscribe(to: "test1") { subscription2 in
                        var iterator = subscription.makeAsyncIterator()
                        try #expect(await iterator.next() == .init(channel: "test1", message: "1"))
                        var iterator2 = subscription2.makeAsyncIterator()
                        try #expect(await iterator2.next() == .init(channel: "test1", message: "1"))
                    }
                }
            }
            group.addTask {
                var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect PSUBSCRIBE command
                #expect(String(buffer: outbound) == "*2\r\n$10\r\nPSUBSCRIBE\r\n$5\r\ntest*\r\n")
                // push psubscribe
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$10\r\npsubscribe\r\n$5\r\ntest*\r\n:1\r\n"))
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect SUBSCRIBE command
                #expect(String(buffer: outbound) == "*2\r\n$9\r\nSUBSCRIBE\r\n$5\r\ntest1\r\n")
                // push subscribe
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$9\r\nsubscribe\r\n$5\r\ntest1\r\n:1\r\n"))
                // push pmessage
                try await channel.writeInbound(ByteBuffer(string: ">4\r\n$8\r\npmessage\r\n$5\r\ntest*\r\n$5\r\ntest1\r\n$1\r\n1\r\n"))
                // push message
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$7\r\nmessage\r\n$5\r\ntest1\r\n$1\r\n1\r\n"))
                // expect UNSUBSCRIBE command
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(String(buffer: outbound) == "*2\r\n$11\r\nUNSUBSCRIBE\r\n$5\r\ntest1\r\n")
                // push unsubscribe
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$11\r\nunsubscribe\r\n$5\r\ntest1\r\n:0\r\n"))
                // expect PUNSUBSCRIBE command
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(String(buffer: outbound) == "*2\r\n$12\r\nPUNSUBSCRIBE\r\n$5\r\ntest*\r\n")
                // push punsubscribe
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$12\r\npunsubscribe\r\n$5\r\ntest*\r\n:0\r\n"))
            }
            try await group.waitForAll()
        }
        try await connection.channel.eventLoop.submit {
            #expect(connection.channelHandler.value.subscriptions.subscriptionIDMap.count == 0)
        }.get()
    }

    @Test
    func testInvalidPush() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await connection.subscribe(to: "test") { subscription in
                    var iterator = subscription.makeAsyncIterator()
                    await #expect(throws: Error.self) {
                        _ = try await iterator.next()
                    }
                }
            }
            group.addTask {
                let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect SUBSCRIBE command
                #expect(String(buffer: outbound) == "*2\r\n$9\r\nSUBSCRIBE\r\n$4\r\ntest\r\n")
                // push subscribe
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$9\r\nsubscribe\r\n$4\r\ntest\r\n:1\r\n"))
                // push message before pushing subscribe
                try await channel.writeInbound(ByteBuffer(string: ">4\r\n$7\r\nmessage\r\n$4\r\ntest\r\n$8\r\nTesting!\r\n+hello\r\n"))
            }
            try await group.waitForAll()
        }
        try await connection.channel.eventLoop.submit {
            #expect(connection.channelHandler.value.subscriptions.subscriptionIDMap.count == 0)
        }.get()
    }

    @Test
    func testSubscriptionsAndCommandsCombined() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await connection.subscribe(to: "test") { subscription in
                    var iterator = subscription.makeAsyncIterator()
                    try #expect(await iterator.next() == .init(channel: "test", message: "Testing!"))
                    let value = try await connection.get(key: "foo")
                    #expect(value == "bar")
                    try #expect(await iterator.next() == .init(channel: "test", message: "Testing2!"))
                }
            }
            group.addTask {
                var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect SUBSCRIBE command
                #expect(String(buffer: outbound) == "*2\r\n$9\r\nSUBSCRIBE\r\n$4\r\ntest\r\n")
                // push subscribe
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$9\r\nsubscribe\r\n$4\r\ntest\r\n:1\r\n"))
                // push message
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$7\r\nmessage\r\n$4\r\ntest\r\n$8\r\nTesting!\r\n"))
                // expect GET command
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(String(buffer: outbound) == "*2\r\n$3\r\nGET\r\n$3\r\nfoo\r\n")
                // write command response
                try await channel.writeInbound(ByteBuffer(string: "$3\r\nbar\r\n"))
                // push message
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$7\r\nmessage\r\n$4\r\ntest\r\n$9\r\nTesting2!\r\n"))
                // expect UNSUBSCRIBE command
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(String(buffer: outbound) == "*2\r\n$11\r\nUNSUBSCRIBE\r\n$4\r\ntest\r\n")
                // push unsubscribe
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$11\r\nunsubscribe\r\n$4\r\ntest\r\n:0\r\n"))
            }
            try await group.waitForAll()
        }
        try await connection.channel.eventLoop.submit {
            #expect(connection.channelHandler.value.subscriptions.subscriptionIDMap.count == 0)
        }.get()
    }

    @Test
    func testSubscribeError() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                await #expect(throws: ValkeyClientError(.commandError, message: "Subscription error")) {
                    try await connection.subscribe(to: "test") { subscription in
                    }
                }
            }
            group.addTask {
                let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect SUBSCRIBE command
                #expect(String(buffer: outbound) == "*2\r\n$9\r\nSUBSCRIBE\r\n$4\r\ntest\r\n")
                // return error
                try await channel.writeInbound(ByteBuffer(string: "!18\r\nSubscription error\r\n"))
            }
            try await group.waitForAll()
        }
        try await connection.channel.eventLoop.submit {
            #expect(connection.channelHandler.value.subscriptions.subscriptionIDMap.count == 0)
            #expect(connection.channelHandler.value.subscriptions.subscribeCommandStack.commands.isEmpty)
        }.get()
    }

    @Test
    func testUnsubscribeError() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                await #expect(throws: ValkeyClientError(.commandError, message: "Subscription error")) {
                    try await connection.subscribe(to: "test") { subscription in
                    }
                }
            }
            group.addTask {
                var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect SUBSCRIBE command
                #expect(String(buffer: outbound) == "*2\r\n$9\r\nSUBSCRIBE\r\n$4\r\ntest\r\n")
                // push subscribe
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$9\r\nsubscribe\r\n$4\r\ntest\r\n:1\r\n"))
                // expect UNSUBSCRIBE command
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(String(buffer: outbound) == "*2\r\n$11\r\nUNSUBSCRIBE\r\n$4\r\ntest\r\n")
                // return error
                try await channel.writeInbound(ByteBuffer(string: "!18\r\nSubscription error\r\n"))
            }
            try await group.waitForAll()
        }
        try await connection.channel.eventLoop.submit {
            #expect(connection.channelHandler.value.subscriptions.subscriptionIDMap.count == 0)
            #expect(connection.channelHandler.value.subscriptions.unsubscribeCommandStack.commands.isEmpty)
        }.get()
    }
}
