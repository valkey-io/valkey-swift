//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import DequeModule
import Logging
import NIOCore

@usableFromInline
@available(valkeySwift 1.0, *)
enum ValkeyPromise<T: Sendable>: ~Copyable, Sendable {
    case nio(EventLoopPromise<T>)
    case swift(Continuation<T, any Error>)
    case forget

    @inlinable
    consuming func succeed(_ t: T) {
        switch consume self {
        case .nio(let eventLoopPromise):
            eventLoopPromise.succeed(t)
        case .swift(let continuation):
            continuation.resume(returning: t)
        case .forget:
            break
        }
    }

    @inlinable
    consuming func fail(_ e: any Error) {
        switch consume self {
        case .nio(let eventLoopPromise):
            eventLoopPromise.fail(e)
        case .swift(let continuation):
            continuation.resume(throwing: e)
        case .forget:
            break
        }
    }
}

@usableFromInline
@available(valkeySwift 1.0, *)
enum ValkeyRequest: ~Copyable, Sendable {
    case single(buffer: ByteBuffer, promise: ValkeyPromise<RESPToken>, id: Int)
    case multiple(buffer: ByteBuffer, promises: UniqueDeque<ValkeyPromise<RESPToken>>, id: Int)
}

@available(valkeySwift 1.0, *)
@usableFromInline
final class ValkeyChannelHandler: ChannelInboundHandler {
    @usableFromInline
    struct Configuration {
        let authentication: ValkeyConnectionConfiguration.Authentication?
        @usableFromInline
        let commandTimeout: TimeAmount
        @usableFromInline
        let blockingCommandTimeout: TimeAmount
        let clientName: String?
        let readOnly: Bool
        let clientRedirect: Bool
        let databaseNumber: Int
    }
    @usableFromInline
    struct PendingCommand: ~Copyable {
        @usableFromInline
        internal init(promise: consuming ValkeyPromise<RESPToken>, requestID: Int, deadline: NIODeadline) {
            self.promise = consume promise
            self.requestID = requestID
            self.deadline = deadline
        }

        @usableFromInline
        var promise: ValkeyPromise<RESPToken>
        let requestID: Int
        let deadline: NIODeadline
    }

    struct ValkeyDeadlineSchedule: NIOScheduledCallbackHandler {
        let channelHandler: NIOLoopBound<ValkeyChannelHandler>

        func handleScheduledCallback(eventLoop: some NIOCore.EventLoop) {
            let channelHandler = self.channelHandler.value
            switch channelHandler.stateMachine.hitDeadline(now: .now()) {
            case .failPendingCommandsAndClose(let context, var commands):
                while let command = commands.popFirst() {
                    command.promise.fail(ValkeyClientError(.timeout))
                }
                channelHandler.closeSubscriptionsAndConnection(context: context, error: ValkeyClientError(.timeout))
            case .reschedule(let deadline):
                channelHandler.scheduleDeadlineCallback(deadline: deadline)
            case .clearCallback:
                channelHandler.deadlineCallback = nil
                break
            }
        }
    }

    @usableFromInline
    typealias OutboundOut = ByteBuffer
    @usableFromInline
    typealias InboundIn = ByteBuffer

    static let simpleOk = RESPToken(validated: ByteBuffer(string: "+OK\r\n"))
    @usableFromInline
    /*private*/ let eventLoop: any EventLoop
    @usableFromInline
    /*private*/ var encoder = ValkeyCommandEncoder()
    @usableFromInline
    /*private*/ var stateMachine: StateMachine<ChannelHandlerContext>
    @usableFromInline
    /*private*/ var subscriptions: ValkeySubscriptions

    @usableFromInline
    private(set) var deadlineCallback: NIOScheduledCallback?

    private var decoder: NIOSingleStepByteToMessageProcessor<RESPTokenDecoder>
    private let logger: Logger
    @usableFromInline
    /* private*/ let configuration: Configuration

    /// Initialize a ValkeyChannelHandler
    init(configuration: Configuration, eventLoop: any EventLoop, logger: Logger) {
        self.configuration = configuration
        self.eventLoop = eventLoop
        self.subscriptions = .init(logger: logger)
        self.decoder = NIOSingleStepByteToMessageProcessor(RESPTokenDecoder())
        self.stateMachine = .init()
        self.logger = logger
    }

    /// Write valkey command/commands to channel
    /// - Parameters:
    ///   - request: Valkey command request
    ///   - promise: Promise to fulfill when command is complete
    @inlinable
    func write<Command: ValkeyCommand>(command: Command, continuation: consuming Continuation<RESPToken, any Error>, requestID: Int) {
        self.eventLoop.assertInEventLoop()
        let deadline: NIODeadline =
            command.isBlocking ? .now() + self.configuration.blockingCommandTimeout : .now() + self.configuration.commandTimeout
        let pendingCommand = PendingCommand(
            promise: ValkeyPromise.swift(continuation),
            requestID: requestID,
            deadline: deadline
        )
        switch self.stateMachine.sendCommand(pendingCommand) {
        case .sendCommand(let context):
            self.encoder.reset()
            command.encode(into: &self.encoder)
            let buffer = self.encoder.buffer
            context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
            if self.deadlineCallback == nil {
                self.scheduleDeadlineCallback(deadline: deadline)
            }

        case .throwError(let error, let command):
            command.promise.fail(error)
        }
    }

    @usableFromInline
    func write(request: consuming ValkeyRequest) {
        self.eventLoop.assertInEventLoop()
        let deadline = .now() + self.configuration.commandTimeout
        switch request {
        case .single(let buffer, let tokenPromise, let requestID):
            let pendingCommand = PendingCommand(promise: tokenPromise, requestID: requestID, deadline: deadline)
            switch self.stateMachine.sendCommand(pendingCommand) {
            case .sendCommand(let context):
                context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
                if self.deadlineCallback == nil {
                    scheduleDeadlineCallback(deadline: deadline)
                }
            case .throwError(let error, let command):
                command.promise.fail(error)
            }

        case .multiple(let buffer, var tokenPromises, let requestID):
            var pendingCommands = UniqueDeque<PendingCommand>()
            pendingCommands.reserveCapacity(tokenPromises.count)
            while let promise = tokenPromises.popFirst() {
                pendingCommands.append(
                    PendingCommand(promise: promise, requestID: requestID, deadline: deadline)
                )
            }
            switch self.stateMachine.sendCommands(pendingCommands) {
            case .sendCommand(let context):
                context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
                if self.deadlineCallback == nil {
                    scheduleDeadlineCallback(deadline: deadline)
                }
            case .throwError(let error, var pendingCommands):
                while let command = pendingCommands.popFirst() {
                    command.promise.fail(error)
                }
            }
        }
    }

    /// Add subscription, and call SUBSCRIBE command if required
    func subscribe(
        command: some ValkeyCommand,
        streamContinuation: ValkeySubscription.Continuation,
        filters: [ValkeySubscriptionFilter],
        promise: consuming ValkeyPromise<Int>,
        requestID: Int
    ) {
        self.eventLoop.assertInEventLoop()
        switch self.subscriptions.addSubscription(continuation: streamContinuation, filters: filters) {
        case .subscribe(let subscription, _):
            // TODO: currently ignoring returned filter array, as we have already constructed the subscribe command
            //   But it would be cool to build the subscribe command based on what filters we aren't subscribed to
            self.subscriptions.pushCommand(filters: subscription.filters)
            let subscriptionID = subscription.id
            // we use an optional to smuggle the ValkeyPromise in
            var promise: Optional<ValkeyPromise> = consume promise
            return self._execute(command: command, requestID: requestID).assumeIsolated().whenComplete { result in
                let promise = promise.take()!
                switch result {
                case .success:
                    promise.succeed(subscriptionID)
                case .failure(let error):
                    self.subscriptions.removeSubscription(id: subscriptionID)
                    self.subscriptions.removeUnhandledCommand()
                    promise.fail(error)
                }
            }

        case .doNothing(let subscriptionID):
            promise.succeed(subscriptionID)
        }
    }

    /// Remove subscription and if required call UNSUBSCRIBE command
    func unsubscribe(
        id: Int,
        promise: consuming ValkeyPromise<Void>,
        requestID: Int
    ) {
        self.eventLoop.assertInEventLoop()
        switch self.subscriptions.unsubscribe(id: id) {
        case .unsubscribe(let channels):
            self.performUnsubscribe(
                command: UNSUBSCRIBE(channels: channels),
                filters: channels.map { .channel($0) },
                promise: promise,
                requestID: requestID
            )
        case .punsubscribe(let patterns):
            self.performUnsubscribe(
                command: PUNSUBSCRIBE(patterns: patterns),
                filters: patterns.map { .pattern($0) },
                promise: promise,
                requestID: requestID
            )
        case .sunsubscribe(let shardChannels):
            self.performUnsubscribe(
                command: SUNSUBSCRIBE(shardchannels: shardChannels),
                filters: shardChannels.map { .shardChannel($0) },
                promise: promise,
                requestID: requestID
            )
        case .doNothing:
            promise.succeed(())
        }
    }

    func performUnsubscribe(
        command: some ValkeyCommand,
        filters: [ValkeySubscriptionFilter],
        promise: consuming ValkeyPromise<Void>,
        requestID: Int
    ) {
        self.subscriptions.pushCommand(filters: filters)
        // we use an optional to smuggle the ValkeyPromise in
        var promise: Optional<ValkeyPromise> = consume promise
        self._execute(command: command, requestID: requestID).assumeIsolated().whenComplete { result in
            let promise = promise.take()!
            switch result {
            case .success:
                promise.succeed(())
            case .failure(let error):
                self.subscriptions.removeUnhandledCommand()
                promise.fail(error)
            }
        }
    }

    @usableFromInline
    func setConnected(context: ChannelHandlerContext) {
        // Send initial HELLO command
        let helloCommand = HELLO(
            arguments: .init(
                protover: 3,
                auth: configuration.authentication.map { .init(username: $0.username, password: $0.password) },
                clientname: configuration.clientName
            )
        )
        // set client info
        let clientInfoLibName = CLIENT.SETINFO(attr: .libname(valkeySwiftLibraryName))
        let clientInfoLibVersion = CLIENT.SETINFO(attr: .libver(valkeySwiftLibraryVersion))

        var numberOfPendingCommands = 2
        self.encoder.reset()
        helloCommand.encode(into: &self.encoder)
        clientInfoLibName.encode(into: &self.encoder)
        clientInfoLibVersion.encode(into: &self.encoder)

        // Select DB if needed
        if self.configuration.databaseNumber > 0 {
            numberOfPendingCommands += 1
            SELECT(index: self.configuration.databaseNumber).encode(into: &self.encoder)
        }

        if self.configuration.readOnly {
            numberOfPendingCommands += 1
            READONLY().encode(into: &self.encoder)
        }

        if self.configuration.clientRedirect {
            numberOfPendingCommands += 1
            CLIENT.CAPA(capabilities: ["redirect"]).encode(into: &self.encoder)
        }

        let promise = ValkeyPromise.nio(self.eventLoop.makePromise(of: RESPToken.self))

        let deadline = .now() + self.configuration.commandTimeout
        context.writeAndFlush(self.wrapOutboundOut(self.encoder.buffer), promise: nil)
        self.scheduleDeadlineCallback(deadline: deadline)

        var pendingCommands = UniqueDeque<PendingCommand>()
        pendingCommands.reserveCapacity(numberOfPendingCommands)
        for _ in 0..<numberOfPendingCommands {
            pendingCommands.append(.init(promise: .forget, requestID: 0, deadline: deadline))
        }

        self.stateMachine.setConnected(
            context: context,
            pendingHelloCommand: PendingCommand(promise: consume promise, requestID: 0, deadline: deadline),
            pendingCommands: pendingCommands
        )
    }

    @usableFromInline
    func waitOnActive() -> EventLoopFuture<Void> {
        switch self.stateMachine.waitOnActive() {
        case .waitForPromise(let promise):
            return promise.futureResult.map { _ in return }
        case .reportedClosed(let error):
            return self.eventLoop.makeFailedFuture(error ?? ValkeyClientError(.connectionClosed))
        case .done:
            return self.eventLoop.makeSucceededVoidFuture()
        }
    }

    @usableFromInline
    func handlerAdded(context: ChannelHandlerContext) {
        if context.channel.isActive {
            setConnected(context: context)
            self.logger.trace("Handler added when channel active.")
        }
    }

    @usableFromInline
    func handlerRemoved(context: ChannelHandlerContext) {
        self.setClosed()
    }

    @usableFromInline
    func channelActive(context: ChannelHandlerContext) {
        setConnected(context: context)
        self.logger.trace("Channel active.")
    }

    @usableFromInline
    func channelInactive(context: ChannelHandlerContext) {
        do {
            try self.decoder.finishProcessing(seenEOF: true) { token in
                self.handleToken(context: context, token: token)
            }
        } catch let error as RESPParsingError {
            self.handleError(context: context, error: ValkeyClientError(.respParsingError, error: error))
        } catch {
            preconditionFailure("Expected to only get RESPParsingError from the RESPTokenDecoder.")
        }
        self.setClosed()

        self.logger.trace("Channel inactive.")
    }

    @usableFromInline
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let buffer = self.unwrapInboundIn(data)

        do {
            try self.decoder.process(buffer: buffer) { token in
                self.handleToken(context: context, token: token)
            }
        } catch let error as RESPParsingError {
            self.handleError(context: context, error: ValkeyClientError(.respParsingError, error: error))
        } catch {
            preconditionFailure("Expected to only get RESPParsingError from the RESPTokenDecoder.")
        }
    }

    @usableFromInline
    func cancel(requestID: Int) {
        self.eventLoop.assertInEventLoop()
        switch self.stateMachine.cancel(requestID: requestID) {
        case .failPendingCommandsAndClose(let context, var cancelAction):
            while let command = cancelAction.cancelled.popFirst() {
                command.promise.fail(ValkeyClientError.init(.cancelled))
            }
            while let command = cancelAction.connectionClosedDueToCancellation.popFirst() {
                command.promise.fail(ValkeyClientError.init(.connectionClosedDueToCancellation))
            }
            self.closeSubscriptionsAndConnection(context: context, error: ValkeyClientError(.cancelled))

        case .doNothing:
            break
        }

    }

    func handleToken(context: ChannelHandlerContext, token: RESPToken) {
        switch token.identifier {
        case .simpleError, .bulkError:
            switch self.stateMachine.receivedResponse(token: token) {
            case .respond(let command, let deadlineAction):
                self.processDeadlineCallbackAction(action: deadlineAction)
                command.promise.fail(ValkeyClientError(.commandError, message: token.errorString.map { String(buffer: $0) }))
            case .respondAndClose(let command, let error):
                let commandError = ValkeyClientError(.commandError, message: token.errorString.map { String(buffer: $0) })
                command.promise.fail(commandError)
                self.closeSubscriptionsAndConnection(context: context, error: error)
            case .closeWithError(let error):
                self.closeSubscriptionsAndConnection(context: context, error: error)
            }

        case .push:
            // If subscription notify throws an error then assume something has gone wrong
            // and close the channel with the error
            do {
                if try self.subscriptions.notify(token) == true {
                    switch self.stateMachine.receivedResponse(token: token) {
                    case .respond(let command, let deadlineAction):
                        self.processDeadlineCallbackAction(action: deadlineAction)
                        command.promise.succeed(Self.simpleOk)
                    case .respondAndClose(let command, let error):
                        command.promise.succeed(Self.simpleOk)
                        self.closeSubscriptionsAndConnection(context: context, error: error)
                    case .closeWithError(let error):
                        self.closeSubscriptionsAndConnection(context: context, error: error)
                    }
                }
            } catch {
                self.closeSubscriptionsAndConnection(context: context, error: error)
            }

        case .simpleString,
            .bulkString,
            .verbatimString,
            .integer,
            .double,
            .boolean,
            .null,
            .bigNumber,
            .array,
            .map,
            .set,
            .attribute:
            switch self.stateMachine.receivedResponse(token: token) {
            case .respond(let command, let deadlineAction):
                self.processDeadlineCallbackAction(action: deadlineAction)
                command.promise.succeed(token)
            case .respondAndClose(let command, let error):
                command.promise.succeed(token)
                self.closeSubscriptionsAndConnection(context: context, error: error)
            case .closeWithError(let error):
                self.closeSubscriptionsAndConnection(context: context, error: error)
            }
        }
    }

    func handleError(context: ChannelHandlerContext, error: ValkeyClientError) {
        self.logger.debug("ValkeyCommandHandler: ERROR", metadata: ["error": "\(error)"])
        switch self.stateMachine.close() {
        case .failPendingCommandsAndClose(let context, var commands):
            while let command = commands.popFirst() {
                command.promise.fail(error)
            }
            self.closeSubscriptionsAndConnection(context: context, error: error)
        case .doNothing:
            // only call fireErrorCaught here as it is called from `closeSubscriptionsAndConnection`
            context.fireErrorCaught(error)
            break
        }
    }

    @usableFromInline
    func scheduleDeadlineCallback(deadline: NIODeadline) {
        self.deadlineCallback = try? self.eventLoop.scheduleCallback(
            at: deadline,
            handler: ValkeyDeadlineSchedule(channelHandler: .init(self, eventLoop: self.eventLoop))
        )
    }

    func processDeadlineCallbackAction(action: StateMachine<ChannelHandlerContext>.DeadlineCallbackAction) {
        switch action {
        case .cancel:
            self.deadlineCallback?.cancel()
            self.deadlineCallback = nil
        case .reschedule(let deadline):
            self.scheduleDeadlineCallback(deadline: deadline)
        case .doNothing:
            break
        }
    }

    private func closeSubscriptionsAndConnection(context: ChannelHandlerContext, error: ValkeyClientError? = nil) {
        if let error {
            context.fireErrorCaught(error)
            self.subscriptions.close(error: error)
        } else {
            self.subscriptions.close(error: ValkeyClientError(.connectionClosed))
        }
        context.close(promise: nil)
    }

    // Function used internally by subscribe
    func _execute<Command: ValkeyCommand>(command: Command, requestID: Int) -> EventLoopFuture<RESPToken> {
        self.eventLoop.assertInEventLoop()
        self.encoder.reset()
        command.encode(into: &self.encoder)
        let buffer = self.encoder.buffer

        let promise = eventLoop.makePromise(of: RESPToken.self)
        self.write(request: ValkeyRequest.single(buffer: buffer, promise: .nio(promise), id: requestID))
        return promise.futureResult
    }

    private func setClosed() {
        switch self.stateMachine.setClosed() {
        case .failPendingCommandsAndSubscriptions(var commands):
            while let command = commands.popFirst() {
                command.promise.fail(ValkeyClientError.init(.connectionClosed))
            }
            self.subscriptions.close(error: ValkeyClientError.init(.connectionClosed))
            self.deadlineCallback?.cancel()
        case .doNothing:
            break
        }
    }

    func triggerGracefulShutdown() {
        switch self.stateMachine.triggerGracefulShutdown() {
        case .closeConnection(let context):
            context.close(mode: .all, promise: nil)
        case .doNothing:
            break
        }
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyChannelHandler.Configuration {
    init(_ other: ValkeyConnectionConfiguration) {
        self.init(
            authentication: other.authentication,
            commandTimeout: .init(other.commandTimeout),
            blockingCommandTimeout: .init(other.blockingCommandTimeout),
            clientName: other.clientName,
            readOnly: other.readOnly,
            clientRedirect: other.enableClientCapaRedirect,
            databaseNumber: other.databaseNumber
        )
    }
}
