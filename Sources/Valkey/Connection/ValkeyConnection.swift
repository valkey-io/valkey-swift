//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import Logging
import NIOCore
import NIOPosix
import NIOSSL
import Synchronization

#if canImport(Network)
import Network
import NIOTransportServices
#endif

#if DistributedTracingSupport
import Tracing
#endif

/// A single connection to a Valkey database.
@available(valkeySwift 1.0, *)
public final actor ValkeyConnection: ValkeyClientProtocol, Sendable {
    nonisolated public let unownedExecutor: UnownedSerialExecutor

    /// Request ID generator
    @usableFromInline
    static let requestIDGenerator: IDGenerator = .init()
    /// Connection ID, used by connection pool
    public let id: ID
    /// Logger used by Server
    let logger: Logger
    #if DistributedTracingSupport
    @usableFromInline
    let tracer: (any Tracer)?
    @usableFromInline
    let address: (hostOrSocketPath: String, port: Int?)?
    #endif
    @usableFromInline
    let channel: any Channel
    @usableFromInline
    let channelHandler: ValkeyChannelHandler
    let configuration: ValkeyConnectionConfiguration
    let isClosed: Atomic<Bool>

    /// Initialize connection
    init(
        channel: any Channel,
        connectionID: ID,
        channelHandler: ValkeyChannelHandler,
        configuration: ValkeyConnectionConfiguration,
        address: ValkeyServerAddress?,
        logger: Logger
    ) {
        self.unownedExecutor = channel.eventLoop.executor.asUnownedSerialExecutor()
        self.channel = channel
        self.channelHandler = channelHandler
        self.configuration = configuration
        self.id = connectionID
        self.logger = logger
        #if DistributedTracingSupport
        self.tracer = configuration.tracing.tracer
        switch address?.value {
        case let .hostname(host, port):
            self.address = (host, port)
        case let .unixDomainSocket(path):
            self.address = (path, nil)
        case nil:
            self.address = nil
        }
        #endif
        self.isClosed = .init(false)
    }

    /// Connect to Valkey database and run operation using connection and then close
    /// connection.
    ///
    /// To avoid the cost of acquiring the connection and then closing it, it is always
    /// preferable to use ``ValkeyClient/withConnection(isolation:operation:)`` which
    /// uses a persistent connection pool to provide connections to your Valkey database.
    ///
    /// - Parameters:
    ///   - address: Internet address of database
    ///   - configuration: Configuration of Valkey connection
    ///   - eventLoop: EventLoop to run connection on
    ///   - logger: Logger for connection
    ///   - isolation: Actor isolation
    ///   - operation: Closure handling Valkey connection
    /// - Returns: Return value of operation closure
    public static func withConnection<Value>(
        address: ValkeyServerAddress,
        configuration: ValkeyConnectionConfiguration = .init(),
        eventLoop: any EventLoop = MultiThreadedEventLoopGroup.singleton.any(),
        logger: Logger,
        isolation: isolated (any Actor)? = #isolation,
        operation: (ValkeyConnection) async throws -> sending Value
    ) async throws -> sending Value {
        let connection = try await connect(
            address: address,
            connectionID: 0,
            configuration: configuration,
            eventLoop: eventLoop,
            logger: logger
        )
        defer {
            connection.close()
        }
        return try await operation(connection)
    }

    /// Connect to Valkey database and return connection
    ///
    /// - Parameters:
    ///   - address: Internet address of database
    ///   - connectionID: Connection identifier
    ///   - configuration: Configuration of Valkey connection
    ///   - eventLoop: EventLoop to run connection on
    ///   - logger: Logger for connection
    /// - Returns: ValkeyConnection
    static func connect(
        address: ValkeyServerAddress,
        connectionID: ID,
        configuration: ValkeyConnectionConfiguration,
        eventLoop: any EventLoop = MultiThreadedEventLoopGroup.singleton.any(),
        logger: Logger
    ) async throws -> ValkeyConnection {
        let future =
            if eventLoop.inEventLoop {
                self._makeConnection(
                    address: address,
                    connectionID: connectionID,
                    eventLoop: eventLoop,
                    configuration: configuration,
                    logger: logger
                )
            } else {
                eventLoop.flatSubmit {
                    self._makeConnection(
                        address: address,
                        connectionID: connectionID,
                        eventLoop: eventLoop,
                        configuration: configuration,
                        logger: logger
                    )
                }
            }
        let connection = try await future.get()
        try await connection.waitOnActive()
        return connection
    }

    /// Close connection
    public nonisolated func close() {
        guard self.isClosed.compareExchange(expected: false, desired: true, successOrdering: .relaxed, failureOrdering: .relaxed).exchanged else {
            return
        }
        self.channel.close(mode: .all, promise: nil)
    }

    func waitOnActive() async throws {
        try await self.channelHandler.waitOnActive().get()
    }

    /// Send RESP command to Valkey connection
    /// - Parameter command: ValkeyCommand structure
    /// - Returns: The command response as defined in the ValkeyCommand
    @inlinable
    public func execute<Command: ValkeyCommand>(_ command: Command) async throws -> Command.Response {
        #if DistributedTracingSupport
        let span = self.tracer?.startSpan(Command.name, ofKind: .client)
        defer { span?.end() }

        span?.updateAttributes { attributes in
            self.applyCommonAttributes(to: &attributes, commandName: Command.name)
        }
        #endif

        let requestID = Self.requestIDGenerator.next()

        do {
            let token = try await withTaskCancellationHandler {
                if Task.isCancelled {
                    throw ValkeyClientError(.cancelled)
                }
                return try await withCheckedThrowingContinuation { continuation in
                    self.channelHandler.write(command: command, continuation: continuation, requestID: requestID)
                }
            } onCancel: {
                self.cancel(requestID: requestID)
            }
            return try .init(fromRESP: token)
        } catch let error as ValkeyClientError {
            #if DistributedTracingSupport
            if let span {
                span.recordError(error)
                span.setStatus(SpanStatus(code: .error))
                if let prefix = error.simpleErrorPrefix {
                    span.attributes["db.response.status_code"] = "\(prefix)"
                }
            }
            #endif
            throw error
        } catch {
            #if DistributedTracingSupport
            if let span {
                span.recordError(error)
                span.setStatus(SpanStatus(code: .error))
            }
            #endif
            throw error
        }
    }

    /// Pipeline a series of commands to Valkey connection
    ///
    /// Once all the responses for the commands have been received the function returns
    /// a parameter pack of Results, one for each command.
    ///
    /// - Parameter commands: Parameter pack of ValkeyCommands
    /// - Returns: Parameter pack holding the responses of all the commands
    @inlinable
    public func execute<each Command: ValkeyCommand>(
        _ commands: repeat each Command
    ) async -> sending (repeat Result<(each Command).Response, any Error>) {
        func convert<Response: RESPTokenDecodable>(_ result: Result<RESPToken, any Error>, to: Response.Type) -> Result<Response, any Error> {
            result.flatMap {
                do {
                    return try .success(Response(fromRESP: $0))
                } catch {
                    return .failure(error)
                }
            }
        }
        let requestID = Self.requestIDGenerator.next()
        // this currently allocates a promise for every command. We could collapse this down to one promise
        var mpromises: [EventLoopPromise<RESPToken>] = []
        var encoder = ValkeyCommandEncoder()
        for command in repeat each commands {
            command.encode(into: &encoder)
            mpromises.append(channel.eventLoop.makePromise(of: RESPToken.self))
        }
        let outBuffer = encoder.buffer
        let promises = mpromises
        return await withTaskCancellationHandler {
            if Task.isCancelled {
                for promise in mpromises {
                    promise.fail(ValkeyClientError(.cancelled))
                }
            } else {
                // write directly to channel handler
                self.channelHandler.write(request: ValkeyRequest.multiple(buffer: outBuffer, promises: promises.map { .nio($0) }, id: requestID))
            }
            // get response from channel handler
            var index = AutoIncrementingInteger()
            return await (repeat convert(promises[index.next()].futureResult._result(), to: (each Command).Response.self))
        } onCancel: {
            self.cancel(requestID: requestID)
        }
    }

    /// Pipeline a series of commands to Valkey connection
    ///
    /// Once all the responses for the commands have been received the function returns
    /// an array of RESPToken Results, one for each command.
    ///
    /// This is an alternative version of the pipelining function ``ValkeyConnection/execute(_:)->(_,_)``
    /// that allows for a collection of ValkeyCommands. It provides more flexibility but is
    /// slightly more expensive to run and the command responses are returned as ``RESPToken``
    /// instead of the response type for the command.
    ///
    /// - Parameter commands: Collection of ValkeyCommands
    /// - Returns: Array holding the RESPToken responses of all the commands
    @inlinable
    public func execute(
        _ commands: some Collection<any ValkeyCommand>
    ) async -> sending [Result<RESPToken, any Error>] {
        let requestID = Self.requestIDGenerator.next()
        // this currently allocates a promise for every command. We could collapse this down to one promise
        var mpromises: [EventLoopPromise<RESPToken>] = []
        mpromises.reserveCapacity(commands.count)
        var encoder = ValkeyCommandEncoder()
        for command in commands {
            command.encode(into: &encoder)
            mpromises.append(channel.eventLoop.makePromise(of: RESPToken.self))
        }
        let outBuffer = encoder.buffer
        let promises = mpromises
        return await withTaskCancellationHandler {
            if Task.isCancelled {
                for promise in mpromises {
                    promise.fail(ValkeyClientError(.cancelled))
                }
            } else {
                // write directly to channel handler
                self.channelHandler.write(request: ValkeyRequest.multiple(buffer: outBuffer, promises: promises.map { .nio($0) }, id: requestID))
            }
            // get response from channel handler
            var results: [Result<RESPToken, any Error>] = .init()
            results.reserveCapacity(commands.count)
            for promise in promises {
                await results.append(promise.futureResult._result())
            }
            return results
        } onCancel: {
            self.cancel(requestID: requestID)
        }
    }

    /// Pipeline a series of commands to Valkey connection and precede each command with an ASKING
    /// command
    ///
    /// Once all the responses for the commands have been received the function returns
    /// an array of RESPToken Results, one for each command.
    ///
    /// This is an internal function used by the cluster client
    ///
    /// - Parameter commands: Collection of ValkeyCommands
    /// - Returns: Array holding the RESPToken responses of all the commands
    @usableFromInline
    func executeWithAsk(
        _ commands: some Collection<any ValkeyCommand>
    ) async -> sending [Result<RESPToken, any Error>] {
        let requestID = Self.requestIDGenerator.next()
        // this currently allocates a promise for every command. We could collapse this down to one promise
        var mpromises: [EventLoopPromise<RESPToken>] = []
        mpromises.reserveCapacity(commands.count)
        var encoder = ValkeyCommandEncoder()
        for command in commands {
            ASKING().encode(into: &encoder)
            command.encode(into: &encoder)
            mpromises.append(channel.eventLoop.makePromise(of: RESPToken.self))
        }
        let outBuffer = encoder.buffer
        let promises = mpromises
        return await withTaskCancellationHandler {
            if Task.isCancelled {
                for promise in mpromises {
                    promise.fail(ValkeyClientError(.cancelled))
                }
            } else {
                // write directly to channel handler
                self.channelHandler.write(
                    request: ValkeyRequest.multiple(buffer: outBuffer, promises: promises.flatMap { [.forget, .nio($0)] }, id: requestID)
                )
            }
            // get response from channel handler
            var results: [Result<RESPToken, any Error>] = .init()
            results.reserveCapacity(commands.count)
            for promise in promises {
                await results.append(promise.futureResult._result())
            }
            return results
        } onCancel: {
            self.cancel(requestID: requestID)
        }
    }

    #if DistributedTracingSupport
    @usableFromInline
    func applyCommonAttributes(to attributes: inout SpanAttributes, commandName: String) {
        attributes[self.configuration.tracing.attributeNames.databaseOperationName] = commandName
        attributes[self.configuration.tracing.attributeNames.databaseSystemName] = self.configuration.tracing.attributeValues.databaseSystem
        attributes[self.configuration.tracing.attributeNames.networkPeerAddress] = channel.remoteAddress?.ipAddress
        attributes[self.configuration.tracing.attributeNames.networkPeerPort] = channel.remoteAddress?.port
        attributes[self.configuration.tracing.attributeNames.serverAddress] = address?.hostOrSocketPath
        attributes[self.configuration.tracing.attributeNames.serverPort] = address?.port == 6379 ? nil : address?.port
    }
    #endif

    @usableFromInline
    nonisolated func cancel(requestID: Int) {
        self.channel.eventLoop.execute {
            self.assumeIsolated { this in
                this.channelHandler.cancel(requestID: requestID)
            }
        }
    }

    /// Create Valkey connection and return channel connection is running on and the Valkey channel handler
    private static func _makeConnection(
        address: ValkeyServerAddress,
        connectionID: ID,
        eventLoop: any EventLoop,
        configuration: ValkeyConnectionConfiguration,
        logger: Logger
    ) -> EventLoopFuture<ValkeyConnection> {
        eventLoop.assertInEventLoop()

        let bootstrap: any NIOClientTCPBootstrapProtocol
        #if canImport(Network)
        if let tsBootstrap = createTSBootstrap(eventLoopGroup: eventLoop, tlsOptions: nil) {
            bootstrap = tsBootstrap
        } else {
            #if os(iOS) || os(tvOS)
            logger.warning(
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
                try self._setupChannel(channel, configuration: configuration, logger: logger)
                return eventLoop.makeSucceededVoidFuture()
            } catch {
                return eventLoop.makeFailedFuture(error)
            }
        }

        let future: EventLoopFuture<any Channel>
        switch address.value {
        case .hostname(let host, let port):
            future = connect.connect(host: host, port: port)
            future.whenSuccess { _ in
                logger.debug("Client connected to \(host):\(port)")
            }
        case .unixDomainSocket(let path):
            future = connect.connect(unixDomainSocketPath: path)
            future.whenSuccess { _ in
                logger.debug("Client connected to socket path \(path)")
            }
        }

        return future.flatMapThrowing { channel in
            let handler = try channel.pipeline.syncOperations.handler(type: ValkeyChannelHandler.self)
            return ValkeyConnection(
                channel: channel,
                connectionID: connectionID,
                channelHandler: handler,
                configuration: configuration,
                address: address,
                logger: logger
            )
        }
    }

    package static func setupChannelAndConnect(
        _ channel: any Channel,
        configuration: ValkeyConnectionConfiguration = .init(),
        logger: Logger
    ) async throws -> ValkeyConnection {
        if !channel.eventLoop.inEventLoop {
            return try await channel.eventLoop.flatSubmit {
                self._setupChannelAndConnect(channel, configuration: configuration, logger: logger)
            }.get()
        }
        return try await self._setupChannelAndConnect(channel, configuration: configuration, logger: logger).get()
    }

    private static func _setupChannelAndConnect(
        _ channel: any Channel,
        tlsSetting: TLSSetting = .disable,
        configuration: ValkeyConnectionConfiguration,
        logger: Logger
    ) -> EventLoopFuture<ValkeyConnection> {
        do {
            let handler = try self._setupChannel(
                channel,
                configuration: configuration,
                logger: logger
            )
            let connection = ValkeyConnection(
                channel: channel,
                connectionID: 0,
                channelHandler: handler,
                configuration: configuration,
                address: .hostname("127.0.0.1", port: 6379),
                logger: logger
            )
            return channel.connect(to: try SocketAddress(ipAddress: "127.0.0.1", port: 6379)).map {
                connection
            }
        } catch {
            return channel.eventLoop.makeFailedFuture(error)
        }
    }

    @usableFromInline
    enum TLSSetting {
        case enable(NIOSSLContext, serverName: String?)
        case disable
    }

    @discardableResult
    static func _setupChannel(
        _ channel: any Channel,
        configuration: ValkeyConnectionConfiguration,
        logger: Logger
    ) throws -> ValkeyChannelHandler {
        channel.eventLoop.assertInEventLoop()
        let sync = channel.pipeline.syncOperations
        switch configuration.tls.base {
        case .enable(let sslContext, let tlsServerName):
            try sync.addHandler(NIOSSLClientHandler(context: sslContext, serverHostname: tlsServerName))
        case .disable:
            break
        }
        let valkeyChannelHandler = ValkeyChannelHandler(
            configuration: .init(configuration),
            eventLoop: channel.eventLoop,
            logger: logger
        )
        try sync.addHandler(valkeyChannelHandler)
        return valkeyChannelHandler
    }

    /// create a BSD sockets based bootstrap
    private static func createSocketsBootstrap(eventLoopGroup: any EventLoopGroup) -> ClientBootstrap {
        ClientBootstrap(group: eventLoopGroup)
    }

    #if canImport(Network)
    /// create a NIOTransportServices bootstrap using Network.framework
    private static func createTSBootstrap(eventLoopGroup: any EventLoopGroup, tlsOptions: NWProtocolTLS.Options?) -> NIOTSConnectionBootstrap? {
        guard
            let bootstrap = NIOTSConnectionBootstrap(validatingGroup: eventLoopGroup)
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

#if DistributedTracingSupport
extension ValkeyClientError {
    /// Extract the simple error prefix from this error.
    ///
    /// - SeeAlso: [](https://valkey.io/topics/protocol/#simple-errors)
    @usableFromInline
    var simpleErrorPrefix: Substring? {
        guard let message else { return nil }
        var prefixEndIndex = message.startIndex
        while prefixEndIndex < message.endIndex, message[prefixEndIndex] != " " {
            message.formIndex(after: &prefixEndIndex)
        }
        return message[message.startIndex..<prefixEndIndex]
    }
}
#endif
