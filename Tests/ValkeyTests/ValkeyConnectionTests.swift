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
import Valkey

@Suite
struct ConnectionTests {

    @Test
    func testConnectionCreationAndGET() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)

        async let fooResult = connection.get(key: "foo")

        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(outbound == ByteBuffer(string: "*2\r\n$3\r\nGET\r\n$3\r\nfoo\r\n"))

        try await channel.writeInbound(ByteBuffer(string: "$3\r\nBar\r\n"))
        #expect(try await fooResult == "Bar")
    }

    @Test
    func testSimpleError() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)

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
        let connection = try await ValkeyConnection.setupChannel(channel, configuration: .init(), logger: logger)

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
}
