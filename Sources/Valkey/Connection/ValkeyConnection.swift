//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey project
//
// Copyright (c) 2024 the swift-valkey authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See swift-valkey/CONTRIBUTORS.txt for the list of swift-valkey authors
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

/// Single connection to a Valkey database
public struct ValkeyConnection: Sendable {
    /// Logger used by Server
    let logger: Logger
    let channel: Channel
    let configuration: ValkeyClientConfiguration

    /// Initialize Client
    private init(
        channel: Channel,
        configuration: ValkeyClientConfiguration,
        logger: Logger
    ) {
        self.channel = channel
        self.configuration = configuration
        self.logger = logger
    }

    public static func connect(
        address: ServerAddress,
        configuration: ValkeyClientConfiguration,
        eventLoopGroup: EventLoopGroup = MultiThreadedEventLoopGroup.singleton,
        logger: Logger
    ) async throws -> Self {
        let channel = try await makeClient(address: address, eventLoopGroup: eventLoopGroup, configuration: configuration, logger: logger)
        return .init(channel: channel, configuration: configuration, logger: logger)
    }

    @discardableResult public func send<Command: RESPCommand>(command: Command) async throws -> Command.Response {
        var encoder = RESPCommandEncoder()
        command.encode(into: &encoder)

        let promise = channel.eventLoop.makePromise(of: RESPToken.self)
        channel.writeAndFlush(ValkeyRequest(buffer: encoder.buffer, promise: promise), promise: nil)
        return try await .init(from: promise.futureResult.get())
    }
    /*
    @discardableResult public func pipeline<each Command: RESPCommand>(
        _ commands: repeat each Command
    ) async throws -> (repeat (each Command).Response) {
        var count = 0
        var encoder = RESPCommandEncoder()
        for command in repeat each commands {
            command.encode(into: &encoder)
            count += 1
        }

        let response: Response = try await withCheckedThrowingContinuation { continuation in
            switch requestContinuation.yield((.pipelinedCommands(encoder.buffer, count), continuation)) {
            case .enqueued:
                break
            case .dropped, .terminated:
                continuation.resume(
                    throwing: ValkeyClientError(
                        .connectionClosed,
                        message: "Unable to enqueue request due to the connection being shutdown."
                    )
                )
            default:
                break
            }
        }
        guard case .pipelinedResponse(let tokens) = response else { preconditionFailure("Expected a single response") }

        var index = AutoIncrementingInteger()
        return try (repeat (each Command).Response(from: tokens[index.next()].get()))
    }*/

    /// Try to upgrade to RESP3
    private func resp3Upgrade(
        outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>,
        inboundIterator: inout NIOAsyncChannelInboundStream<RESPToken>.AsyncIterator
    ) async throws {
        var encoder = RESPCommandEncoder()
        encoder.encodeArray("HELLO", 3)
        try await outbound.write(encoder.buffer)
        let response = try await inboundIterator.next()
        guard let response else {
            throw ValkeyClientError(.connectionClosed, message: "The connection to the database was unexpectedly closed.")
        }
        // if returned value is an error then throw that error
        if let value = response.errorString {
            throw ValkeyClientError(.commandError, message: String(buffer: value))
        }
    }

    /// Connect to server
    private static func makeClient(
        address: ServerAddress,
        eventLoopGroup: EventLoopGroup,
        configuration: ValkeyClientConfiguration,
        logger: Logger
    ) async throws -> Channel {
        // get bootstrap
        let bootstrap: ClientBootstrapProtocol
        #if canImport(Network)
        if let tsBootstrap = createTSBootstrap(eventLoopGroup: eventLoopGroup, tlsOptions: nil) {
            bootstrap = tsBootstrap
        } else {
            #if os(iOS) || os(tvOS)
            self.logger.warning(
                "Running BSD sockets on iOS or tvOS is not recommended. Please use NIOTSEventLoopGroup, to run with the Network framework"
            )
            #endif
            bootstrap = self.createSocketsBootstrap(eventLoopGroup: eventLoopGroup)
        }
        #else
        bootstrap = self.createSocketsBootstrap(eventLoopGroup: eventLoopGroup)
        #endif

        // connect
        let channel: Channel
        do {
            switch address.value {
            case .hostname(let host, let port):
                channel =
                    try await bootstrap
                    .connect(host: host, port: port) { channel in
                        setupChannel(channel, configuration: configuration)
                    }
                logger.debug("Client connnected to \(host):\(port)")
            case .unixDomainSocket(let path):
                channel =
                    try await bootstrap
                    .connect(unixDomainSocketPath: path) { channel in
                        setupChannel(channel, configuration: configuration)
                    }
                logger.debug("Client connnected to socket path \(path)")
            }
            return channel
        } catch {
            throw error
        }
    }

    private static func setupChannel(_ channel: Channel, configuration: ValkeyClientConfiguration) -> EventLoopFuture<Channel> {
        channel.eventLoop.makeCompletedFuture {
            if case .enable(let sslContext, let tlsServerName) = configuration.tls.base {
                try channel.pipeline.syncOperations.addHandler(NIOSSLClientHandler(context: sslContext, serverHostname: tlsServerName))
            }
            try channel.pipeline.syncOperations.addHandlers(
                [
                    ByteToMessageHandler(RESPTokenDecoder()),
                    ValkeyCommandHandler(),
                ]
            )
            return channel
        }
    }

    /// create a BSD sockets based bootstrap
    private static func createSocketsBootstrap(eventLoopGroup: EventLoopGroup) -> ClientBootstrap {
        ClientBootstrap(group: eventLoopGroup)
            .channelOption(ChannelOptions.allowRemoteHalfClosure, value: true)
    }

    #if canImport(Network)
    /// create a NIOTransportServices bootstrap using Network.framework
    private static func createTSBootstrap(eventLoopGroup: EventLoopGroup, tlsOptions: NWProtocolTLS.Options?) -> NIOTSConnectionBootstrap? {
        guard
            let bootstrap = NIOTSConnectionBootstrap(validatingGroup: eventLoopGroup)?
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

private struct AutoIncrementingInteger {
    var value: Int = 0
    mutating func next() -> Int {
        value += 1
        return value - 1
    }
}
