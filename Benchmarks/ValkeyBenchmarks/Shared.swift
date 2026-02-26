//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import Benchmark
import Foundation
import NIOCore
import NIOPosix
import Valkey

let defaultMetrics: [BenchmarkMetric] =
    // There is no point comparing wallClock, cpuTotal or throughput on CI as they are too inconsistent
    ProcessInfo.processInfo.environment["CI"] != nil
    ? [
        .instructions,
        .mallocCountTotal,
    ]
    : [
        .wallClock,
        .cpuTotal,
        .instructions,
        .mallocCountTotal,
        .throughput,
    ]

struct BenchmarkGetHandler: BenchmarkCommandHandler {
    static let expectedCommand = RESPToken.Value.bulkString(ByteBuffer(string: "GET"))
    static let response = ByteBuffer(string: "$3\r\nBar\r\n")
    func handle(command: RESPToken.Value, parameters: RESPToken.Array.Iterator, write: (ByteBuffer) -> Void) {
        switch command {
        case Self.expectedCommand:
            write(Self.response)
        case .bulkString(let string):
            fatalError("Unexpected command: \(String(buffer: string))")
        default:
            fatalError("Unexpected value: \(command)")
        }
    }
}
func makeLocalServer(commandHandler: some BenchmarkCommandHandler = BenchmarkGetHandler()) async throws -> any Channel {
    try await ServerBootstrap(group: NIOSingletons.posixEventLoopGroup)
        .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)
        .childChannelInitializer { channel in
            channel.eventLoop.makeCompletedFuture {
                try channel.pipeline.syncOperations.addHandler(
                    ValkeyServerChannelHandler(commandHandler: commandHandler)
                )
            }
        }
        .bind(host: "127.0.0.1", port: 0)
        .get()
}

protocol BenchmarkCommandHandler: Sendable {
    func handle(command: RESPToken.Value, parameters: RESPToken.Array.Iterator, write: (ByteBuffer) -> Void)
}

final class ValkeyServerChannelHandler<Handler: BenchmarkCommandHandler>: ChannelInboundHandler {

    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer

    private var decoder = NIOSingleStepByteToMessageProcessor(RESPTokenDecoder())
    private let helloCommand = RESPToken.Value.bulkString(ByteBuffer(string: "HELLO"))
    private let helloResponse = ByteBuffer(string: "%1\r\n+server\r\n+fake\r\n")
    private let pingCommand = RESPToken.Value.bulkString(ByteBuffer(string: "PING"))
    private let pongResponse = ByteBuffer(string: "$4\r\nPONG\r\n")
    private let clientCommand = RESPToken.Value.bulkString(ByteBuffer(string: "CLIENT"))
    private let setInfoSubCommand = RESPToken.Value.bulkString(ByteBuffer(string: "SETINFO"))
    private let clientCapaSubCommand = RESPToken.Value.bulkString(ByteBuffer(string: "CAPA"))
    private let okResponse = ByteBuffer(string: "+2OK\r\n")
    private let commandHandler: Handler

    init(commandHandler: Handler) {
        self.commandHandler = commandHandler
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        try! self.decoder.process(buffer: self.unwrapInboundIn(data)) { token in
            self.handleToken(context: context, token: token)
        }
    }

    func handleToken(context: ChannelHandlerContext, token: RESPToken) {
        guard case .array(let array) = token.value else {
            fatalError()
        }
        var iterator = array.makeIterator()
        guard let command = iterator.next()?.value else {
            fatalError()
        }
        switch command {
        case helloCommand:
            context.writeAndFlush(self.wrapOutboundOut(helloResponse), promise: nil)

        case pingCommand:
            context.writeAndFlush(self.wrapOutboundOut(pongResponse), promise: nil)

        case clientCommand:
            var subCommandIterator = iterator
            switch subCommandIterator.next()?.value {
            case setInfoSubCommand:
                context.writeAndFlush(self.wrapOutboundOut(okResponse), promise: nil)
            case clientCapaSubCommand:
                context.writeAndFlush(self.wrapOutboundOut(okResponse), promise: nil)
            default:
                commandHandler.handle(command: command, parameters: iterator) {
                    context.writeAndFlush(self.wrapOutboundOut($0), promise: nil)
                }
            }

        default:
            commandHandler.handle(command: command, parameters: iterator) {
                context.writeAndFlush(self.wrapOutboundOut($0), promise: nil)
            }
        }
    }
}
