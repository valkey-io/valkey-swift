//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift project
//
// Copyright (c) 2025 the valkey-swift authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See valkey-swift/CONTRIBUTORS.txt for the list of valkey-swift authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import DequeModule
import NIOCore

@available(valkeySwift 1.0, *)
extension ValkeyChannelHandler {
    @usableFromInline
    struct StateMachine<Context>: ~Copyable {
        @usableFromInline
        enum State: ~Copyable {
            case initialized
            case connected(ConnectedState)
            case active(ActiveState)
            case closing(ActiveState)
            case closed

            @usableFromInline
            var description: String {
                borrowing get {
                    switch self {
                    case .initialized: "initialized"
                    case .connected: "connected"
                    case .active: "active"
                    case .closing: "closing"
                    case .closed: "closed"
                    }
                }
            }
        }
        @usableFromInline
        var state: State

        @usableFromInline
        struct ActiveState {
            let context: Context
            var pendingCommands: Deque<PendingCommand>

            func cancel(requestID: Int) -> (cancel: [PendingCommand], connectionClosedDueToCancellation: [PendingCommand]) {
                var withRequestID = [PendingCommand]()
                var withoutRequestID = [PendingCommand]()
                for command in pendingCommands {
                    if command.requestID == requestID {
                        withRequestID.append(command)
                    } else {
                        withoutRequestID.append(command)
                    }
                }
                return (withRequestID, withoutRequestID)
            }
        }

        @usableFromInline
        struct ConnectedState {
            let context: Context
            var pendingHelloCommand: PendingCommand

            func cancel(requestID: Int) -> PendingCommand? {
                if pendingHelloCommand.requestID == requestID {
                    return pendingHelloCommand
                }
                return nil
            }
        }

        init() {
            self.state = .initialized
        }

        private init(_ state: consuming State) {
            self.state = state
        }

        /// handler has become active
        @usableFromInline
        mutating func setConnected(context: Context, pendingHelloCommand: PendingCommand) {
            switch consume self.state {
            case .initialized:
                self = .connected(
                    .init(context: context, pendingHelloCommand: pendingHelloCommand)
                )
            case .connected:
                preconditionFailure("Cannot set connected state when state is connected")
            case .active:
                preconditionFailure("Cannot set connected state when state is active")
            case .closing:
                preconditionFailure("Cannot set connected state when state is closing")
            case .closed:
                preconditionFailure("Cannot set connected state when state is closed")
            }
        }

        @usableFromInline
        enum SendCommandAction {
            case sendCommand(Context)
            case throwError(Error)
        }

        /// handler wants to send a command
        @usableFromInline
        mutating func sendCommand(_ pendingCommand: PendingCommand) -> SendCommandAction {
            self.sendCommands(CollectionOfOne(pendingCommand))
        }

        /// handler wants to send pipelined commands
        @usableFromInline
        mutating func sendCommands(_ pendingCommands: some Collection<PendingCommand>) -> SendCommandAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot send command when initialized")
            case .connected:
                preconditionFailure("Cannot send command when in connected state")
            case .active(var state):
                state.pendingCommands.append(contentsOf: pendingCommands)
                self = .active(state)
                return .sendCommand(state.context)
            case .closing(let state):
                self = .closing(state)
                return .throwError(ValkeyClientError(.connectionClosing))
            case .closed:
                self = .closed
                return .throwError(ValkeyClientError(.connectionClosed))
            }
        }

        @usableFromInline
        enum DeadlineCallbackAction {
            case cancel
            case reschedule(NIODeadline)
            case doNothing
        }

        @usableFromInline
        enum ReceivedResponseAction {
            case respond(PendingCommand, DeadlineCallbackAction)
            case respondAndClose(PendingCommand, Error?)
            case closeWithError(Error)
        }

        /// handler wants to send a command
        @usableFromInline
        mutating func receivedResponse(token: RESPToken) -> ReceivedResponseAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot send command when initialized")
            case .connected(let state):
                switch token.value {
                case .bulkError(let message), .simpleError(let message):
                    self = .closed
                    let error = ValkeyClientError(.commandError, message: String(buffer: message))
                    return .respondAndClose(state.pendingHelloCommand, error)
                default:
                    self = .active(.init(context: state.context, pendingCommands: .init()))
                    return .respond(state.pendingHelloCommand, .cancel)
                }
            case .active(var state):
                guard let command = state.pendingCommands.popFirst() else {
                    self = .closed
                    return .closeWithError(ValkeyClientError(.unsolicitedToken, message: "Received a token without having sent a command"))
                }
                self = .active(state)
                let deadlineCallback: DeadlineCallbackAction =
                    if let nextCommand = state.pendingCommands.first {
                        if nextCommand.deadline < command.deadline {
                            // if the next command has an earlier deadline than the current then reschedule the callback
                            .reschedule(nextCommand.deadline)
                        } else {
                            // otherwise do nothing
                            .doNothing
                        }
                    } else {
                        // if there are no more commands cancel the callback
                        .cancel
                    }
                return .respond(command, deadlineCallback)
            case .closing(var state):
                guard let command = state.pendingCommands.popFirst() else {
                    preconditionFailure("Cannot be in closing state with no pending commands")
                }
                if let nextCommand = state.pendingCommands.first {
                    self = .closing(state)
                    let deadlineCallback: DeadlineCallbackAction =
                        if nextCommand.deadline < command.deadline {
                            // if the next command has an earlier deadline than the current then reschedule the callback
                            .reschedule(nextCommand.deadline)
                        } else {
                            // otherwise do nothing
                            .doNothing
                        }
                    return .respond(command, deadlineCallback)
                } else {
                    self = .closed
                    return .respondAndClose(command, nil)
                }
            case .closed:
                preconditionFailure("Cannot receive command on closed connection")
            }
        }

        @usableFromInline
        enum WaitOnActiveAction {
            case waitForPromise(EventLoopPromise<RESPToken>)
            case done
            case close
        }

        mutating func waitOnActive() -> WaitOnActiveAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot wait until connection has succeeded")
            case .connected(let state):
                switch state.pendingHelloCommand.promise {
                case .nio(let promise):
                    self = .connected(state)
                    return .waitForPromise(promise)
                case .swift:
                    preconditionFailure("Connected state cannot be setup with a Swift continuation")
                }
            case .active(let state):
                self = .active(state)
                return .done
            case .closing(let state):
                self = .closing(state)
                return .done
            case .closed:
                self = .closed
                return .close
            }
        }

        @usableFromInline
        enum HitDeadlineAction {
            case failPendingCommandsAndClose(Context, Deque<PendingCommand>)
            case reschedule(NIODeadline)
            case clearCallback
        }

        @usableFromInline
        mutating func hitDeadline(now: NIODeadline) -> HitDeadlineAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot cancel when initialized")
            case .connected(let state):
                if state.pendingHelloCommand.deadline <= now {
                    self = .closed
                    return .failPendingCommandsAndClose(state.context, [state.pendingHelloCommand])
                } else {
                    self = .connected(state)
                    return .reschedule(state.pendingHelloCommand.deadline)
                }
            case .active(let state):
                if let firstCommand = state.pendingCommands.first {
                    if firstCommand.deadline <= now {
                        self = .closed
                        return .failPendingCommandsAndClose(state.context, state.pendingCommands)
                    } else {
                        self = .active(state)
                        return .reschedule(firstCommand.deadline)
                    }
                } else {
                    self = .active(state)
                    return .clearCallback
                }
            case .closing(let state):
                guard let firstCommand = state.pendingCommands.first else {
                    preconditionFailure("Cannot be in closing state with no pending commands")
                }
                if firstCommand.deadline <= now {
                    self = .closed
                    return .failPendingCommandsAndClose(state.context, state.pendingCommands)
                } else {
                    self = .closing(state)
                    return .reschedule(firstCommand.deadline)
                }
            case .closed:
                self = .closed
                return .clearCallback
            }
        }

        @usableFromInline
        enum CancelAction {
            case failPendingCommandsAndClose(Context, cancel: [PendingCommand], closeConnectionDueToCancel: [PendingCommand])
            case doNothing
        }

        /// handler wants to send a command
        @usableFromInline
        mutating func cancel(requestID: Int) -> CancelAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot cancel when initialized")
            case .connected(let state):
                if let command = state.cancel(requestID: requestID) {
                    self = .closed
                    return .failPendingCommandsAndClose(
                        state.context,
                        cancel: [command],
                        closeConnectionDueToCancel: []
                    )
                } else {
                    self = .connected(state)
                    return .doNothing
                }
            case .active(let state):
                let (cancel, closeConnectionDueToCancel) = state.cancel(requestID: requestID)
                if cancel.count > 0 {
                    self = .closed
                    return .failPendingCommandsAndClose(
                        state.context,
                        cancel: cancel,
                        closeConnectionDueToCancel: closeConnectionDueToCancel
                    )
                } else {
                    self = .active(state)
                    return .doNothing
                }
            case .closing(let state):
                let (cancel, closeConnectionDueToCancel) = state.cancel(requestID: requestID)
                if cancel.count > 0 {
                    self = .closed
                    return .failPendingCommandsAndClose(
                        state.context,
                        cancel: cancel,
                        closeConnectionDueToCancel: closeConnectionDueToCancel
                    )
                } else {
                    self = .closing(state)
                    return .doNothing
                }
            case .closed:
                self = .closed
                return .doNothing
            }
        }

        @usableFromInline
        enum GracefulShutdownAction {
            case waitForPendingCommands(Context)
            case closeConnection(Context)
            case doNothing
        }
        /// Want to gracefully shutdown the handler
        @usableFromInline
        mutating func gracefulShutdown() -> GracefulShutdownAction {
            switch consume self.state {
            case .initialized:
                self = .closed
                return .doNothing
            case .connected(let state):
                self = .closing(.init(context: state.context, pendingCommands: [state.pendingHelloCommand]))
                return .waitForPendingCommands(state.context)
            case .active(let state):
                if state.pendingCommands.count > 0 {
                    self = .closing(.init(context: state.context, pendingCommands: state.pendingCommands))
                    return .waitForPendingCommands(state.context)
                } else {
                    self = .closed
                    return .closeConnection(state.context)
                }
            case .closing(let state):
                self = .closing(state)
                return .doNothing
            case .closed:
                self = .closed
                return .doNothing
            }
        }

        @usableFromInline
        enum CloseAction {
            case failPendingCommandsAndClose(Context, Deque<PendingCommand>)
            case doNothing
        }
        /// Want to close the connection
        @usableFromInline
        mutating func close() -> CloseAction {
            switch consume self.state {
            case .initialized:
                self = .closed
                return .doNothing
            case .connected(let state):
                self = .closed
                return .failPendingCommandsAndClose(state.context, [state.pendingHelloCommand])
            case .active(let state):
                self = .closed
                return .failPendingCommandsAndClose(state.context, state.pendingCommands)
            case .closing(let state):
                self = .closed
                return .failPendingCommandsAndClose(state.context, state.pendingCommands)
            case .closed:
                self = .closed
                return .doNothing
            }
        }

        @usableFromInline
        enum SetClosedAction {
            case failPendingCommandsAndSubscriptions(Deque<PendingCommand>)
            case doNothing
        }

        /// The connection has been closed
        @usableFromInline
        mutating func setClosed() -> SetClosedAction {
            switch consume self.state {
            case .initialized:
                self = .closed
                return .doNothing
            case .connected(let state):
                self = .closed
                return .failPendingCommandsAndSubscriptions([state.pendingHelloCommand])
            case .active(let state):
                self = .closed
                return .failPendingCommandsAndSubscriptions(state.pendingCommands)
            case .closing(let state):
                self = .closed
                return .failPendingCommandsAndSubscriptions(state.pendingCommands)
            case .closed:
                self = .closed
                return .doNothing
            }
        }

        private static var initialized: Self {
            StateMachine(.initialized)
        }

        private static func connected(_ state: ConnectedState) -> Self {
            StateMachine(.connected(state))
        }

        private static func active(_ state: ActiveState) -> Self {
            StateMachine(.active(state))
        }

        private static func closing(_ state: ActiveState) -> Self {
            StateMachine(.closing(state))
        }

        private static var closed: Self {
            StateMachine(.closed)
        }
    }
}
