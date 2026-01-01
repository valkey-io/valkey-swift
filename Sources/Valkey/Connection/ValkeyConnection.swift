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
    /// Logger used by connection
    @usableFromInline
    let logger: Logger
    #if DistributedTracingSupport
    @usableFromInline
    let tracer: (any Tracer)?
    @usableFromInline
    let commonSpanAttributes: SpanAttributes
    #endif
    @usableFromInline
    let channel: any Channel
    @usableFromInline
    let channelHandler: ValkeyChannelHandler
    @usableFromInline
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
        self.commonSpanAttributes = Self.createCommonSpanAttributes(address: address, configuration: configuration, channel: channel)
        #endif
        self.isClosed = .init(false)
    }

    /// Connect to Valkey database and run operation using connection and then close
    /// connection.
    ///
    /// To avoid the cost of acquiring the connection and then closing it, it is always
    /// preferable to use ``ValkeyClient/withConnection(operation:)`` which
    /// uses a persistent connection pool to provide connections to your Valkey database.
    ///
    /// - Parameters:
    ///   - address: Internet address of database
    ///   - configuration: Configuration of Valkey connection
    ///   - eventLoop: EventLoop to run connection on
    ///   - logger: Logger for connection
    ///   - operation: Closure handling Valkey connection
    /// - Returns: Return value of operation closure
    public static func withConnection<Value>(
        address: ValkeyServerAddress,
        configuration: ValkeyConnectionConfiguration = .init(),
        eventLoop: any EventLoop = MultiThreadedEventLoopGroup.singleton.any(),
        logger: Logger,
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

    /// Trigger graceful shutdown of connection
    ///
    /// The connection will wait until all pending commands have been processed before
    /// closing the connection.
    func triggerGracefulShutdown() {
        self.channelHandler.triggerGracefulShutdown()
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
            self.applyCommonAttributes(to: &attributes)
            attributes[self.configuration.tracing.attributeNames.databaseOperationName] = Command.name
        }
        #endif

        self.logger.trace("execute", metadata: ["command": "\(Command.name)"])

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
            return try .init(token)
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
        self.logger.trace("execute", metadata: ["commands": .string(Self.concatenateCommandNames(repeat each commands).string)])

        #if DistributedTracingSupport
        let span = self.tracer?.startSpan("Pipeline", ofKind: .client)
        defer { span?.end() }

        if !(span is NoOpTracer.Span) {
            span?.updateAttributes { attributes in
                self.applyCommonAttributes(to: &attributes)
                let commands = Self.concatenateCommandNames(repeat each commands)
                attributes[self.configuration.tracing.attributeNames.databaseOperationName] = commands.string
                attributes[self.configuration.tracing.attributeNames.databaseOperationBatchSize] = commands.count
            }
        }
        #endif

        // this currently allocates a promise for every command. We could collapse this down to one promise
        var promises: [EventLoopPromise<RESPToken>] = []
        var encoder = ValkeyCommandEncoder()
        for command in repeat each commands {
            command.encode(into: &encoder)
            promises.append(channel.eventLoop.makePromise(of: RESPToken.self))
        }
        return await _execute(
            buffer: encoder.buffer,
            promises: promises,
            valkeyPromises: promises.map { .nio($0) }
        ) { promises in
            // get response from channel handler
            var index = AutoIncrementingInteger()
            return await (repeat promises[index.next()].futureResult._result().convertFromRESP(to: (each Command).Response.self))
        }
    }

    /// Pipeline a series of commands as a transaction to Valkey connection
    ///
    /// Another client will never be served in the middle of the execution of these
    /// commands. See https://valkey.io/topics/transactions/ for more information.
    ///
    /// EXEC and MULTI commands are added to the pipelined commands and the output
    /// of the EXEC command is transformed into a parameter pack of Results, one
    /// for each command.
    ///
    /// - Parameter commands: Parameter pack of ValkeyCommands
    /// - Returns: Parameter pack holding the responses of all the commands
    /// - Throws: ValkeyTransactionError when EXEC aborts
    @inlinable
    public func transaction<each Command: ValkeyCommand>(
        _ commands: repeat each Command
    ) async throws -> sending (repeat Result<(each Command).Response, Error>) {
        self.logger.trace("transaction", metadata: ["commands": .string(Self.concatenateCommandNames(repeat each commands).string)])

        #if DistributedTracingSupport
        let span = self.tracer?.startSpan("MULTI", ofKind: .client)
        defer { span?.end() }

        if !(span is NoOpTracer.Span) {
            span?.updateAttributes { attributes in
                self.applyCommonAttributes(to: &attributes)
                let commands = Self.concatenateCommandNames(repeat each commands)
                attributes[self.configuration.tracing.attributeNames.databaseOperationName] = commands.string
                attributes[self.configuration.tracing.attributeNames.databaseOperationBatchSize] = commands.count
            }
        }
        #endif

        // Construct encoded commands and promise array
        var encoder = ValkeyCommandEncoder()
        var promises: [EventLoopPromise<RESPToken>] = []
        MULTI().encode(into: &encoder)
        promises.append(channel.eventLoop.makePromise(of: RESPToken.self))
        for command in repeat each commands {
            command.encode(into: &encoder)
            promises.append(channel.eventLoop.makePromise(of: RESPToken.self))
        }
        EXEC().encode(into: &encoder)
        promises.append(channel.eventLoop.makePromise(of: RESPToken.self))

        do {
            return try await _execute(
                buffer: encoder.buffer,
                promises: promises,
                valkeyPromises: promises.map { .nio($0) }
            ) { promises -> sending Result<(repeat Result<(each Command).Response, Error>), any Error> in
                let responses: EXEC.Response
                do {
                    let execFutureResult = promises.last!.futureResult
                    responses = try await execFutureResult.get().decode(as: EXEC.Response.self)
                } catch let error as ValkeyClientError where error.errorCode == .commandError {
                    // we received an error while running the EXEC command. Extract queuing
                    // results and throw error
                    var results: [Result<RESPToken, Error>] = .init()
                    results.reserveCapacity(promises.count - 2)
                    for promise in promises[1..<(promises.count - 1)] {
                        results.append(await promise.futureResult._result())
                    }
                    return .failure(ValkeyTransactionError.transactionErrors(queuedResults: results, execError: error))
                } catch {
                    return .failure(error)
                }
                // If EXEC returned nil then transaction was aborted because a
                // WATCHed variable changed
                guard let responses else {
                    return .failure(ValkeyTransactionError.transactionAborted)
                }
                // We convert all the RESP errors in the response array from EXEC to Result.failure
                // and attempt to convert the remaining to their respective Response types
                return .success(responses.decodeExecResults())
            }.get()
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
    /// an array of Results, one for each command.
    ///
    /// This is an alternative version of the pipeline function ``ValkeyConnection/execute(_:)->(_,_)``
    /// that allows for a collection of ValkeyCommands. It provides more flexibility but the command
    /// responses are returned as ``RESPToken`` instead of the response type for the command.
    ///
    /// - Parameter commands: Collection of ValkeyCommands
    /// - Returns: Array holding the RESPToken responses of all the commands
    @inlinable
    public func execute<Commands: Collection & Sendable>(
        _ commands: Commands
    ) async -> [Result<RESPToken, any Error>] where Commands.Element == any ValkeyCommand {
        self.logger.trace("execute", metadata: ["commands": .string(Self.concatenateCommandNames(commands))])

        #if DistributedTracingSupport
        let span = self.tracer?.startSpan("Pipeline", ofKind: .client)
        defer { span?.end() }

        if !(span is NoOpTracer.Span) {
            span?.updateAttributes { attributes in
                self.applyCommonAttributes(to: &attributes)
                attributes[self.configuration.tracing.attributeNames.databaseOperationName] = Self.concatenateCommandNames(commands)
                attributes[self.configuration.tracing.attributeNames.databaseOperationBatchSize] = commands.count
            }
        }
        #endif

        // this currently allocates a promise for every command. We could collapse this down to one promise
        var promises: [EventLoopPromise<RESPToken>] = []
        promises.reserveCapacity(commands.count)
        var encoder = ValkeyCommandEncoder()
        for command in commands {
            command.encode(into: &encoder)
            promises.append(channel.eventLoop.makePromise(of: RESPToken.self))
        }
        let count = commands.count
        return await _execute(
            buffer: encoder.buffer,
            promises: promises,
            valkeyPromises: promises.map { .nio($0) }
        ) { promises in
            // get response from channel handler
            var results: [Result<RESPToken, any Error>] = .init()
            results.reserveCapacity(count)
            for promise in promises {
                await results.append(promise.futureResult._result())
            }
            return results
        }
    }

    /// Pipeline a series of commands as a transaction to Valkey connection
    ///
    /// Another client will never be served in the middle of the execution of these
    /// commands. See https://valkey.io/topics/transactions/ for more information.
    ///
    /// EXEC and MULTI commands are added to the pipelined commands and the output
    /// of the EXEC command is transformed into an array of RESPToken Results, one for
    /// each command.
    ///
    /// This is an alternative version of the transaction function ``ValkeyConnection/transaction(_:)->(_,_)``
    /// that allows for a collection of ValkeyCommands. It provides more flexibility but the command
    /// responses are returned as ``RESPToken`` instead of the response type for the command.
    ///
    /// - Parameter commands: Collection of ValkeyCommands
    /// - Returns: Array holding the RESPToken responses of all the commands
    /// - Throws: ValkeyTransactionError when EXEC aborts
    @inlinable
    public func transaction<Commands: Collection & Sendable>(
        _ commands: Commands
    ) async throws -> [Result<RESPToken, Error>] where Commands.Element == any ValkeyCommand {
        self.logger.trace("transaction", metadata: ["commands": .string(Self.concatenateCommandNames(commands))])

        #if DistributedTracingSupport
        let span = self.tracer?.startSpan("MULTI", ofKind: .client)
        defer { span?.end() }

        if !(span is NoOpTracer.Span) {
            span?.updateAttributes { attributes in
                self.applyCommonAttributes(to: &attributes)
                attributes[self.configuration.tracing.attributeNames.databaseOperationName] = Self.concatenateCommandNames(commands)
                attributes[self.configuration.tracing.attributeNames.databaseOperationBatchSize] = commands.count
            }
        }
        #endif

        // Construct encoded commands and promise array
        var encoder = ValkeyCommandEncoder()
        var promises: [EventLoopPromise<RESPToken>] = []
        MULTI().encode(into: &encoder)
        promises.append(channel.eventLoop.makePromise(of: RESPToken.self))
        for command in commands {
            command.encode(into: &encoder)
            promises.append(channel.eventLoop.makePromise(of: RESPToken.self))
        }
        EXEC().encode(into: &encoder)
        promises.append(channel.eventLoop.makePromise(of: RESPToken.self))

        do {
            return try await _execute(
                buffer: encoder.buffer,
                promises: promises,
                valkeyPromises: promises.map { .nio($0) },
                processResults: self._processTransactionPromises
            ).get()
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
    ) async -> [Result<RESPToken, any Error>] {
        self.logger.trace("asking", metadata: ["commands": .string(Self.concatenateCommandNames(commands))])
        // this currently allocates a promise for every command. We could collapse this down to one promise
        var promises: [EventLoopPromise<RESPToken>] = []
        promises.reserveCapacity(commands.count)
        var valkeyPromises: [ValkeyPromise<RESPToken>] = []
        valkeyPromises.reserveCapacity(commands.count * 2)
        var encoder = ValkeyCommandEncoder()
        for command in commands {
            ASKING().encode(into: &encoder)
            command.encode(into: &encoder)
            promises.append(channel.eventLoop.makePromise(of: RESPToken.self))
            valkeyPromises.append(.forget)
            valkeyPromises.append(.nio(promises.last!))
        }

        let count = commands.count
        return await _execute(
            buffer: encoder.buffer,
            promises: promises,
            valkeyPromises: valkeyPromises
        ) { promises in
            // get response from channel handler
            var results: [Result<RESPToken, Error>] = .init()
            results.reserveCapacity(count)
            for promise in promises {
                await results.append(promise.futureResult._result())
            }
            return results
        }
    }

    /// Pipeline a series of commands as a transaction preceded with an ASKING command
    ///
    /// Once all the responses for the commands have been received the function returns
    /// an array of RESPToken Results, one for each command.
    ///
    /// This is an internal function used by the cluster client
    ///
    /// - Parameter commands: Collection of ValkeyCommands
    /// - Returns: Array holding the RESPToken responses of all the commands
    @usableFromInline
    func transactionWithAsk(
        _ commands: some Collection<any ValkeyCommand>
    ) async throws -> [Result<RESPToken, any Error>] {
        self.logger.trace("transaction asking", metadata: ["commands": .string(Self.concatenateCommandNames(commands))])
        var promises: [EventLoopPromise<RESPToken>] = []
        promises.reserveCapacity(commands.count)
        var valkeyPromises: [ValkeyPromise<RESPToken>] = []
        valkeyPromises.reserveCapacity(commands.count + 3)
        var encoder = ValkeyCommandEncoder()
        ASKING().encode(into: &encoder)
        MULTI().encode(into: &encoder)
        promises.append(channel.eventLoop.makePromise(of: RESPToken.self))
        valkeyPromises.append(.forget)
        valkeyPromises.append(.nio(promises.last!))

        for command in commands {
            command.encode(into: &encoder)
            promises.append(channel.eventLoop.makePromise(of: RESPToken.self))
            valkeyPromises.append(.nio(promises.last!))
        }
        EXEC().encode(into: &encoder)
        promises.append(channel.eventLoop.makePromise(of: RESPToken.self))
        valkeyPromises.append(.nio(promises.last!))

        return try await _execute(
            buffer: encoder.buffer,
            promises: promises,
            valkeyPromises: valkeyPromises,
            processResults: self._processTransactionPromises
        ).get()
    }

    /// Execute stream of commands written into buffer
    ///
    /// The function is provided with an array of EventLoopPromises for the responses of commands
    /// we care about and an array of valkey promises one for each command
    @usableFromInline  // would like to set this to inlinable but it crashes in release if I do
    func _execute<Value>(
        buffer: ByteBuffer,
        promises: [EventLoopPromise<RESPToken>],
        valkeyPromises: [ValkeyPromise<RESPToken>],
        processResults: sending ([EventLoopPromise<RESPToken>]) async -> sending Value
    ) async -> Value {
        let requestID = Self.requestIDGenerator.next()
        return await withTaskCancellationHandler {
            if Task.isCancelled {
                for promise in promises {
                    promise.fail(ValkeyClientError(.cancelled))
                }
            } else {
                // write directly to channel handler
                self.channelHandler.write(
                    request: ValkeyRequest.multiple(buffer: buffer, promises: valkeyPromises, id: requestID)
                )
            }

            return await processResults(promises)
        } onCancel: {
            self.cancel(requestID: requestID)
        }
    }

    @usableFromInline
    func _processTransactionPromises(
        _ promises: [EventLoopPromise<RESPToken>]
    ) async -> sending Result<[Result<RESPToken, Error>], any Error> {
        let responses: EXEC.Response
        do {
            let execFutureResult = promises.last!.futureResult
            responses = try await execFutureResult.get().decode(as: EXEC.Response.self)
        } catch let error as ValkeyClientError where error.errorCode == .commandError {
            // we received an error while running the EXEC command. Extract queuing
            // results and throw error
            var results: [Result<RESPToken, Error>] = .init()
            results.reserveCapacity(promises.count - 2)
            for promise in promises[1..<(promises.count - 1)] {
                results.append(await promise.futureResult._result())
            }
            return .failure(ValkeyTransactionError.transactionErrors(queuedResults: results, execError: error))
        } catch {
            return .failure(error)
        }
        // If EXEC returned nil then transaction was aborted because a
        // WATCHed variable changed
        guard let responses else {
            return .failure(ValkeyTransactionError.transactionAborted)
        }
        // We convert all the RESP errors in the response from EXEC to Result.failure
        return .success(
            responses.map {
                switch $0.identifier {
                case .simpleError, .bulkError:
                    .failure(ValkeyClientError(.commandError, message: $0.errorString.map { Swift.String(buffer: $0) }))
                default:
                    .success($0)
                }
            }
        )
    }

    #if DistributedTracingSupport
    @usableFromInline
    static func createCommonSpanAttributes(
        address: ValkeyServerAddress?,
        configuration: ValkeyConnectionConfiguration,
        channel: Channel
    ) -> SpanAttributes {
        var commonAttributes: SpanAttributes = [
            configuration.tracing.attributeNames.databaseSystemName: .string(configuration.tracing.attributeValues.databaseSystem)
        ]
        if let remoteAddress = channel.remoteAddress {
            commonAttributes[configuration.tracing.attributeNames.networkPeerAddress] = remoteAddress.ipAddress
            commonAttributes[configuration.tracing.attributeNames.networkPeerPort] = remoteAddress.port
        }
        switch address?.value {
        case let .hostname(host, port):
            commonAttributes[configuration.tracing.attributeNames.serverAddress] = host
            commonAttributes[configuration.tracing.attributeNames.serverPort] = (port == 6379 ? nil : port)
        case let .unixDomainSocket(path):
            commonAttributes[configuration.tracing.attributeNames.serverAddress] = path
        case nil:
            break
        }
        return commonAttributes
    }
    @usableFromInline
    func applyCommonAttributes(to attributes: inout SpanAttributes) {
        attributes.merge(self.commonSpanAttributes)
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

    /// Concatenate names from parameter pack of commands together
    @inlinable
    static func concatenateCommandNames<each Command: ValkeyCommand>(
        _ commands: repeat each Command
    ) -> (string: String, count: Int) {
        // get length of string so we only do one allocation
        var stringLength = 0
        var count = 0
        for command in repeat each commands {
            if count == 16 {
                stringLength += 3  // length of ellipsis
                break
            }
            stringLength += Swift.type(of: command).name.count + 1
            count += 1
        }
        var string: String = ""
        string.reserveCapacity(stringLength - 1)

        count = 0
        for command in repeat each commands {
            if count == 0 {
                string += "\(Swift.type(of: command).name)"
            } else if count == 16 {
                string += "..."
            } else if count < 16 {
                string += ",\(Swift.type(of: command).name)"
            }
            count += 1
        }
        return (string, count)
    }

    /// Concatenate names from collection of command together
    @inlinable
    static func concatenateCommandNames<Commands: Collection>(
        _ commands: Commands
    ) -> String where Commands.Element == any ValkeyCommand {
        // get length of string so we only do one allocation
        var stringLength = 0
        var count = 0
        for command in commands {
            if count == 16 {
                stringLength += 3  // length of ellipsis
                break
            }
            stringLength += Swift.type(of: command).name.count + 1
            count += 1
        }
        var string: String = ""
        string.reserveCapacity(stringLength - 1)

        guard let firstCommand = commands.first else { return "" }
        string = "\(Swift.type(of: firstCommand).name)"
        count = 1
        for command in commands.dropFirst() {
            if count == 16 {
                string += "..."
                break
            } else {
                string += ",\(Swift.type(of: command).name)"
            }
            count += 1
        }
        return string
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
            return channel.connect(to: try SocketAddress(ipAddress: "127.0.0.1", port: 6379)).flatMap {
                channel.eventLoop.makeCompletedFuture {
                    let handler = try self._setupChannel(
                        channel,
                        configuration: configuration,
                        logger: logger
                    )
                    return ValkeyConnection(
                        channel: channel,
                        connectionID: 0,
                        channelHandler: handler,
                        configuration: configuration,
                        address: .hostname("127.0.0.1", port: 6379),
                        logger: logger
                    )
                }
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
    init(_ value: Int = 0) {
        self.value = value
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
        guard case .commandError = self.errorCode, let message else { return nil }
        guard let prefixEndIndex = message.firstIndex(of: " ") else { return nil }
        return message[message.startIndex..<prefixEndIndex]
    }
}
#endif

extension Result where Success == RESPToken, Failure == any Error {
    @usableFromInline
    func convertFromRESP<Response: RESPTokenDecodable>(to: Response.Type) -> Result<Response, Error> {
        self.flatMap {
            do {
                return try .success(Response($0))
            } catch {
                return .failure(error)
            }
        }
    }
}
