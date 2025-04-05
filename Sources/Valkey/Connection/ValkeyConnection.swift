//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey project
//
// Copyright (c) 2025 the swift-valkey authors
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
    let channelHandler: NIOLoopBound<ValkeyChannelHandler>
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
        self.channelHandler = .init(channelHandler, eventLoop: channel.eventLoop)
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
        eventLoop: EventLoop = MultiThreadedEventLoopGroup.singleton.any(),
        logger: Logger
    ) async throws -> ValkeyConnection {
        let future =
            if eventLoop.inEventLoop {
                self._makeClient(address: address, eventLoop: eventLoop, configuration: configuration, logger: logger)
            } else {
                eventLoop.flatSubmit {
                    self._makeClient(address: address, eventLoop: eventLoop, configuration: configuration, logger: logger)
                }
            }
        let connection = try await future.get()
        if configuration.respVersion == .v3 {
            try await connection.resp3Upgrade()
        }
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
        let buffer = encoder.buffer

        let result = try await withCheckedThrowingContinuation { continuation in
            if self.channel.eventLoop.inEventLoop {
                self.channelHandler.value.write(request: ValkeyRequest.single(buffer: buffer, promise: .swift(continuation)))
            } else {
                self.channel.eventLoop.execute {
                    self.channelHandler.value.write(request: ValkeyRequest.single(buffer: buffer, promise: .swift(continuation)))
                }
            }
        }
        return try .init(from: result)
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
        var mpromises: [EventLoopPromise<RESPToken>] = []
        var encoder = RESPCommandEncoder()
        for command in repeat each commands {
            command.encode(into: &encoder)
            mpromises.append(channel.eventLoop.makePromise(of: RESPToken.self))
        }
        let outBuffer = encoder.buffer
        let promises = mpromises
        // write directly to channel handler
        if self.channel.eventLoop.inEventLoop {
            self.channelHandler.value.write(request: ValkeyRequest.multiple(buffer: outBuffer, promises: promises.map { .nio($0) }))
        } else {
            self.channel.eventLoop.execute {
                self.channelHandler.value.write(request: ValkeyRequest.multiple(buffer: outBuffer, promises: promises.map { .nio($0) }))
            }
        }

        // get response from channel handler
        var index = AutoIncrementingInteger()
        return try await (repeat (each Command).Response(from: promises[index.next()].futureResult.get()))
    }

    /// Try to upgrade to RESP3
    private func resp3Upgrade() async throws {
        _ = try await send(command: HELLO(arguments: .init(protover: 3, auth: nil, clientname: nil)))
    }

    /// Create Valkey connection and return channel connection is running on and the Valkey channel handler
    private static func _makeClient(
        address: ServerAddress,
        eventLoop: EventLoop,
        configuration: ValkeyClientConfiguration,
        logger: Logger
    ) -> EventLoopFuture<ValkeyConnection> {
        eventLoop.assertInEventLoop()

        let bootstrap: NIOClientTCPBootstrapProtocol
        #if canImport(Network)
        if let tsBootstrap = createTSBootstrap(eventLoopGroup: eventLoop, tlsOptions: nil) {
            bootstrap = tsBootstrap
        } else {
            #if os(iOS) || os(tvOS)
            self.logger.warning(
                "Running BSD sockets on iOS or tvOS is not recommended. Please use NIOTSEventLoopGroup, to run with the Network framework"
            )
            #endif
            bootstrap = self.createSocketsBootstrap(eventLoopGroup: eventLoop)
        }
        #else
        bootstrap = self.createSocketsBootstrap(eventLoopGroup: eventLoop)
        #endif

        let connect = bootstrap.channelInitializer { channel in
            do {
                let sync = channel.pipeline.syncOperations
                if case .enable(let sslContext, let tlsServerName) = configuration.tls.base {
                    try sync.addHandler(NIOSSLClientHandler(context: sslContext, serverHostname: tlsServerName))
                }
                let valkeyChannelHandler = ValkeyChannelHandler(
                    eventLoop: channel.eventLoop,
                    logger: logger
                )
                try sync.addHandler(valkeyChannelHandler)
                return eventLoop.makeSucceededVoidFuture()
            } catch {
                return eventLoop.makeFailedFuture(error)
            }
        }

        let future: EventLoopFuture<Channel>
        switch address.value {
        case .hostname(let host, let port):
            future = connect.connect(host: host, port: port)
            future.whenSuccess { _ in
                logger.debug("Client connnected to \(host):\(port)")
            }
        case .unixDomainSocket(let path):
            future = connect.connect(unixDomainSocketPath: path)
            future.whenSuccess { _ in
                logger.debug("Client connnected to socket path \(path)")
            }
        }

        return future.flatMapThrowing { channel in
            let handler = try channel.pipeline.syncOperations.handler(type: ValkeyChannelHandler.self)
            return ValkeyConnection(channel: channel, channelHandler: handler, configuration: configuration, logger: logger)
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
