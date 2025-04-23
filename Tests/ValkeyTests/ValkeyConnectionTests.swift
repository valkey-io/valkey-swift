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
struct ConnectionTests {

    @Test
    func testConnectionCreationAndGET() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

        async let fooResult = connection.get(key: "foo")?.decode(as: String.self)

        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(outbound == RESPToken(.command(["GET", "foo"])).base)

        try await channel.writeInbound(RESPToken(.bulkString("Bar")).base)
        #expect(try await fooResult == "Bar")
    }

    @Test
    func testConnectionCreationHelloV3() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        _ = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)

        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(outbound == RESPToken(.command(["HELLO", "3"])).base)
    }

    @Test
    func testConnectionCreationHelloError() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        _ = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)

        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(outbound == RESPToken(.command(["HELLO", "3"])).base)
        await #expect(throws: ValkeyClientError(.commandError, message: "Not supported")) {
            try await channel.writeInbound(RESPToken(.bulkError("Not supported")).base)
        }

        try await channel.closeFuture.get()
    }

    @Test
    func testConnectionCreationHelloAuth() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        _ = try await ValkeyConnection.setupChannelAndConnect(
            channel,
            configuration: .init(
                authentication: .init(username: "john", password: "smith")
            ),
            logger: logger
        )

        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(outbound == RESPToken(.command(["HELLO", "3", "AUTH", "john", "smith"])).base)
    }

    @Test
    func testConnectionCreationHelloClientName() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        _ = try await ValkeyConnection.setupChannelAndConnect(
            channel,
            clientName: "Testing",
            logger: logger
        )

        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(outbound == RESPToken(.command(["HELLO", "3", "SETNAME", "Testing"])).base)
    }

    @Test
    func testSimpleError() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

        async let fooResult = connection.get(key: "foo")
        _ = try await channel.waitForOutboundWrite(as: ByteBuffer.self)

        try await channel.writeInbound(RESPToken(.simpleError("Error!")).base)
        do {
            _ = try await fooResult
            Issue.record()
        } catch let error as ValkeyClientError {
            #expect(error.errorCode == .commandError)
            #expect(error.message == "Error!")
        }
    }

    @Test
    func testBulkError() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

        async let fooResult = connection.get(key: "foo")
        _ = try await channel.waitForOutboundWrite(as: ByteBuffer.self)

        try await channel.writeInbound(RESPToken(.bulkError("BulkError!")).base)
        do {
            _ = try await fooResult
            Issue.record()
        } catch let error as ValkeyClientError {
            #expect(error.errorCode == .commandError)
            #expect(error.message == "BulkError!")
        }
    }

    @Test
    func testUnsolicitedErrorToken() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        _ = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

        await #expect(throws: ValkeyClientError(.unsolicitedToken, message: "Received an error token without having sent a command")) {
            try await channel.writeInbound(RESPToken(.simpleError("Error!")).base)
        }
        try await channel.closeFuture.get()
    }

    @Test
    func testUnsolicitedToken() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        _ = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

        await #expect(throws: ValkeyClientError(.unsolicitedToken, message: "Received a token without having sent a command")) {
            try await channel.writeInbound(RESPToken(.bulkString("Bar")).base)
        }
        try await channel.closeFuture.get()
    }

    func testPipeline() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)

        async let results = connection.pipeline(
            SET(key: "foo", value: "bar"),
            GET(key: "foo")
        )
        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(String(buffer: outbound) == "*3\r\n$3\r\nSET\r\n$3\r\nfoo\r\n$3\r\nbar\r\n*2\r\n$3\r\nGET\r\n$3\r\nfoo\r\n")
        try await channel.writeInbound(ByteBuffer(string: "+OK\r\n$3\r\nbar\r\n"))
        #expect(try await results.1.get() == "bar")
    }

    @Test
    func testPipelineError() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)

        async let asyncResults = connection.pipeline(
            SET(key: "foo", value: "bar"),
            GET(key: "foo")
        )
        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(String(buffer: outbound) == "*3\r\n$3\r\nSET\r\n$3\r\nfoo\r\n$3\r\nbar\r\n*2\r\n$3\r\nGET\r\n$3\r\nfoo\r\n")
        try await channel.writeInbound(ByteBuffer(string: "+OK\r\n!10\r\nBulkError!\r\n"))
        let results = await asyncResults
        #expect(throws: ValkeyClientError(.commandError, message: "BulkError!")) { try results.1.get() }
    }

    @Test
    func testTransaction() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)

        async let results = connection.transaction(
            SET(key: "foo", value: "10"),
            INCR(key: "foo")
        )
        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(
            String(buffer: outbound)
                == "*1\r\n$5\r\nMULTI\r\n*3\r\n$3\r\nSET\r\n$3\r\nfoo\r\n$2\r\n10\r\n*2\r\n$4\r\nINCR\r\n$3\r\nfoo\r\n*1\r\n$4\r\nEXEC\r\n"
        )
        try await channel.writeInbound(ByteBuffer(string: "+OK\r\n+QUEUED\r\n+QUEUED\r\n*2\r\n+OK\r\n:11\r\n"))
        #expect(try await results.1.get() == 11)
    }

    @Test
    func testTransactionError() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)

        async let asyncResults = connection.transaction(
            SET(key: "foo", value: "bar"),
            INCR(key: "foo")
        )
        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(
            String(buffer: outbound)
                == "*1\r\n$5\r\nMULTI\r\n*3\r\n$3\r\nSET\r\n$3\r\nfoo\r\n$3\r\nbar\r\n*2\r\n$4\r\nINCR\r\n$3\r\nfoo\r\n*1\r\n$4\r\nEXEC\r\n"
        )
        try await channel.writeInbound(ByteBuffer(string: "+OK\r\n+QUEUED\r\n!5\r\nERROR\r\n!9\r\nEXECABORT\r\n"))
        do {
            _ = try await asyncResults
            Issue.record("Transaction should throw error")
        } catch let error as ValkeyClientError {
            #expect(error == ValkeyClientError(.commandError, message: "EXECABORT"))
        }
    }

    @Test
    func testTransactionCommandError() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)

        async let asyncResults = connection.transaction(
            SET(key: "foo", value: "bar"),
            INCR(key: "foo")
        )
        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(
            String(buffer: outbound)
                == "*1\r\n$5\r\nMULTI\r\n*3\r\n$3\r\nSET\r\n$3\r\nfoo\r\n$3\r\nbar\r\n*2\r\n$4\r\nINCR\r\n$3\r\nfoo\r\n*1\r\n$4\r\nEXEC\r\n"
        )
        try await channel.writeInbound(ByteBuffer(string: "+OK\r\n+QUEUED\r\n+QUEUED\r\n*2\r\n+OK\r\n!5\r\nerror\r\n"))
        let results = try await asyncResults
        #expect(throws: ValkeyClientError(.commandError, message: "error")) { try results.1.get() }
    }
}
