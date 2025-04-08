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
                // push SUBSCRIBE channel
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$9\r\nsubscribe\r\n$4\r\ntest\r\n:1\r\n"))
                // push SUBSCRIBE message
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$7\r\nmessage\r\n$4\r\ntest\r\n$8\r\nTesting!\r\n"))
                // expect UNSUBSCRIBE command
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(String(buffer: outbound) == "*2\r\n$11\r\nUNSUBSCRIBE\r\n$4\r\ntest\r\n")
                // push UNSUBSCRIBE message
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$11\r\nunsubscribe\r\n$4\r\ntest\r\n:0\r\n"))
            }
            try await group.waitForAll()
        }
    }

    @Test(.disabled("Need to fix issue with unsubscribing not returning a value when there is no subscription"))
    func testUnsubscribe() async throws {
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
                    _ = try await connection.unsubscribe(channel: ["test"])
                    #expect(try await iterator.next() == nil)
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
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect UNSUBSCRIBE command
                #expect(String(buffer: outbound) == "*2\r\n$11\r\nUNSUBSCRIBE\r\n$4\r\ntest\r\n")
                // push unsubscribe
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$11\r\nunsubscribe\r\n$4\r\ntest\r\n:0\r\n"))
                // push message
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$7\r\nmessage\r\n$4\r\ntest\r\n$8\r\nTesting!\r\n"))
                // expect UNSUBSCRIBE command
                #expect(String(buffer: outbound) == "*2\r\n$11\r\nUNSUBSCRIBE\r\n$4\r\ntest\r\n")
                // push UNSUBSCRIBE message
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$11\r\nunsubscribe\r\n$4\r\ntest\r\n:0\r\n"))
            }
            try await group.waitForAll()
        }
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
    }

    /// Test when unsubscribing from one channel, that you will still receive messages from other channels you are
    /// still subscribed to
    @Test
    func testUnsubscribeFromOneChannel() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await connection.subscribe(to: "test1", "test2", "test3") { subscription in
                    _ = try await connection.unsubscribe(channel: ["test2"])
                    var iterator = subscription.makeAsyncIterator()
                    #expect(try await iterator.next() == .init(channel: "test1", message: "1"))
                    #expect(try await iterator.next() == .init(channel: "test3", message: "3"))
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
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect UNSUBSCRIBE command
                #expect(String(buffer: outbound) == "*2\r\n$11\r\nUNSUBSCRIBE\r\n$5\r\ntest2\r\n")
                // push unsubscribe
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$11\r\nunsubscribe\r\n$5\r\ntest2\r\n:0\r\n"))
                // push 3 messages
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$7\r\nmessage\r\n$5\r\ntest1\r\n$1\r\n1\r\n"))
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$7\r\nmessage\r\n$5\r\ntest2\r\n$1\r\n2\r\n"))
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$7\r\nmessage\r\n$5\r\ntest3\r\n$1\r\n3\r\n"))
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
                    try #expect(await iterator.next() == .init(channel: "test2", message: "2"))
                    try #expect(await iterator.next() == .init(channel: "test3", message: "3"))
                }
            }
            group.addTask {
                var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect SUBSCRIBE command
                #expect(String(buffer: outbound) == "*3\r\n$9\r\nSUBSCRIBE\r\n$5\r\ntest1\r\n$5\r\ntest2\r\n")
                // push 2 subscribes
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$9\r\nsubscribe\r\n$5\r\ntest1\r\n:1\r\n"))
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$9\r\nsubscribe\r\n$5\r\ntest2\r\n:2\r\n"))
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect SUBSCRIBE command
                #expect(String(buffer: outbound) == "*3\r\n$9\r\nSUBSCRIBE\r\n$5\r\ntest2\r\n$5\r\ntest3\r\n")
                // push 2 subscribes
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$9\r\nsubscribe\r\n$5\r\ntest2\r\n:2\r\n"))
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$9\r\nsubscribe\r\n$5\r\ntest3\r\n:2\r\n"))
                // push 3 messages
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$7\r\nmessage\r\n$5\r\ntest1\r\n$1\r\n1\r\n"))
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$7\r\nmessage\r\n$5\r\ntest2\r\n$1\r\n2\r\n"))
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$7\r\nmessage\r\n$5\r\ntest3\r\n$1\r\n3\r\n"))
                // expect UNSUBSCRIBE command
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(String(buffer: outbound) == "*3\r\n$11\r\nUNSUBSCRIBE\r\n$5\r\ntest1\r\n$5\r\ntest2\r\n")
                // push UNSUBSCRIBE message
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$11\r\nunsubscribe\r\n$5\r\ntest1\r\n:0\r\n"))
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$11\r\nunsubscribe\r\n$5\r\ntest2\r\n:0\r\n"))
                // expect UNSUBSCRIBE command
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(String(buffer: outbound) == "*3\r\n$11\r\nUNSUBSCRIBE\r\n$5\r\ntest2\r\n$5\r\ntest3\r\n")
                // push UNSUBSCRIBE message
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$11\r\nunsubscribe\r\n$5\r\ntest2\r\n:0\r\n"))
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$11\r\nunsubscribe\r\n$5\r\ntest3\r\n:0\r\n"))
            }
            try await group.waitForAll()
        }
    }

    @Test
    func testCloseFinishesSubscriptionWithError() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    try await connection.subscribe(to: "test") { subscription in
                        var iterator = subscription.makeAsyncIterator()
                        let message = try await iterator.next()
                        #expect(message == .init(channel: "test", message: "Testing!"))
                        await #expect(throws: ValkeyClientError(.connectionClosed)) {
                            try await iterator.next() == nil
                        }
                    }
                    Issue.record("Should have thrown a connection closed error")
                } catch let error as ValkeyClientError where error.errorCode == .connectionClosed {
                    //
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
            #expect(connection.channelHandler.value.subscriptions.subscriptions.count == 0)
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
    }

    @Test(.disabled("Need to fix issue with unsubscribing not returning a value when there is no subscription"))
    func testPUnsubscribe() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await connection.psubscribe(to: "test*") { subscription in
                    var iterator = subscription.makeAsyncIterator()
                    let message = try await iterator.next()
                    #expect(message == .init(channel: "test1", message: "Testing!"))
                    _ = try await connection.punsubscribe(pattern: ["test*"])
                    #expect(try await iterator.next() == nil)
                }
            }
            group.addTask {
                var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect PSUBSCRIBE command
                #expect(String(buffer: outbound) == "*2\r\n$10\r\nPSUBSCRIBE\r\n$5\r\ntest*\r\n")
                // push psubscribe
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$10\r\npsubscribe\r\n$5\r\ntest*\r\n:1\r\n"))
                // push pmessage
                try await channel.writeInbound(ByteBuffer(string: ">4\r\n$8\r\npmessage\r\n$5\r\ntest*\r\n$5\r\ntest1\r\n$8\r\nTesting!\r\n"))
                // expect PUNSUBSCRIBE command
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(String(buffer: outbound) == "*2\r\n$12\r\nPUNSUBSCRIBE\r\n$5\r\ntest*\r\n")
                // push punsubscribe
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$12\r\npunsubscribe\r\n$5\r\ntest*\r\n:0\r\n"))
                // push pmessage
                try await channel.writeInbound(ByteBuffer(string: ">4\r\n$8\r\npmessage\r\n$5\r\ntest*\r\n$5\r\ntest1\r\n$8\r\nTesting!\r\n"))
            }
            try await group.waitForAll()
        }
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
    }

    @Test
    func testInvalidPush() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    try await connection.subscribe(to: "test") { subscription in
                        var iterator = subscription.makeAsyncIterator()
                        await #expect(throws: Error.self) {
                            _ = try await iterator.next()
                        }
                    }
                    Issue.record("Should have thrown a connection closed error")
                } catch let error as ValkeyClientError where error.errorCode == .connectionClosed {
                    //
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
    }
}
