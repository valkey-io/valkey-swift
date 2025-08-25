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

import NIOCore
import Valkey

// Fake Valkey server channel handler
final class TestValkeyServerChannelHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer

    private var decoder = NIOSingleStepByteToMessageProcessor(RESPTokenDecoder())
    private let commandHandler: (String, ArraySlice<String>, (ByteBuffer) -> Void) -> Void

    static private let helloCommand = RESPToken.Value.bulkString(ByteBuffer(string: "HELLO"))
    static private let helloResponse = ByteBuffer(string: "%1\r\n+server\r\n+fake\r\n")
    static private let pingCommand = RESPToken.Value.bulkString(ByteBuffer(string: "PING"))
    static private let pongResponse = ByteBuffer(string: "$4\r\nPONG\r\n")
    static private let clientCommand = RESPToken.Value.bulkString(ByteBuffer(string: "CLIENT"))
    static private let setInfoSubCommand = RESPToken.Value.bulkString(ByteBuffer(string: "SETINFO"))
    static private let okResponse = ByteBuffer(string: "+2OK\r\n")

    static private let response = ByteBuffer(string: "$3\r\nBar\r\n")
    static func defaultHandler(command: String, parameters: ArraySlice<String>, write: (ByteBuffer) -> Void) {
        guard command == "GET" else {
            fatalError("Unexpected command: \(command)")
        }
        write(Self.response)
    }

    init(commandHandler: @escaping (String, ArraySlice<String>, (ByteBuffer) -> Void) -> Void = defaultHandler) {
        self.commandHandler = commandHandler
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        try! self.decoder.process(buffer: self.unwrapInboundIn(data)) { token in
            self.handleToken(context: context, token: token)
        }
    }

    func handleToken(context: ChannelHandlerContext, token: RESPToken) {
        guard let fullCommand = try? token.decode(as: [String].self) else {
            fatalError()
        }
        guard let command = fullCommand.first else {
            fatalError()
        }
        let parameters = fullCommand.dropFirst()
        switch command {
        case "HELLO":
            context.writeAndFlush(self.wrapOutboundOut(Self.helloResponse), promise: nil)

        case "PING":
            context.writeAndFlush(self.wrapOutboundOut(Self.pongResponse), promise: nil)

        case "CLIENT":
            switch parameters.first {
            case "SETINFO":
                context.writeAndFlush(self.wrapOutboundOut(Self.okResponse), promise: nil)
            default:
                commandHandler(command, parameters) {
                    context.writeAndFlush(self.wrapOutboundOut($0), promise: nil)
                }
            }

        default:
            commandHandler(command, parameters) {
                context.writeAndFlush(self.wrapOutboundOut($0), promise: nil)
            }
        }
    }
}
