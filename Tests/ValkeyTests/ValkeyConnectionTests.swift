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
}
