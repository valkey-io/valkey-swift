//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 Apple Inc. and the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of valkey-swift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Benchmark
import Foundation
import Logging
import NIOCore
import NIOPosix
import Valkey

let benchmarks: @Sendable () -> Void = {
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

    var server: (any Channel)?

    if #available(valkeySwift 1.0, *) {
        Benchmark("GET benchmark", configuration: .init(metrics: defaultMetrics, scalingFactor: .kilo)) { benchmark in
            let port = server!.localAddress!.port!
            let logger = Logger(label: "test")
            let client = ValkeyClient(.hostname("127.0.0.1", port: port), logger: logger)

            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    await client.run()
                }
                await Task.yield()
                try await client.withConnection { connection in
                    benchmark.startMeasurement()

                    for _ in benchmark.scaledIterations {
                        let foo = try await connection.get(key: "foo")?.decode(as: String.self)
                        precondition(foo == "Bar")
                    }

                    benchmark.stopMeasurement()
                }
                group.cancelAll()
            }
        } setup: {
            struct GetHandler: BenchmarkCommandHandler {
                static let expectedCommand = RESPToken.Value.bulkString(ByteBuffer(string: "GET"))
                static let response = ByteBuffer(string: "$3\r\nBar\r\n")
                func handle(command: RESPToken.Value, parameters: RESPToken.Array.Iterator, write: (ByteBuffer) -> Void) {
                    switch command {
                    case Self.expectedCommand:
                        write(Self.response)
                    default:
                        fatalError()
                    }
                }
            }
            server = try await ServerBootstrap(group: NIOSingletons.posixEventLoopGroup)
                .childChannelInitializer { channel in
                    do {
                        try channel.pipeline.syncOperations.addHandler(
                            ValkeyServerChannelHandler(commandHandler: GetHandler())
                        )
                        return channel.eventLoop.makeSucceededVoidFuture()
                    } catch {
                        return channel.eventLoop.makeFailedFuture(error)
                    }
                }
                .bind(host: "127.0.0.1", port: 0)
                .get()
        } teardown: {
            try await server?.close().get()
        }

        Benchmark("ValkeyCommandEncoder – Simple GET", configuration: .init(metrics: defaultMetrics, scalingFactor: .kilo)) { benchmark in
            let command = GET(key: "foo")
            benchmark.startMeasurement()

            var encoder = ValkeyCommandEncoder()
            for _ in benchmark.scaledIterations {
                encoder.reset()
                command.encode(into: &encoder)
            }

            benchmark.stopMeasurement()
        }

        Benchmark("ValkeyCommandEncoder – Simple MGET 15 keys", configuration: .init(metrics: defaultMetrics, scalingFactor: .kilo)) { benchmark in
            let keys = (0..<15).map { ValkeyKey(rawValue: "foo-\($0)") }
            let command = MGET(key: keys)
            benchmark.startMeasurement()

            var encoder = ValkeyCommandEncoder()
            for _ in benchmark.scaledIterations {
                encoder.reset()
                command.encode(into: &encoder)
            }

            benchmark.stopMeasurement()
        }

        Benchmark("ValkeyCommandEncoder – Command with 7 words", configuration: .init(metrics: defaultMetrics, scalingFactor: .kilo)) { benchmark in
            let string = "string"
            let optionalString: String? = "optionalString"
            let array = ["array", "of", "strings"]
            let number = 456
            let token = RESPPureToken("TOKEN", true)
            benchmark.startMeasurement()

            var encoder = ValkeyCommandEncoder()
            for _ in benchmark.scaledIterations {
                encoder.reset()
                encoder.encodeArray(string, optionalString, array, number, token)
            }

            benchmark.stopMeasurement()
        }

        Benchmark("HashSlot – {user}.whatever", configuration: .init(metrics: defaultMetrics, scalingFactor: .mega)) { benchmark in
            let key = "{user}.whatever"

            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                blackHole(HashSlot(key: key))
            }
        }
    }
}

protocol BenchmarkCommandHandler {
    func handle(command: RESPToken.Value, parameters: RESPToken.Array.Iterator, write: (ByteBuffer) -> Void)
}

final class ValkeyServerChannelHandler<Handler: BenchmarkCommandHandler>: ChannelInboundHandler {

    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer

    private var decoder = NIOSingleStepByteToMessageProcessor(RESPTokenDecoder())
    private let helloCommand = RESPToken.Value.bulkString(ByteBuffer(string: "HELLO"))
    private let helloResponse = ByteBuffer(string: "%1\r\n+server\r\n+fake\r\n")
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

        default:
            commandHandler.handle(command: command, parameters: iterator) {
                context.writeAndFlush(self.wrapOutboundOut($0), promise: nil)
            }
        }
    }
}
