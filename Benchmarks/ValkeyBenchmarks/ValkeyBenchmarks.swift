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

import Benchmark
import Logging
import NIOCore
import NIOPosix
import Valkey

let benchmarks: @Sendable () -> Void = {
    let defaultMetrics: [BenchmarkMetric] = [
        .wallClock,
        .cpuTotal,
        .mallocCountTotal,
        .throughput,
        .instructions,
    ]

    var server: Channel?
    Benchmark("GET benchmark", configuration: .init(metrics: defaultMetrics, scalingFactor: .kilo)) { benchmark in
        let port = server!.localAddress!.port!
        let logger = Logger(label: "test")
        let client = ValkeyClient(.hostname("127.0.0.1", port: port), logger: logger)

        try await client.withConnection(logger: logger) { connection in
            benchmark.startMeasurement()

            for _ in benchmark.scaledIterations {
                let foo = try await connection.get(key: "foo")
                precondition(foo == "Bar")
            }

            benchmark.stopMeasurement()
        }
    } setup: {
        server = try await ServerBootstrap(group: NIOSingletons.posixEventLoopGroup)
            .childChannelInitializer { channel in
                do {
                    try channel.pipeline.syncOperations.addHandler(ValkeyServerChannelHandler())
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

    Benchmark("RESPCommandEncoder", configuration: .init(metrics: defaultMetrics, scalingFactor: .kilo)) { benchmark in
        let string = "string"
        let optionalString: String? = "optionalString"
        let array = ["array", "of", "strings"]
        let number = 456
        let token = RESPPureToken("TOKEN", true)
        benchmark.startMeasurement()

        var encoder = RESPCommandEncoder()
        for _ in benchmark.scaledIterations {
            encoder.reset()
            encoder.encodeArray(string, optionalString, array, number, token)
        }

        benchmark.stopMeasurement()
    }
}

final class ValkeyServerChannelHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer

    private var decoder = NIOSingleStepByteToMessageProcessor(RESPTokenDecoder())
    private let response = ByteBuffer(string: "$3\r\nBar\r\n")

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
        switch iterator.next()?.value {
        case .bulkString(ByteBuffer(string: "HELLO")):
            let map = "%1\r\n+server\r\n+fake\r\n"
            context.writeAndFlush(self.wrapOutboundOut(ByteBuffer(string: map)), promise: nil)

        case .bulkString(ByteBuffer(string: "GET")):
            context.writeAndFlush(self.wrapOutboundOut(self.response), promise: nil)

        default:
            fatalError()
        }
    }
}
