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
import Testing
import Valkey

/// Mock multiple servers
actor MockServerConnections {
    enum Error: Swift.Error {
        case connectionUnavailable
    }
    let eventLoop: NIOAsyncTestingEventLoop
    var servers: [ValkeyServerAddress: @Sendable (NIOAsyncTestingChannel) async throws -> Void]
    let (connectionStream, connectionCont) = AsyncStream.makeStream(
        of: (channel: NIOAsyncTestingChannel, server: @Sendable (NIOAsyncTestingChannel) async throws -> Void).self
    )

    init() {
        self.eventLoop = NIOAsyncTestingEventLoop()
        self.servers = [:]
    }

    func addServer(_ address: ValkeyServerAddress, serve: @escaping @Sendable (NIOAsyncTestingChannel) async throws -> Void) {
        self.servers[address] = serve
    }

    func addValkeyServer(_ address: ValkeyServerAddress, processCommand: @escaping @Sendable ([String]) throws -> RESPToken?) {
        self.addServer(address) { channel in
            await withThrowingTaskGroup { group in
                let (outputStream, outputCont) = AsyncStream.makeStream(of: RESPToken.self)

                group.addTask {
                    for try await output in outputStream {
                        try await channel.writeInbound(output.base)
                    }
                }
                let decoder = NIOSingleStepByteToMessageProcessor(RESPTokenDecoder())
                do {
                    while true {
                        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                        try decoder.process(buffer: outbound) { token in
                            let command = try token.decode(as: [String].self)
                            if let response = try processCommand(command) {
                                outputCont.yield(response)
                            } else {
                                var iterator = command.makeIterator()
                                switch (iterator.next(), iterator.next()) {
                                case ("HELLO", _):
                                    outputCont.yield(
                                        RESPToken(
                                            .map([
                                                .bulkString("server"): .bulkString("mock"),
                                                .bulkString("version"): .bulkString("9.0.2"),
                                                .bulkString("proto"): .number(3),
                                                .bulkString("id"): .number(5),
                                                //.bulkString("mode"): .bulkString("standalone"),
                                                //.bulkString("role"): .bulkString("master"),
                                                .bulkString("modules"): .array([]),
                                                .bulkString("availability_zone"): .bulkString("us-east-1"),
                                            ])
                                        )
                                    )
                                case ("CLIENT", "SETINFO"), ("CLIENT", "CAPA"):
                                    outputCont.yield(.ok)
                                case ("READONLY", _):
                                    outputCont.yield(.ok)
                                case ("PING", _):
                                    outputCont.yield(RESPToken(.simpleString("PONG")))
                                default:
                                    outputCont.yield(RESPToken(.bulkError("ERR unrecognised command")))
                                }
                            }
                        }
                    }
                } catch {
                    // Ignore I/O on closed channel error
                }
            }
        }
    }

    func connectionManagerCustomHandler(_ address: ValkeyServerAddress, eventLoop: EventLoop) async throws -> Channel {
        guard let server = servers[address] else { throw Error.connectionUnavailable }
        let channel = NIOAsyncTestingChannel(loop: self.eventLoop)
        return try await channel.connect(to: try SocketAddress(ipAddress: "127.0.0.1", port: 6379)).map {
            self.connectionCont.yield((channel, server))
            return channel
        }.get()
    }

    func run() async throws {
        try await withThrowingTaskGroup { group in
            for await connection in connectionStream {
                group.addTask {
                    try await connection.server(connection.channel)
                }
            }
            try await group.waitForAll()
        }
    }
}
