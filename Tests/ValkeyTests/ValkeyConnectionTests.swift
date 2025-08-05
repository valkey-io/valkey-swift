//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import Logging
import NIOCore
import NIOEmbedded
import NIOPosix
import Testing

#if DistributedTracingSupport
@testable import Instrumentation
#endif

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

        var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        let hello3 = RESPToken(.command(["HELLO", "3"])).base
        #expect(outbound.readSlice(length: hello3.readableBytes) == hello3)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testConnectionCreationHelloError() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        _ = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)

        var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        let hello3 = RESPToken(.command(["HELLO", "3"])).base
        #expect(outbound.readSlice(length: hello3.readableBytes) == hello3)
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

        var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        let hello3 = RESPToken(.command(["HELLO", "3", "AUTH", "john", "smith"])).base
        #expect(outbound.readSlice(length: hello3.readableBytes) == hello3)
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

        var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        let hello3 = RESPToken(.command(["HELLO", "3", "SETNAME", "Testing"])).base
        #expect(outbound.readSlice(length: hello3.readableBytes) == hello3)
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

        async let results = connection.execute(
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

        async let asyncResults = connection.execute(
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
                let results = await connection.execute(
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
                let results = await connection.execute(
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

    @Test
    @available(valkeySwift 1.0, *)
    func testCloseOnServeClose() async throws {
        let channel = try await ServerBootstrap(group: NIOSingletons.posixEventLoopGroup)
            .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.allowRemoteHalfClosure, value: true)
            .childChannelInitializer { channel in
                channel.eventLoop.makeCompletedFuture {
                    try channel.pipeline.syncOperations.addHandler(
                        TestValkeyServerChannelHandler { command, _, write in
                            switch command {
                            case "QUIT":
                                write(ByteBuffer(string: "+2OK\r\n"))
                                channel.close(mode: .output, promise: nil)
                            default:
                                fatalError("Unexpected command: \(command)")
                            }

                        }
                    )
                }
            }
            .bind(host: "127.0.0.1", port: 0)
            .get()
        let port = channel.localAddress!.port!
        try await ValkeyConnection.withConnection(
            address: .hostname("127.0.0.1", port: port),
            configuration: .init(),
            eventLoop: MultiThreadedEventLoopGroup.singleton.any(),
            logger: Logger(label: "test")
        ) { connection in
            let clientChannel = await connection.channel
            try await connection.quit()
            await withCheckedContinuation { cont in
                clientChannel.closeFuture.whenComplete { _ in
                    cont.resume()
                }
            }
        }
        try await channel.close()
    }

    #if DistributedTracingSupport && compiler(>=6.2) // Swift Testing exit tests only added in 6.2
    @Suite(.serialized)
    struct DistributedTracingTests {
        @Test
        @available(valkeySwift 1.0, *)
        func testSingleCommandSpan() async throws {
            await #expect(processExitsWith: .success, "Running in a separate process because test uses bootstrap") {
                let tracer = TestTracer()
                InstrumentationSystem.bootstrapInternal(tracer)

                let channel = NIOAsyncTestingChannel()
                let logger = Logger(label: "test")
                let connection = try await ValkeyConnection.setupChannelAndConnect(channel, logger: logger)
                try await channel.processHello()

                async let fooResult = connection.get("foo").map { String(buffer: $0) }

                let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(outbound == RESPToken(.command(["GET", "foo"])).base)

                try await channel.writeInbound(RESPToken(.bulkString("Bar")).base)
                #expect(try await fooResult == "Bar")

                #expect(tracer.spans.count == 1)
                let span = try #require(tracer.spans.first)
                #expect(span.operationName == "GET")
                #expect(span.kind == .client)
                #expect(span.recordedErrors.isEmpty)
                #expect(span.attributes == [
                    "db.system.name": "valkey",
                    "db.operation.name": "GET",
                    "server.address": "127.0.0.1",
                    "network.peer.address": "127.0.0.1",
                    "network.peer.port": 6379
                ])
                #expect(span.recordedErrors.isEmpty)
                #expect(span.status == nil)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testSingleCommandFailureSpan() async throws {
            await #expect(processExitsWith: .success, "Running in a separate process because test uses bootstrap") {
                let tracer = TestTracer()
                InstrumentationSystem.bootstrapInternal(tracer)

                let channel = NIOAsyncTestingChannel()
                let logger = Logger(label: "test")
                let connection = try await ValkeyConnection.setupChannelAndConnect(channel, logger: logger)
                try await channel.processHello()

                async let fooResult = connection.get("foo")
                _ = try await channel.waitForOutboundWrite(as: ByteBuffer.self)

                try await channel.writeInbound(RESPToken(.simpleError("ERR Error!")).base)
                do {
                    _ = try await fooResult
                    Issue.record()
                } catch let error as ValkeyClientError {
                    #expect(error.errorCode == .commandError)
                    #expect(error.message == "ERR Error!")
                }

                #expect(tracer.spans.count == 1)
                let span = try #require(tracer.spans.first)
                #expect(span.operationName == "GET")
                #expect(span.kind == .client)
                #expect(span.recordedErrors.count == 1)
                let error = try #require(span.recordedErrors.first)
                #expect(error.0 as? ValkeyClientError == ValkeyClientError(.commandError, message: "ERR Error!"))
                #expect(span.attributes == [
                    "db.system.name": "valkey",
                    "db.operation.name": "GET",
                    "db.response.status_code": "ERR",
                    "server.address": "127.0.0.1",
                    "network.peer.address": "127.0.0.1",
                    "network.peer.port": 6379
                ])
                #expect(span.status?.code == .error)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testPipelinedSameCommandsSpan() async throws {
            await #expect(processExitsWith: .success, "Running in a separate process because test uses bootstrap") {
                let tracer = TestTracer()
                InstrumentationSystem.bootstrapInternal(tracer)

                let channel = NIOAsyncTestingChannel()
                let logger = Logger(label: "test")
                let connection = try await ValkeyConnection.setupChannelAndConnect(channel, logger: logger)
                try await channel.processHello()

                async let results = connection.execute(
                    SET("foo", value: "bar"),
                    SET("bar", value: "foo")
                )
                var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                let set1 = RESPToken(.command(["SET", "foo", "bar"])).base
                #expect(outbound.readSlice(length: set1.readableBytes) == set1)
                #expect(outbound == RESPToken(.command(["SET", "bar", "foo"])).base)
                try await channel.writeInbound(RESPToken(.simpleString("OK")).base)
                try await channel.writeInbound(RESPToken(.simpleString("OK")).base)

                #expect(try await results.1.get().map { String(buffer: $0) } == "OK")

                #expect(tracer.spans.count == 1)
                let span = try #require(tracer.spans.first)
                #expect(span.operationName == "MULTI")
                #expect(span.kind == .client)
                #expect(span.recordedErrors.isEmpty)
                #expect(span.attributes == [
                    "db.system.name": "valkey",
                    "db.operation.name": "MULTI SET",
                    "db.operation.batch.size": 2,
                    "server.address": "127.0.0.1",
                    "network.peer.address": "127.0.0.1",
                    "network.peer.port": 6379
                ])
                #expect(span.recordedErrors.isEmpty)
                #expect(span.status == nil)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testPipelinedDifferentCommandsSpan() async throws {
            await #expect(processExitsWith: .success, "Running in a separate process because test uses bootstrap") {
                let tracer = TestTracer()
                InstrumentationSystem.bootstrapInternal(tracer)

                let channel = NIOAsyncTestingChannel()
                let logger = Logger(label: "test")
                let connection = try await ValkeyConnection.setupChannelAndConnect(channel, logger: logger)
                try await channel.processHello()

                async let results = connection.execute(
                    SET("foo", value: "bar"),
                    GET("foo"),
                )
                var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                let set = RESPToken(.command(["SET", "foo", "bar"])).base
                #expect(outbound.readSlice(length: set.readableBytes) == set)
                #expect(outbound == RESPToken(.command(["GET", "foo"])).base)
                try await channel.writeInbound(RESPToken(.simpleString("OK")).base)
                try await channel.writeInbound(RESPToken(.bulkString("bar")).base)

                #expect(try await results.1.get().map { String(buffer: $0) } == "bar")

                #expect(tracer.spans.count == 1)
                let span = try #require(tracer.spans.first)
                #expect(span.operationName == "MULTI")
                #expect(span.kind == .client)
                #expect(span.recordedErrors.isEmpty)
                #expect(span.attributes == [
                    "db.system.name": "valkey",
                    "db.operation.name": "MULTI",
                    "db.operation.batch.size": 2,
                    "server.address": "127.0.0.1",
                    "network.peer.address": "127.0.0.1",
                    "network.peer.port": 6379
                ])
                #expect(span.recordedErrors.isEmpty)
                #expect(span.status == nil)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testPipelinedCommandFailureSpan() async throws {
            await #expect(processExitsWith: .success, "Running in a separate process because test uses bootstrap") {
                let tracer = TestTracer()
                InstrumentationSystem.bootstrapInternal(tracer)

                let channel = NIOAsyncTestingChannel()
                let logger = Logger(label: "test")
                let connection = try await ValkeyConnection.setupChannelAndConnect(channel, logger: logger)
                try await channel.processHello()

                async let results = connection.execute(
                    SET("foo", value: "bar"),
                    GET("foo"),
                )
                _ = try await channel.waitForOutboundWrite(as: ByteBuffer.self)

                try await channel.writeInbound(RESPToken(.simpleString("OK")).base)
                try await channel.writeInbound(RESPToken(.simpleError("WRONGTYPE Error!")).base)
                _ = await results

                #expect(tracer.spans.count == 1)
                let span = try #require(tracer.spans.first)
                #expect(span.operationName == "MULTI")
                #expect(span.kind == .client)
                #expect(span.recordedErrors.count == 1)
                let error = try #require(span.recordedErrors.first)
                #expect(error.0 as? ValkeyClientError == ValkeyClientError(.commandError, message: "WRONGTYPE Error!"))
                #expect(span.attributes == [
                    "db.system.name": "valkey",
                    "db.operation.name": "MULTI",
                    "db.operation.batch.size": 2,
                    "server.address": "127.0.0.1",
                    "network.peer.address": "127.0.0.1",
                    "network.peer.port": 6379
                ])
                #expect(span.status == nil)
            }
        }
    }
    #endif
}
