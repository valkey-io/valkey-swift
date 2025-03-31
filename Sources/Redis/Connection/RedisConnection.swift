//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-redis project
//
// Copyright (c) 2024 the swift-redis authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See swift-redis/CONTRIBUTORS.txt for the list of swift-redis authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Logging
import NIOCore
import NIOPosix
import NIOSSL

#if canImport(Network)
import Network
import NIOTransportServices
#endif

/// Server address to connect to
public struct ServerAddress: Sendable, Equatable {
    enum _Internal: Equatable {
        case hostname(_ host: String, port: Int)
        case unixDomainSocket(path: String)
    }

    let value: _Internal
    init(_ value: _Internal) {
        self.value = value
    }

    // Address define by host and port
    public static func hostname(_ host: String, port: Int) -> Self { .init(.hostname(host, port: port)) }
    // Address defined by unxi domain socket
    public static func unixDomainSocket(path: String) -> Self { .init(.unixDomainSocket(path: path)) }
}

/// Single connection to a Redis database
@_documentation(visibility: internal)
public struct RedisConnection: Sendable {
    enum Request {
        case command(RESPCommand)
        case pipelinedCommands([RESPCommand])
    }
    enum Response {
        case token(RESPToken)
        case pipelinedResponse([RESPToken])
    }
    typealias RequestStreamElement = (Request, CheckedContinuation<Response, Error>)
    /// Logger used by Server
    let logger: Logger
    let eventLoopGroup: EventLoopGroup
    let configuration: RedisClientConfiguration
    let address: ServerAddress
    #if canImport(Network)
    let tlsOptions: NWProtocolTLS.Options?
    #endif

    let requestStream: AsyncStream<RequestStreamElement>
    let requestContinuation: AsyncStream<RequestStreamElement>.Continuation

    /// Initialize Client
    public init(
        address: ServerAddress,
        configuration: RedisClientConfiguration,
        eventLoopGroup: EventLoopGroup = MultiThreadedEventLoopGroup.singleton,
        logger: Logger
    ) {
        self.address = address
        self.configuration = configuration
        self.eventLoopGroup = eventLoopGroup
        self.logger = logger
        #if canImport(Network)
        self.tlsOptions = nil
        #endif
        (self.requestStream, self.requestContinuation) = AsyncStream.makeStream(of: RequestStreamElement.self)
    }

    public func run() async throws {
        let asyncChannel = try await self.makeClient(
            address: self.address
        )
        do {
            try await withTaskCancellationHandler {
                try await asyncChannel.executeThenClose { inbound, outbound in
                    var inboundIterator = inbound.makeAsyncIterator()
                    if self.configuration.respVersion == .v3 {
                        try await resp3Upgrade(outbound: outbound, inboundIterator: &inboundIterator)
                    }
                    for await (request, continuation) in requestStream {
                        do {
                            switch request {
                            case .command(let command):
                                try await outbound.write(command.buffer)
                                let response = try await inboundIterator.next()
                                if let response {
                                    continuation.resume(returning: .token(response))
                                } else {
                                    requestContinuation.finish()
                                    continuation.resume(
                                        throwing: RedisClientError(
                                            .connectionClosed,
                                            message: "The connection to the Redis database was unexpectedly closed."
                                        )
                                    )
                                }
                            case .pipelinedCommands(let commands):
                                try await outbound.write(contentsOf: commands.map { $0.buffer })
                                var responses: [RESPToken] = .init()
                                for _ in 0..<commands.count {
                                    let response = try await inboundIterator.next()
                                    if let response {
                                        responses.append(response)
                                    } else {
                                        requestContinuation.finish()
                                        continuation.resume(
                                            throwing: RedisClientError(
                                                .connectionClosed,
                                                message: "The connection to the Redis database was unexpectedly closed."
                                            )
                                        )
                                        return
                                    }
                                }
                                continuation.resume(returning: .pipelinedResponse(responses))
                            }
                        } catch {
                            requestContinuation.finish()
                            continuation.resume(
                                throwing: RedisClientError(
                                    .connectionClosed,
                                    message: "The connection to the Redis database has shut down while processing a request."
                                )
                            )
                        }
                    }
                }
            } onCancel: {
                asyncChannel.channel.close(mode: .input, promise: nil)
            }
        } catch {
            requestContinuation.finish()
            for await (_, continuation) in requestStream {
                continuation.resume(
                    throwing: error
                )
            }
        }
    }

    @discardableResult public func send(command: RESPCommand) async throws -> RESPToken {
        if logger.logLevel <= .debug {
            var buffer = command.buffer
            let sending = try [String](from: RESPToken(consuming: &buffer)!).joined(separator: " ")
            self.logger.debug("send: \(sending)")
        }
        let response: Response = try await withCheckedThrowingContinuation { continuation in
            switch requestContinuation.yield((.command(command), continuation)) {
            case .enqueued:
                break
            case .dropped, .terminated:
                continuation.resume(
                    throwing: RedisClientError(
                        .connectionClosed,
                        message: "Unable to enqueue request due to the connection being shutdown."
                    )
                )
            default:
                break
            }
        }
        guard case .token(let token) = response else { preconditionFailure("Expected a single response") }
        return token
    }

    @discardableResult public func pipeline(_ commands: [RESPCommand]) async throws -> [RESPToken] {
        let response: Response = try await withCheckedThrowingContinuation { continuation in
            switch requestContinuation.yield((.pipelinedCommands(commands), continuation)) {
            case .enqueued:
                break
            case .dropped, .terminated:
                continuation.resume(
                    throwing: RedisClientError(
                        .connectionClosed,
                        message: "Unable to enqueue request due to the connection being shutdown."
                    )
                )
            default:
                break
            }
        }
        guard case .pipelinedResponse(let tokens) = response else { preconditionFailure("Expected a single response") }
        return tokens
    }

    @discardableResult public func send<each Arg: RESPRenderable>(_ command: repeat each Arg) async throws -> RESPToken {
        let command = RESPCommand(repeat each command)
        return try await self.send(command: command)
    }

    /// Try to upgrade to RESP3
    private func resp3Upgrade(
        outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>,
        inboundIterator: inout NIOAsyncChannelInboundStream<RESPToken>.AsyncIterator
    ) async throws {
        let helloCommand = RESPCommand("HELLO", "3")
        try await outbound.write(helloCommand.buffer)
        let response = try await inboundIterator.next()
        guard let response else {
            throw RedisClientError(.connectionClosed, message: "The connection to the Redis database was unexpectedly closed.")
        }
        // if returned value is an error then throw that error
        if let value = response.errorString {
            throw RedisClientError(.commandError, message: String(buffer: value))
        }
    }

    /// Connect to server
    private func makeClient(address: ServerAddress) async throws -> NIOAsyncChannel<RESPToken, ByteBuffer> {
        // get bootstrap
        let bootstrap: ClientBootstrapProtocol
        #if canImport(Network)
        if let tsBootstrap = self.createTSBootstrap() {
            bootstrap = tsBootstrap
        } else {
            #if os(iOS) || os(tvOS)
            self.logger.warning(
                "Running BSD sockets on iOS or tvOS is not recommended. Please use NIOTSEventLoopGroup, to run with the Network framework"
            )
            #endif
            bootstrap = self.createSocketsBootstrap()
        }
        #else
        bootstrap = self.createSocketsBootstrap()
        #endif

        // connect
        let result: NIOAsyncChannel<RESPToken, ByteBuffer>
        do {
            switch address.value {
            case .hostname(let host, let port):
                result =
                    try await bootstrap
                    .connect(host: host, port: port) { channel in
                        setupChannel(channel)
                    }
                self.logger.debug("Client connnected to \(host):\(port)")
            case .unixDomainSocket(let path):
                result =
                    try await bootstrap
                    .connect(unixDomainSocketPath: path) { channel in
                        setupChannel(channel)
                    }
                self.logger.debug("Client connnected to socket path \(path)")
            }
            return result
        } catch {
            throw error
        }
    }

    private func setupChannel(_ channel: Channel) -> EventLoopFuture<NIOAsyncChannel<RESPToken, ByteBuffer>> {
        channel.eventLoop.makeCompletedFuture {
            if case .enable(let sslContext, let tlsServerName) = self.configuration.tls.base {
                try channel.pipeline.syncOperations.addHandler(NIOSSLClientHandler(context: sslContext, serverHostname: tlsServerName))
            }
            try channel.pipeline.syncOperations.addHandler(ByteToMessageHandler(RESPTokenDecoder()))
            return try NIOAsyncChannel<RESPToken, ByteBuffer>(
                wrappingChannelSynchronously: channel,
                configuration: .init()
            )
        }
    }

    /// create a BSD sockets based bootstrap
    private func createSocketsBootstrap() -> ClientBootstrap {
        ClientBootstrap(group: self.eventLoopGroup)
            .channelOption(ChannelOptions.allowRemoteHalfClosure, value: true)
    }

    #if canImport(Network)
    /// create a NIOTransportServices bootstrap using Network.framework
    private func createTSBootstrap() -> NIOTSConnectionBootstrap? {
        guard
            let bootstrap = NIOTSConnectionBootstrap(validatingGroup: self.eventLoopGroup)?
                .channelOption(ChannelOptions.allowRemoteHalfClosure, value: true)
        else {
            return nil
        }
        if let tlsOptions {
            return bootstrap.tlsOptions(tlsOptions)
        }
        return bootstrap
    }
    #endif
}

protocol ClientBootstrapProtocol {
    func connect<Output: Sendable>(
        host: String,
        port: Int,
        channelInitializer: @escaping @Sendable (Channel) -> EventLoopFuture<Output>
    ) async throws -> Output

    func connect<Output: Sendable>(
        unixDomainSocketPath: String,
        channelInitializer: @escaping @Sendable (Channel) -> EventLoopFuture<Output>
    ) async throws -> Output
}

extension ClientBootstrap: ClientBootstrapProtocol {}
#if canImport(Network)
extension NIOTSConnectionBootstrap: ClientBootstrapProtocol {}
#endif
