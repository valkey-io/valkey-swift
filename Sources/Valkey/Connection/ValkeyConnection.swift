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
import Synchronization

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
public final class ValkeyConnection: Sendable {
    /// Logger used by Server
    let logger: Logger
    @usableFromInline
    let channel: Channel
    @usableFromInline
    let channelHandler: ValkeyChannelHandler
    let configuration: ValkeyClientConfiguration
    let isClosed: Atomic<Bool>

    /// Initialize connection
    private init(
        channel: Channel,
        channelHandler: ValkeyChannelHandler,
        configuration: ValkeyClientConfiguration,
        logger: Logger
    ) {
        self.channel = channel
        self.channelHandler = channelHandler
        self.configuration = configuration
        self.logger = logger
        self.isClosed = .init(false)
    }

    /// Connect to Valkey database and return connection
    ///
    /// - Parameters:
    ///   - address: Internet address of database
    ///   - configuration: Configuration of Valkey connection
    ///   - eventLoopGroup: EventLoopGroup to use
    ///   - logger: Logger for connection
    /// - Returns: ValkeyConnection
    public static func connect(
        address: ServerAddress,
        configuration: ValkeyClientConfiguration,
        eventLoopGroup: EventLoopGroup = MultiThreadedEventLoopGroup.singleton,
        logger: Logger
    ) async throws -> ValkeyConnection {
        let (channel, channelHandler) = try await makeClient(
            address: address,
            eventLoopGroup: eventLoopGroup,
            configuration: configuration,
            logger: logger
        )
        let connection = ValkeyConnection(channel: channel, channelHandler: channelHandler, configuration: configuration, logger: logger)
        try await connection.resp3Upgrade()
        return connection
    }

    /// Close connection
    /// - Returns: EventLoopFuture that is completed on connection closure
    public func close() -> EventLoopFuture<Void> {
        guard self.isClosed.compareExchange(expected: false, desired: true, successOrdering: .relaxed, failureOrdering: .relaxed).exchanged else {
            return channel.eventLoop.makeSucceededVoidFuture()
        }
        self.channel.close(mode: .all, promise: nil)
        return self.channel.closeFuture
    }

    /// Send RESP command to Valkey connection
    /// - Parameter command: RESPCommand structure
    /// - Returns: The command response as defined in the RESPCommand 
    
    @inlinable
    public func send<Command: RESPCommand>(command: Command) async throws -> Command.Response {
        var encoder = RESPCommandEncoder()
        command.encode(into: &encoder)

        let promise = channel.eventLoop.makePromise(of: RESPToken.self)
        channelHandler.write(request: ValkeyRequest.single(buffer: encoder.buffer, promise: promise))
        return try await .init(from: promise.futureResult.get())
    }

    /// Pipeline a series of commands to Valkey connection
    /// 
    /// This function will only return once it has the results of all the commands sent
    /// - Parameter commands: Parameter pack of RESPCommands
    /// - Returns: Parameter pack holding the responses of all the commands
    @inlinable
    public func pipeline<each Command: RESPCommand>(
        _ commands: repeat each Command
    ) async throws -> (repeat (each Command).Response) {
        // this currently allocates a promise for every command. We could collpase this down to one promise
        var promises: [EventLoopPromise<RESPToken>] = []
        var encoder = RESPCommandEncoder()
        for command in repeat each commands {
            command.encode(into: &encoder)
            promises.append(channel.eventLoop.makePromise(of: RESPToken.self))
        }
        // write directly to channel handler
        channelHandler.write(request: ValkeyRequest.multiple(buffer: encoder.buffer, promises: promises))
        // get response from channel handler
        var index = AutoIncrementingInteger()
        return try await (repeat (each Command).Response(from: promises[index.next()].futureResult.get()))
    }

    /// Try to upgrade to RESP3
    private func resp3Upgrade() async throws {
        _ = try await send(command: HELLO(arguments: .init(protover: 3, auth: nil, clientname: nil)))
    }

    /// Create Valkey connection and return channel connection is running on and the Valkey channel handler
    private static func makeClient(
        address: ServerAddress,
        eventLoopGroup: EventLoopGroup,
        configuration: ValkeyClientConfiguration,
        logger: Logger
    ) async throws -> (Channel, ValkeyChannelHandler) {
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
        let channelHandler: ValkeyChannelHandler
        do {
            switch address.value {
            case .hostname(let host, let port):
                (channel, channelHandler) =
                    try await bootstrap
                    .connect(host: host, port: port) { channel in
                        setupChannel(channel, configuration: configuration, logger: logger)
                    }
                logger.debug("Client connnected to \(host):\(port)")
            case .unixDomainSocket(let path):
                (channel, channelHandler) =
                    try await bootstrap
                    .connect(unixDomainSocketPath: path) { channel in
                        setupChannel(channel, configuration: configuration, logger: logger)
                    }
                logger.debug("Client connnected to socket path \(path)")
            }
            return (channel, channelHandler)
        } catch {
            throw error
        }
    }

    private static func setupChannel(
        _ channel: Channel,
        configuration: ValkeyClientConfiguration,
        logger: Logger
    ) -> EventLoopFuture<(Channel, ValkeyChannelHandler)> {
        channel.eventLoop.makeCompletedFuture {
            if case .enable(let sslContext, let tlsServerName) = configuration.tls.base {
                try channel.pipeline.syncOperations.addHandler(NIOSSLClientHandler(context: sslContext, serverHostname: tlsServerName))
            }
            let valkeyChannelHandler = ValkeyChannelHandler(channel: channel, logger: logger)
            try channel.pipeline.syncOperations.addHandler(valkeyChannelHandler)
            return (channel, valkeyChannelHandler)
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

// Used in ValkeyConnection.pipeline
@usableFromInline
struct AutoIncrementingInteger {
    @usableFromInline
    var value: Int = 0

    @inlinable
    init() {
        self.value = 0
    }

    @inlinable
    mutating func next() -> Int {
        value += 1
        return value - 1
    }
}
