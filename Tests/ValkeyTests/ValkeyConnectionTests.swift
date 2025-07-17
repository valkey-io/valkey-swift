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
struct ConnectionTests {

    @Test
    @available(valkeySwift 1.0, *)
    func testConnectionCreationAndGET() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

        async let fooResult = connection.get("foo").map { String(buffer: $0) }

        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(outbound == RESPToken(.command(["GET", "foo"])).base)

        try await channel.writeInbound(RESPToken(.bulkString("Bar")).base)
        #expect(try await fooResult == "Bar")
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testConnectionCreationHelloV3() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        _ = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)

        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(outbound == RESPToken(.command(["HELLO", "3"])).base)
    }

    @Test
    @available(valkeySwift 1.0, *)
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
    @available(valkeySwift 1.0, *)
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
    @available(valkeySwift 1.0, *)
    func testConnectionCreationHelloClientName() async throws {
        let channel = NIOAsyncTestingChannel()
        let configuration = ValkeyConnectionConfiguration(clientName: "Testing")
        let logger = Logger(label: "test")
        _ = try await ValkeyConnection.setupChannelAndConnect(
            channel,
            configuration: configuration,
            logger: logger
        )

        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(outbound == RESPToken(.command(["HELLO", "3", "SETNAME", "Testing"])).base)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testParseError() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

        async let fooResult = connection.get("foo")
        _ = try await channel.waitForOutboundWrite(as: ByteBuffer.self)

        await #expect(throws: RESPParsingError.self) {
            try await channel.writeInbound(ByteBuffer(string: "invalid resp token"))
        }
        do {
            _ = try await fooResult
            Issue.record()
        } catch let error as RESPParsingError {
            #expect(error.code == .invalidLeadingByte)
        }
        #expect(channel.isActive == false)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testSimpleError() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

        async let fooResult = connection.get("foo")
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
    @available(valkeySwift 1.0, *)
    func testBulkError() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

        async let fooResult = connection.get("foo")
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
    @available(valkeySwift 1.0, *)
    func testUnsolicitedErrorToken() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        _ = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

        await #expect(throws: ValkeyClientError(.unsolicitedToken, message: "Received a token without having sent a command")) {
            try await channel.writeInbound(RESPToken(.simpleError("Error!")).base)
        }
        try await channel.closeFuture.get()
    }

    @Test
    @available(valkeySwift 1.0, *)
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

    @Test
    @available(valkeySwift 1.0, *)
    func testPipeline() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, logger: logger)
        try await channel.processHello()

        async let results = connection.pipeline(
            SET("foo", value: "bar"),
            GET("foo")
        )
        var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        let set = RESPToken(.command(["SET", "foo", "bar"])).base
        #expect(outbound.readSlice(length: set.readableBytes) == set)
        #expect(outbound == RESPToken(.command(["GET", "foo"])).base)
        try await channel.writeInbound(RESPToken(.simpleString("OK")).base)
        try await channel.writeInbound(RESPToken(.bulkString("bar")).base)

        #expect(try await results.1.get().map { String(buffer: $0) } == "bar")
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testPipelineError() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, logger: logger)
        try await channel.processHello()

        async let asyncResults = connection.pipeline(
            SET("foo", value: "bar"),
            GET("foo")
        )
        var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        let set = RESPToken(.command(["SET", "foo", "bar"])).base
        #expect(outbound.readSlice(length: set.readableBytes) == set)
        #expect(outbound == RESPToken(.command(["GET", "foo"])).base)
        try await channel.writeInbound(RESPToken(.simpleString("OK")).base)
        try await channel.writeInbound(RESPToken(.bulkError("BulkError!")).base)

        let results = await asyncResults
        #expect(throws: ValkeyClientError(.commandError, message: "BulkError!")) { try results.1.get() }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testTransaction() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, logger: logger)
        try await channel.processHello()

        async let results = connection.transaction(
            SET("foo", value: "10"),
            INCR("foo")
        )
        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        var buffer = ByteBuffer()
        buffer.writeImmutableBuffer(RESPToken(.command(["MULTI"])).base)
        buffer.writeImmutableBuffer(RESPToken(.command(["SET", "foo", "10"])).base)
        buffer.writeImmutableBuffer(RESPToken(.command(["INCR", "foo"])).base)
        buffer.writeImmutableBuffer(RESPToken(.command(["EXEC"])).base)
        #expect(outbound == buffer)
        try await channel.writeInbound(RESPToken(.simpleString("OK")).base)
        try await channel.writeInbound(RESPToken(.simpleString("QUEUED")).base)
        try await channel.writeInbound(RESPToken(.simpleString("QUEUED")).base)
        try await channel.writeInbound(RESPToken(.array([.simpleString("OK"), .number(11)])).base)

        #expect(try await results.1.get() == 11)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testTransactionError() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, logger: logger)
        try await channel.processHello()

        async let asyncResults = connection.transaction(
            SET("foo", value: "bar"),
            INCR("foo")
        )
        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        var buffer = ByteBuffer()
        buffer.writeImmutableBuffer(RESPToken(.command(["MULTI"])).base)
        buffer.writeImmutableBuffer(RESPToken(.command(["SET", "foo", "bar"])).base)
        buffer.writeImmutableBuffer(RESPToken(.command(["INCR", "foo"])).base)
        buffer.writeImmutableBuffer(RESPToken(.command(["EXEC"])).base)
        #expect(outbound == buffer)
        try await channel.writeInbound(RESPToken(.simpleString("OK")).base)
        try await channel.writeInbound(RESPToken(.simpleString("QUEUED")).base)
        try await channel.writeInbound(RESPToken(.simpleError("ERROR")).base)
        try await channel.writeInbound(RESPToken(.simpleError("EXECABORT")).base)
        do {
            _ = try await asyncResults
            Issue.record("Transaction should throw error")
        } catch let error as ValkeyClientError {
            #expect(error == ValkeyClientError(.commandError, message: "EXECABORT"))
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testTransactionCommandError() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, logger: logger)
        try await channel.processHello()

        async let asyncResults = connection.transaction(
            SET("foo", value: "bar"),
            INCR("foo")
        )
        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        var buffer = ByteBuffer()
        buffer.writeImmutableBuffer(RESPToken(.command(["MULTI"])).base)
        buffer.writeImmutableBuffer(RESPToken(.command(["SET", "foo", "bar"])).base)
        buffer.writeImmutableBuffer(RESPToken(.command(["INCR", "foo"])).base)
        buffer.writeImmutableBuffer(RESPToken(.command(["EXEC"])).base)
        #expect(outbound == buffer)
        try await channel.writeInbound(RESPToken(.simpleString("OK")).base)
        try await channel.writeInbound(RESPToken(.simpleString("QUEUED")).base)
        try await channel.writeInbound(RESPToken(.simpleString("QUEUED")).base)
        try await channel.writeInbound(RESPToken(.array([.simpleString("OK"), .bulkError("error")])).base)
        let results = try await asyncResults
        #expect(throws: ValkeyClientError(.commandError, message: "error")) { try results.1.get() }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testCancellation() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                await #expect(throws: ValkeyClientError(.cancelled)) {
                    _ = try await connection.get("foo").map { String(buffer: $0) }
                }
            }
            _ = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            group.cancelAll()
        }
        // verify connection has been closed
        #expect(channel.isActive == false)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testAlreadyCancelled() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

        await withThrowingTaskGroup(of: Void.self) { group in
            group.cancelAll()
            group.addTask {
                await #expect(throws: ValkeyClientError(.cancelled)) {
                    _ = try await connection.get("foo").map { String(buffer: $0) }
                }
            }
        }
        // verify connection hasnt been closed
        #expect(channel.isActive == true)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testConnectionCloseDueToCancellation() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                await #expect(throws: ValkeyClientError(.connectionClosedDueToCancellation)) {
                    _ = try await connection.get("foo").map { String(buffer: $0) }
                }
            }
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    await #expect(throws: ValkeyClientError(.cancelled)) {
                        _ = try await connection.get("foo").map { String(buffer: $0) }
                    }
                }
                // wait for outbound write from both tasks
                _ = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                _ = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                group.cancelAll()
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testPipelineCancellation() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                let results = await connection.pipeline(
                    SET("foo", value: "bar"),
                    GET("foo")
                )
                #expect(throws: ValkeyClientError(.cancelled)) {
                    _ = try results.1.get()
                }
            }
            // Read SET and respond to it
            var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            let set = RESPToken(.command(["SET", "foo", "bar"])).base
            #expect(outbound.readSlice(length: set.readableBytes) == set)
            try await channel.writeInbound(RESPToken(.simpleString("OK")).base)

            group.cancelAll()
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testAlreadyCancelledPipeline() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
        try await channel.processHello()

        await withThrowingTaskGroup(of: Void.self) { group in
            group.cancelAll()
            group.addTask {
                let results = await connection.pipeline(
                    SET("foo", value: "bar"),
                    GET("foo")
                )
                #expect(throws: ValkeyClientError(.cancelled)) {
                    _ = try results.0.get()
                }
                #expect(throws: ValkeyClientError(.cancelled)) {
                    _ = try results.1.get()
                }
            }
        }
        // verify connection hasnt been closed
        #expect(channel.isActive == true)
    }
}
