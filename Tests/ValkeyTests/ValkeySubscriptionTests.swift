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

import Logging
import NIOCore
import NIOEmbedded
import Testing

@testable import Valkey

@Suite
struct SubscriptionTests {
    struct StateMachine {
        final class TestType: Identifiable {}
        @Test
        @available(valkeySwift 1.0, *)
        func testSubscribeAndUnsubscribe() async throws {
            var stateMachine = ValkeyChannelStateMachine<TestType>()
            let value = TestType()
            #expect(stateMachine.add(subscription: value) == .subscribe)
            stateMachine.added()
            #expect(stateMachine.close(subscription: value) == .unsubscribe)
            #expect(stateMachine.closed() == .removeChannel)
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testSubscribeAndReceiveMessage() async throws {
            var stateMachine = ValkeyChannelStateMachine<TestType>()
            let value = TestType()
            #expect(stateMachine.add(subscription: value) == .subscribe)
            if case .doNothing = stateMachine.receivedMessage() {
            } else {
                Issue.record()
            }
            stateMachine.added()
            if case .forwardMessage(let values) = stateMachine.receivedMessage() {
                #expect(value.id == values.first?.id)
            } else {
                Issue.record()
            }
            #expect(stateMachine.close(subscription: value) == .unsubscribe)
            #expect(stateMachine.closed() == .removeChannel)
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testMultipleSubscriptions() async throws {
            var stateMachine = ValkeyChannelStateMachine<TestType>()
            let value = TestType()
            let value2 = TestType()
            #expect(stateMachine.add(subscription: value) == .subscribe)
            #expect(stateMachine.add(subscription: value2) == .doNothing)
            stateMachine.added()
            if case .forwardMessage(let values) = stateMachine.receivedMessage() {
                #expect(value.id == values.first?.id)
                #expect(value2.id == values.last?.id)
            } else {
                Issue.record()
            }
            #expect(stateMachine.close(subscription: value) == .doNothing)
            #expect(stateMachine.close(subscription: value2) == .unsubscribe)
            #expect(stateMachine.closed() == .removeChannel)
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testMultipleSubscriptionsV2() async throws {
            var stateMachine = ValkeyChannelStateMachine<TestType>()
            let value = TestType()
            let value2 = TestType()
            #expect(stateMachine.add(subscription: value) == .subscribe)
            stateMachine.added()
            #expect(stateMachine.add(subscription: value2) == .doNothing)
            if case .forwardMessage(let values) = stateMachine.receivedMessage() {
                #expect(value.id == values.first?.id)
                #expect(value2.id == values.last?.id)
            } else {
                Issue.record()
            }
            #expect(stateMachine.close(subscription: value) == .doNothing)
            #expect(stateMachine.close(subscription: value2) == .unsubscribe)
            #expect(stateMachine.closed() == .removeChannel)
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testSubscribeAfterStartingClose() async throws {
            var stateMachine = ValkeyChannelStateMachine<TestType>()
            let value = TestType()
            #expect(stateMachine.add(subscription: value) == .subscribe)
            stateMachine.added()
            #expect(stateMachine.close(subscription: value) == .unsubscribe)
            let value2 = TestType()
            #expect(stateMachine.add(subscription: value2) == .subscribe)
            stateMachine.added()
            #expect(stateMachine.close(subscription: value2) == .unsubscribe)
            #expect(stateMachine.closed() == .removeChannel)
        }

    }
    @Test
    @available(valkeySwift 1.0, *)
    func testSubscribe() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

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
                #expect(outbound == RESPToken(.command(["SUBSCRIBE", "test"])).base)
                // push subscribe
                try await channel.writeInbound(RESPToken(.push([.bulkString("subscribe"), .bulkString("test"), .number(1)])).base)
                // push message
                try await channel.writeInbound(RESPToken(.push([.bulkString("message"), .bulkString("test"), .bulkString("Testing!")])).base)
                // expect UNSUBSCRIBE command
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(outbound == RESPToken(.command(["UNSUBSCRIBE", "test"])).base)
                // push unsubscribe
                try await channel.writeInbound(RESPToken(.push([.bulkString("unsubscribe"), .bulkString("test"), .number(0)])).base)
            }
            try await group.waitForAll()
        }
        #expect(await connection.isSubscriptionsEmpty())
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testSubscribeFailed() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

        async let subscribeResult: Void = connection.subscribe(to: "test") { _ in }
        _ = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        try await channel.writeInbound(RESPToken(.bulkError("BulkError!")).base)
        do {
            _ = try await subscribeResult
            Issue.record()
        } catch let error as ValkeyClientError {
            #expect(error.errorCode == .commandError)
            #expect(error.message == "BulkError!")
        }
        // Verify GET runs fine after failing subscription
        async let fooResult = connection.get("foo")
        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(outbound == RESPToken(.command(["GET", "foo"])).base)
        try await channel.writeInbound(RESPToken(.bulkString("Bar")).base)
        #expect(try await fooResult.map { String(buffer: $0) } == "Bar")

        #expect(await connection.isSubscriptionsEmpty())
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testSubscribeAfterChannelError() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await connection.subscribe(to: "test") { subscription in
                    _ = await #expect(throws: ValkeyClientError(.unsolicitedToken, message: "Received a token without having sent a command")) {
                        for try await _ in subscription {}
                    }
                }
            }
            group.addTask {
                let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect SUBSCRIBE command
                #expect(outbound == RESPToken(.command(["SUBSCRIBE", "test"])).base)
                // push subscribe
                try await channel.writeInbound(RESPToken(.push([.bulkString("subscribe"), .bulkString("test"), .number(1)])).base)
                // push unsolicited message
                await #expect(throws: ValkeyClientError(.unsolicitedToken, message: "Received a token without having sent a command")) {
                    try await channel.writeInbound(RESPToken(.bulkString("Bar")).base)
                }
            }
            try await group.waitForAll()
        }
        #expect(await connection.isSubscriptionsEmpty())
    }

    /// Test a single subscription can subscribe to multiple channels
    @Test
    @available(valkeySwift 1.0, *)
    func testSubscribeMultipleChannels() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

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
                #expect(outbound == RESPToken(.command(["SUBSCRIBE", "test1", "test2", "test3"])).base)
                // push 3 subscribes (one for each channel)
                try await channel.writeInbound(RESPToken(.push([.bulkString("subscribe"), .bulkString("test1"), .number(1)])).base)
                try await channel.writeInbound(RESPToken(.push([.bulkString("subscribe"), .bulkString("test2"), .number(1)])).base)
                try await channel.writeInbound(RESPToken(.push([.bulkString("subscribe"), .bulkString("test3"), .number(1)])).base)
                // push 3 messages (one on each channel)
                try await channel.writeInbound(RESPToken(.push([.bulkString("message"), .bulkString("test1"), .bulkString("1")])).base)
                try await channel.writeInbound(RESPToken(.push([.bulkString("message"), .bulkString("test2"), .bulkString("1")])).base)
                try await channel.writeInbound(RESPToken(.push([.bulkString("message"), .bulkString("test3"), .bulkString("1")])).base)
                // expect UNSUBSCRIBE command
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(outbound == RESPToken(.command(["UNSUBSCRIBE", "test1", "test2", "test3"])).base)
                // push UNSUBSCRIBE message
                try await channel.writeInbound(RESPToken(.push([.bulkString("unsubscribe"), .bulkString("test1"), .number(0)])).base)
                try await channel.writeInbound(RESPToken(.push([.bulkString("unsubscribe"), .bulkString("test2"), .number(0)])).base)
                try await channel.writeInbound(RESPToken(.push([.bulkString("unsubscribe"), .bulkString("test3"), .number(0)])).base)
            }
            try await group.waitForAll()
        }
        #expect(await connection.isSubscriptionsEmpty())
    }

    /// Test you can have multiple subscriptions running on one connection
    @Test
    @available(valkeySwift 1.0, *)
    func testMultipleSubscriptions() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

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
                // expect SUBSCRIBE from task 1
                var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(outbound == RESPToken(.command(["SUBSCRIBE", "test1", "test2"])).base)
                // push 2 subscribes
                try await channel.writeInbound(RESPToken(.push([.bulkString("subscribe"), .bulkString("test1"), .number(1)])).base)
                try await channel.writeInbound(RESPToken(.push([.bulkString("subscribe"), .bulkString("test2"), .number(1)])).base)
                // expect SUBSCRIBE from task 2
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(outbound == RESPToken(.command(["SUBSCRIBE", "test2", "test3"])).base)
                // push 2 subscribes
                try await channel.writeInbound(RESPToken(.push([.bulkString("subscribe"), .bulkString("test2"), .number(1)])).base)
                try await channel.writeInbound(RESPToken(.push([.bulkString("subscribe"), .bulkString("test3"), .number(1)])).base)
                // push 2 messages
                try await channel.writeInbound(RESPToken(.push([.bulkString("message"), .bulkString("test1"), .bulkString("1")])).base)
                try await channel.writeInbound(RESPToken(.push([.bulkString("message"), .bulkString("test2"), .bulkString("2")])).base)
                // expect UNSUBSCRIBE from task 1
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(outbound == RESPToken(.command(["UNSUBSCRIBE", "test1"])).base)
                // push UNSUBSCRIBE message
                try await channel.writeInbound(RESPToken(.push([.bulkString("unsubscribe"), .bulkString("test1"), .number(0)])).base)

                // push 1 message
                try await channel.writeInbound(RESPToken(.push([.bulkString("message"), .bulkString("test3"), .bulkString("3")])).base)
                // expect UNSUBSCRIBE from task 2
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(outbound == RESPToken(.command(["UNSUBSCRIBE", "test2", "test3"])).base)
                // push unsubscribe
                try await channel.writeInbound(RESPToken(.push([.bulkString("unsubscribe"), .bulkString("test2"), .number(0)])).base)
                try await channel.writeInbound(RESPToken(.push([.bulkString("unsubscribe"), .bulkString("test3"), .number(0)])).base)
            }
            try await group.waitForAll()
        }
        #expect(await connection.isSubscriptionsEmpty())
    }

    /// Test we can unsubscribe from one subscription while the other still continues to receive messages
    @Test
    @available(valkeySwift 1.0, *)
    func testMultipleSubscriptionsDontAffectEachOther() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()
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
                // expect SUBSCRIBE from task 1, we don't get one from task 2 as we have already instigated a subscribe command
                #expect(outbound == RESPToken(.command(["SUBSCRIBE", "test1"])).base)
                // push subscribes
                try await channel.writeInbound(RESPToken(.push([.bulkString("subscribe"), .bulkString("test1"), .number(1)])).base)

                // push message and wait and push another
                try await channel.writeInbound(RESPToken(.push([.bulkString("message"), .bulkString("test1"), .bulkString("1")])).base)
                // wait for task 1 to complete. We don't get an UNSUBSCRIBE as task 2 is still subscribed
                await stream.first { _ in true }
                try await channel.writeInbound(RESPToken(.push([.bulkString("message"), .bulkString("test1"), .bulkString("2")])).base)
                // expect UNSUBSCRIBE
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(outbound == RESPToken(.command(["UNSUBSCRIBE", "test1"])).base)
                // push UNSUBSCRIBE message
                try await channel.writeInbound(RESPToken(.push([.bulkString("unsubscribe"), .bulkString("test1"), .number(0)])).base)
            }
            try await group.waitForAll()
        }
        #expect(await connection.isSubscriptionsEmpty())
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testCloseFinishesSubscriptionWithError() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

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
                #expect(outbound == RESPToken(.command(["SUBSCRIBE", "test"])).base)
                // push subscribe
                try await channel.writeInbound(RESPToken(.push([.bulkString("subscribe"), .bulkString("test"), .number(1)])).base)
                // push message
                try await channel.writeInbound(RESPToken(.push([.bulkString("message"), .bulkString("test"), .bulkString("Testing!")])).base)
                // close
                try await channel.close()
            }
            try await group.waitForAll()
        }
        #expect(await connection.isSubscriptionsEmpty())
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testPSubscribe() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

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
                // expect PSUBSCRIBE command
                #expect(outbound == RESPToken(.command(["PSUBSCRIBE", "test*"])).base)
                // push psubscribe
                try await channel.writeInbound(RESPToken(.push([.bulkString("psubscribe"), .bulkString("test*"), .number(1)])).base)
                // push 3 messages (one on each channel)
                try await channel.writeInbound(
                    RESPToken(.push([.bulkString("pmessage"), .bulkString("test*"), .bulkString("test1"), .bulkString("1")])).base
                )
                try await channel.writeInbound(
                    RESPToken(.push([.bulkString("pmessage"), .bulkString("test*"), .bulkString("test2"), .bulkString("2")])).base
                )
                try await channel.writeInbound(
                    RESPToken(.push([.bulkString("pmessage"), .bulkString("test*"), .bulkString("test3"), .bulkString("3")])).base
                )
                // expect PUNSUBSCRIBE command
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(outbound == RESPToken(.command(["PUNSUBSCRIBE", "test*"])).base)
                // push PUNSUBSCRIBE message
                try await channel.writeInbound(RESPToken(.push([.bulkString("punsubscribe"), .bulkString("test*"), .number(0)])).base)
            }
            try await group.waitForAll()
        }
        #expect(await connection.isSubscriptionsEmpty())
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testPSubscribeAndSubscribeOnOneChanel() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

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
                // expect PSUBSCRIBE command
                var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(outbound == RESPToken(.command(["PSUBSCRIBE", "test*"])).base)
                // push psubscribe
                try await channel.writeInbound(RESPToken(.push([.bulkString("psubscribe"), .bulkString("test*"), .number(1)])).base)
                // expect SUBSCRIBE command
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(outbound == RESPToken(.command(["SUBSCRIBE", "test1"])).base)
                // push subscribe
                try await channel.writeInbound(RESPToken(.push([.bulkString("subscribe"), .bulkString("test1"), .number(1)])).base)
                // push pmessage
                try await channel.writeInbound(
                    RESPToken(.push([.bulkString("pmessage"), .bulkString("test*"), .bulkString("test1"), .bulkString("1")])).base
                )
                // push message
                try await channel.writeInbound(RESPToken(.push([.bulkString("message"), .bulkString("test1"), .bulkString("1")])).base)
                // expect UNSUBSCRIBE command
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(outbound == RESPToken(.command(["UNSUBSCRIBE", "test1"])).base)
                // push unsubscribe
                try await channel.writeInbound(RESPToken(.push([.bulkString("unsubscribe"), .bulkString("test1"), .number(0)])).base)
                // expect PUNSUBSCRIBE command
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(outbound == RESPToken(.command(["PUNSUBSCRIBE", "test*"])).base)
                // push punsubscribe
                try await channel.writeInbound(RESPToken(.push([.bulkString("punsubscribe"), .bulkString("test*"), .number(0)])).base)
            }
            try await group.waitForAll()
        }
        #expect(await connection.isSubscriptionsEmpty())
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testInvalidPush() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await connection.subscribe(to: "test") { subscription in
                    var iterator = subscription.makeAsyncIterator()
                    await #expect(throws: ValkeyClientError(.subscriptionError, message: "Received invalid message push notification")) {
                        _ = try await iterator.next()
                    }
                }
            }
            group.addTask {
                let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect SUBSCRIBE command
                #expect(outbound == RESPToken(.command(["SUBSCRIBE", "test"])).base)
                // push subscribe
                try await channel.writeInbound(RESPToken(.push([.bulkString("subscribe"), .bulkString("test"), .number(1)])).base)
                // push invalid message
                await #expect(throws: ValkeyClientError(.subscriptionError, message: "Received invalid message push notification")) {
                    try await channel.writeInbound(
                        RESPToken(.push([.bulkString("message"), .bulkString("test"), .bulkString("Testing!"), .number(1)])).base
                    )
                }
            }
            try await group.waitForAll()
        }
        #expect(await connection.isSubscriptionsEmpty())
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testSubscriptionsAndCommandsCombined() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await connection.subscribe(to: "test") { subscription in
                    var iterator = subscription.makeAsyncIterator()
                    try #expect(await iterator.next() == .init(channel: "test", message: "Testing!"))
                    let value = try await connection.get("foo")
                    #expect(value.map { String(buffer: $0) } == "bar")
                    try #expect(await iterator.next() == .init(channel: "test", message: "Testing2!"))
                }
            }
            group.addTask {
                var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect SUBSCRIBE command
                #expect(outbound == RESPToken(.command(["SUBSCRIBE", "test"])).base)
                // push subscribe
                try await channel.writeInbound(RESPToken(.push([.bulkString("subscribe"), .bulkString("test"), .number(1)])).base)
                // push message
                try await channel.writeInbound(RESPToken(.push([.bulkString("message"), .bulkString("test"), .bulkString("Testing!")])).base)
                // expect GET command
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(outbound == RESPToken(.command(["GET", "foo"])).base)
                // write command response
                try await channel.writeInbound(RESPToken(.bulkString("bar")).base)
                // push message
                try await channel.writeInbound(RESPToken(.push([.bulkString("message"), .bulkString("test"), .bulkString("Testing2!")])).base)
                // expect UNSUBSCRIBE command
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(outbound == RESPToken(.command(["UNSUBSCRIBE", "test"])).base)
                // push unsubscribe
                try await channel.writeInbound(RESPToken(.push([.bulkString("unsubscribe"), .bulkString("test"), .number(0)])).base)
            }
            try await group.waitForAll()
        }
        #expect(await connection.isSubscriptionsEmpty())
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testSubscribeError() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

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
                #expect(outbound == RESPToken(.command(["SUBSCRIBE", "test"])).base)
                // return error
                try await channel.writeInbound(RESPToken(.bulkError("Subscription error")).base)

            }
            try await group.waitForAll()
        }
        #expect(await connection.isSubscriptionsEmpty())
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testUnsubscribeError() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                await #expect(throws: ValkeyClientError(.commandError, message: "Subscription error")) {
                    try await connection.subscribe(to: "test") { subscription in
                    }
                }
            }
            group.addTask {
                // expect SUBSCRIBE command
                var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(outbound == RESPToken(.command(["SUBSCRIBE", "test"])).base)
                // push subscribe
                try await channel.writeInbound(RESPToken(.push([.bulkString("subscribe"), .bulkString("test"), .number(1)])).base)
                // expect UNSUBSCRIBE command
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(outbound == RESPToken(.command(["UNSUBSCRIBE", "test"])).base)
                // return error
                try await channel.writeInbound(RESPToken(.bulkError("Subscription error")).base)
            }
            try await group.waitForAll()
        }
        #expect(await connection.isSubscriptionsEmpty())
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testShardSubscribe() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await connection.ssubscribe(to: "test") { subscription in
                    let message = try await subscription.first { _ in true }
                    #expect(message == .init(channel: "test", message: "Testing!"))
                }
            }
            group.addTask {
                // expect SUBSCRIBE command
                var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(outbound == RESPToken(.command(["SSUBSCRIBE", "test"])).base)
                // push subscribe
                try await channel.writeInbound(RESPToken(.push([.bulkString("ssubscribe"), .bulkString("test"), .number(1)])).base)
                try await channel.writeInbound(ByteBuffer(string: ">3\r\n$10\r\nssubscribe\r\n$4\r\ntest\r\n:1\r\n"))
                // push message
                try await channel.writeInbound(RESPToken(.push([.bulkString("smessage"), .bulkString("test"), .bulkString("Testing!")])).base)
                // expect SUNSUBSCRIBE command
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(outbound == RESPToken(.command(["SUNSUBSCRIBE", "test"])).base)
                // push unsubscribe
                try await channel.writeInbound(RESPToken(.push([.bulkString("sunsubscribe"), .bulkString("test"), .number(1)])).base)
            }
            try await group.waitForAll()
        }
        #expect(await connection.isSubscriptionsEmpty())
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testCancelSubscribe() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                await #expect(throws: ValkeyClientError(.cancelled)) {
                    try await connection.subscribe(to: "test") { _ in }
                }
            }
            group.addTask {
                let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect SUBSCRIBE command
                #expect(outbound == RESPToken(.command(["SUBSCRIBE", "test"])).base)
            }
            try await group.next()
            group.cancelAll()
        }
        #expect(await connection.isSubscriptionsEmpty())
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testCancelSubscribeStream() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                await #expect(throws: CancellationError.self) {
                    try await connection.subscribe(to: "test") { subscription in
                        for try await _ in subscription {}
                    }
                }
            }
            group.addTask {
                let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                // expect SUBSCRIBE command
                #expect(outbound == RESPToken(.command(["SUBSCRIBE", "test"])).base)
                // push subscribe
                try await channel.writeInbound(RESPToken(.push([.bulkString("subscribe"), .bulkString("test"), .number(1)])).base)
                // push message
                try await channel.writeInbound(RESPToken(.push([.bulkString("message"), .bulkString("test"), .bulkString("Testing!")])).base)

            }
            try await group.next()
            group.cancelAll()

            // respond to unsubscribe after cancellation
            let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            #expect(outbound == RESPToken(.command(["UNSUBSCRIBE", "test"])).base)
            // push unsubcribe
            try await channel.writeInbound(RESPToken(.push([.bulkString("unsubscribe"), .bulkString("test"), .number(1)])).base)
        }
        #expect(await connection.isSubscriptionsEmpty())
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testCancelUnsubscribe() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

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
                #expect(outbound == RESPToken(.command(["SUBSCRIBE", "test"])).base)
                // push subscribe
                try await channel.writeInbound(RESPToken(.push([.bulkString("subscribe"), .bulkString("test"), .number(1)])).base)
                // push message
                try await channel.writeInbound(RESPToken(.push([.bulkString("message"), .bulkString("test"), .bulkString("Testing!")])).base)
                // expect UNSUBSCRIBE command
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(outbound == RESPToken(.command(["UNSUBSCRIBE", "test"])).base)
            }
            try await group.next()
            group.cancelAll()
        }
        #expect(await connection.isSubscriptionsEmpty())
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testKeyInvalidationSubscription() async throws {
        let channel = NIOAsyncTestingChannel()
        var logger = Logger(label: "test")
        logger.logLevel = .trace
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await connection.subscribeKeyInvalidations { keys in
                    var iterator = keys.makeAsyncIterator()
                    let key = try await iterator.next()
                    #expect(key == "foo")
                }
            }

            group.addTask {
                // SUBSCRIBE command
                var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(outbound == RESPToken(.command(["SUBSCRIBE", "__redis__:invalidate"])).base)
                // push subscribe
                try await channel.writeInbound(RESPToken(.push([.bulkString("subscribe"), .bulkString("__redis__:invalidate"), .number(1)])).base)
                // push invalidate
                try await channel.writeInbound(RESPToken(.push([.bulkString("invalidate"), .bulkString("foo")])).base)
                // expect UNSUBSCRIBE command
                outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(outbound == RESPToken(.command(["UNSUBSCRIBE", "__redis__:invalidate"])).base)
                // push unsubscribe
                try await channel.writeInbound(RESPToken(.push([.bulkString("unsubscribe"), .bulkString("__redis__:invalidate"), .number(0)])).base)
            }
            try await group.waitForAll()
        }
    }
}
