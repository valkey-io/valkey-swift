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
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(respVersion: .v2), logger: logger)

        async let fooResult = connection.get(key: "foo")

        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(String(buffer: outbound) == "*2\r\n$3\r\nGET\r\n$3\r\nfoo\r\n")

        try await channel.writeInbound(ByteBuffer(string: "$3\r\nBar\r\n"))
        #expect(try await fooResult == "Bar")
    }

    @Test
    func testConnectionCreationHelloV3() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        _ = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(respVersion: .v3), logger: logger)

        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(outbound == ByteBuffer(string: "*2\r\n$5\r\nHELLO\r\n$1\r\n3\r\n"))
    }

    @Test
    func testConnectionCreationHelloError() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        _ = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(respVersion: .v3), logger: logger)

        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(outbound == ByteBuffer(string: "*2\r\n$5\r\nHELLO\r\n$1\r\n3\r\n"))
        await #expect(throws: ValkeyClientError(.commandError, message: "Not supported")) {
            try await channel.writeInbound(ByteBuffer(string: "!13\r\nNot supported\r\n"))
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
                respVersion: .v3,
                authentication: .init(username: "john", password: "smith")
            ),
            logger: logger
        )

        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(outbound == ByteBuffer(string: "*5\r\n$5\r\nHELLO\r\n$1\r\n3\r\n$4\r\nAUTH\r\n$4\r\njohn\r\n$5\r\nsmith\r\n"))
    }

    @Test
    func testConnectionCreationHelloClientName() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        _ = try await ValkeyConnection.setupChannelAndConnect(
            channel,
            configuration: .init(respVersion: .v2),
            clientName: "Testing",
            logger: logger
        )

        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(outbound == ByteBuffer(string: "*4\r\n$5\r\nHELLO\r\n$1\r\n2\r\n$7\r\nSETNAME\r\n$7\r\nTesting\r\n"))
    }

    @Test
    func testSimpleError() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(respVersion: .v2), logger: logger)

        async let fooResult = connection.get(key: "foo")
        _ = try await channel.waitForOutboundWrite(as: ByteBuffer.self)

        try await channel.writeInbound(ByteBuffer(string: "-Error!\r\n"))
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
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(respVersion: .v2), logger: logger)

        async let fooResult = connection.get(key: "foo")
        _ = try await channel.waitForOutboundWrite(as: ByteBuffer.self)

        try await channel.writeInbound(ByteBuffer(string: "!10\r\nBulkError!\r\n"))
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
        _ = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)

        await #expect(throws: ValkeyClientError(.unsolicitedToken, message: "Received an error token without having sent a command")) {
            try await channel.writeInbound(ByteBuffer(string: "-Error!\r\n"))
        }
        try await channel.closeFuture.get()
    }

    @Test
    func testUnsolicitedToken() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        _ = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)

        await #expect(throws: ValkeyClientError(.unsolicitedToken, message: "Received a token without having sent a command")) {
            try await channel.writeInbound(ByteBuffer(string: "$3\r\nBar\r\n"))
        }
        try await channel.closeFuture.get()
    }
}
