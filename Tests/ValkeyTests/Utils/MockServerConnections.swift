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
    struct ConnectionRequest {
        let requestID: Int
        let channel: NIOAsyncTestingChannel
        let server: @Sendable (NIOAsyncTestingChannel) async throws -> Void
        let address: ValkeyServerAddress
    }
    var globalID = 0
    let logger: Logger
    let eventLoop: NIOAsyncTestingEventLoop
    var servers: [ValkeyServerAddress: @Sendable (NIOAsyncTestingChannel) async throws -> Void]
    var serverInstances: [Int: ConnectionRequest]
    let (connectionStream, connectionCont) = AsyncStream.makeStream(of: ConnectionRequest.self)

    init(logger: Logger) {
        self.logger = logger
        self.eventLoop = NIOAsyncTestingEventLoop()
        self.servers = [:]
        self.serverInstances = [:]
    }

    func addServer(_ address: ValkeyServerAddress, serve: @escaping @Sendable (NIOAsyncTestingChannel) async throws -> Void) {
        self.servers[address] = serve
    }

    func shutdownServer(_ address: ValkeyServerAddress) async {
        self.servers[address] = nil
        for instance in self.serverInstances.values {
            if instance.address == address {
                try? await instance.channel.close()
            }
        }
    }

    func addValkeyServer(_ address: ValkeyServerAddress, processCommand: @escaping @Sendable ([String]) async throws -> RESP3Value?) {
        self.addServer(address) { channel in
            try await withThrowingTaskGroup { group in
                let (outputStream, outputCont) = AsyncStream.makeStream(of: RESPToken.self)
                let (commandStream, commandCont) = AsyncStream.makeStream(of: [String].self)

                group.addTask {
                    for try await output in outputStream {
                        try await channel.writeInbound(output.base)
                    }
                }
                group.addTask {
                    var logger = self.logger
                    logger[metadataKey: "server"] = .stringConvertible(address)
                    for try await command in commandStream {
                        logger.debug("Command", metadata: ["command": .array(command.map { .string($0) })])
                        if let response = try await processCommand(command) {
                            outputCont.yield(RESPToken(response))
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
                    outputCont.finish()
                }
                let decoder = NIOSingleStepByteToMessageProcessor(RESPTokenDecoder())
                do {
                    while channel.isActive {
                        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                        try decoder.process(buffer: outbound) { token in
                            let command = try token.decode(as: [String].self)
                            commandCont.yield(command)
                        }
                        try await Task.sleep(for: .milliseconds(100))
                    }
                } catch ChannelError.ioOnClosedChannel {
                    // Ignore I/O on closed channel error
                }
                commandCont.finish()
            }
        }
    }

    func connectionManagerCustomHandler(_ address: ValkeyServerAddress, eventLoop: any EventLoop) async throws -> any Channel {
        guard let server = servers[address] else { throw Error.connectionUnavailable }
        let channel = NIOAsyncTestingChannel(loop: self.eventLoop)
        let request = ConnectionRequest(requestID: self.globalID, channel: channel, server: server, address: address)
        self.globalID += 1
        self.serverInstances[request.requestID] = request
        return try await channel.connect(to: try SocketAddress(ipAddress: "127.0.0.1", port: 6379)).map {
            self.connectionCont.yield(request)
            return channel
        }.get()
    }

    func clearServerInstance(_ id: Int) {
        self.serverInstances[id] = nil
    }

    func run() async throws {
        try await withThrowingTaskGroup { group in
            for await request in connectionStream {
                group.addTask {
                    do {
                        try await request.server(request.channel)
                        await self.clearServerInstance(request.requestID)
                    } catch {
                        await self.clearServerInstance(request.requestID)
                        throw error
                    }
                }
            }
            try await group.waitForAll()
        }
    }
}
