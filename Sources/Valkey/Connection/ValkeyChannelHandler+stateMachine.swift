//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

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
            case closed(ValkeyClientError?)

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
        struct ActiveStateCancelAction: ~Copyable {
            var cancelled: UniqueDeque<PendingCommand>
            var connectionClosedDueToCancellation: UniqueDeque<PendingCommand>
        }

        @usableFromInline
        struct ActiveState: ~Copyable {
            let context: Context
            var pendingCommands: UniqueDeque<PendingCommand>

            consuming func cancel(requestID: Int) -> ActiveStateCancelAction {
                var withRequestID = UniqueDeque<PendingCommand>()
                var withoutRequestID = UniqueDeque<PendingCommand>()
                while let command = self.pendingCommands.popFirst() {
                    if command.requestID == requestID {
                        withRequestID.append(command)
                    } else {
                        withoutRequestID.append(command)
                    }
                }
                return ActiveStateCancelAction(cancelled: withRequestID, connectionClosedDueToCancellation: withoutRequestID)
            }
        }

        @usableFromInline
        struct ConnectedState: ~Copyable {
            let context: Context
            let pendingHelloCommand: PendingCommand
            var pendingCommands: UniqueDeque<PendingCommand>

            init(
                context: Context,
                pendingHelloCommand: consuming PendingCommand,
                pendingCommands: consuming UniqueDeque<PendingCommand>
            ) {
                self.context = context
                self.pendingHelloCommand = pendingHelloCommand
                self.pendingCommands = pendingCommands
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
        mutating func setConnected(
            context: Context,
            pendingHelloCommand: consuming PendingCommand,
            pendingCommands: consuming UniqueDeque<PendingCommand>
        ) {
            switch consume self.state {
            case .initialized:
                self = .connected(
                    ConnectedState(
                        context: context,
                        pendingHelloCommand: pendingHelloCommand,
                        pendingCommands: pendingCommands
                    )
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
        enum SendCommandAction: ~Copyable {
            case sendCommand(Context)
            case throwError(ValkeyClientError, PendingCommand)
        }

        /// handler wants to send a command
        @usableFromInline
        mutating func sendCommand(_ pendingCommand: consuming PendingCommand) -> SendCommandAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot send command when initialized")
            case .connected:
                preconditionFailure("Cannot send command when in connected state")
            case .active(var state):
                let context = state.context
                state.pendingCommands.append(pendingCommand)
                self = .active(state)
                return .sendCommand(context)
            case .closing(let state):
                self = .closing(state)
                return .throwError(ValkeyClientError(.connectionClosing), pendingCommand)
            case .closed(let error):
                self = .closed(error)
                return .throwError(ValkeyClientError(.connectionClosed), pendingCommand)
            }
        }

        @usableFromInline
        enum SendCommandsAction: ~Copyable {
            case sendCommand(Context)
            case throwError(ValkeyClientError, UniqueDeque<PendingCommand>)
        }

        /// handler wants to send pipelined commands
        @usableFromInline
        mutating func sendCommands(_ pendingCommands: consuming UniqueDeque<PendingCommand>) -> SendCommandsAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot send command when initialized")
            case .connected:
                preconditionFailure("Cannot send command when in connected state")
            case .active(var state):
                let context = state.context
                while let command = pendingCommands.popFirst() {
                    state.pendingCommands.append(command)
                }
                self = .active(state)
                return .sendCommand(context)
            case .closing(let state):
                self = .closing(state)
                return .throwError(ValkeyClientError(.connectionClosing), pendingCommands)
            case .closed(let error):
                self = .closed(error)
                return .throwError(ValkeyClientError(.connectionClosed), pendingCommands)
            }
        }

        @usableFromInline
        enum DeadlineCallbackAction {
            case cancel
            case reschedule(NIODeadline)
            case doNothing
        }

        @usableFromInline
        enum ReceivedResponseAction: ~Copyable {
            case respond(PendingCommand, DeadlineCallbackAction)
            case respondAndClose(PendingCommand, ValkeyClientError?)
            case closeWithError(ValkeyClientError)
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
                    let error = ValkeyClientError(.commandError, message: String(buffer: message))
                    self = .closed(error)
                    return .respondAndClose(state.pendingHelloCommand, error)
                default:
                    self = .active(ActiveState(context: state.context, pendingCommands: state.pendingCommands))
                    return .respond(state.pendingHelloCommand, .cancel)
                }
            case .active(let state):
                var pendingCommands = state.pendingCommands
                let context = state.context
                guard let command = pendingCommands.popFirst() else {
                    self = .closed(nil)
                    return .closeWithError(ValkeyClientError(.unsolicitedToken, message: "Received a token without having sent a command"))
                }
                let nextCommandDeadline = pendingCommands.isEmpty ? nil : pendingCommands[pendingCommands.startIndex].deadline
                self = .active(ActiveState(context: context, pendingCommands: pendingCommands))
                let deadlineCallback: DeadlineCallbackAction =
                    if let nextCommandDeadline {
                        if nextCommandDeadline < command.deadline {
                            // if the next command has an earlier deadline than the current then reschedule the callback
                            .reschedule(nextCommandDeadline)
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
                let nextCommandDeadline = state.pendingCommands.isEmpty ? nil : state.pendingCommands[state.pendingCommands.startIndex].deadline
                if let nextCommandDeadline {
                    self = .closing(state)
                    let deadlineCallback: DeadlineCallbackAction =
                        if nextCommandDeadline < command.deadline {
                            // if the next command has an earlier deadline than the current then reschedule the callback
                            .reschedule(nextCommandDeadline)
                        } else {
                            // otherwise do nothing
                            .doNothing
                        }
                    return .respond(command, deadlineCallback)
                } else {
                    self = .closed(nil)
                    return .respondAndClose(command, nil)
                }
            case .closed(let error):
                guard let error else {
                    preconditionFailure("Cannot receive command on closed connection with no error")
                }
                self = .closed(error)
                return .closeWithError(error)
            }
        }

        @usableFromInline
        enum WaitOnActiveAction {
            case waitForPromise(EventLoopPromise<RESPToken>)
            case reportedClosed(ValkeyClientError?)
            case done
        }

        mutating func waitOnActive() -> WaitOnActiveAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot wait until connection has succeeded")
            case .connected(let state):
                let pendingCommands = state.pendingCommands
                let pendingHelloCommand = state.pendingHelloCommand

                switch consume pendingHelloCommand.promise {
                case .nio(let promise):
                    self = .connected(
                        ConnectedState(
                            context: state.context,
                            pendingHelloCommand: .init(
                                promise: .nio(promise),
                                requestID: pendingHelloCommand.requestID,
                                deadline: pendingHelloCommand.deadline
                            ),
                            pendingCommands: pendingCommands
                        )
                    )
                    return .waitForPromise(promise)
                case .swift:
                    preconditionFailure("Connected state cannot be setup with a Swift continuation")

                case .forget:
                    preconditionFailure("Connected state cannot be setup with a Swift continuation")
                }
            case .active(let state):
                self = .active(state)
                return .done
            case .closing(let state):
                self = .closing(state)
                return .reportedClosed(nil)
            case .closed(let error):
                self = .closed(error)
                return .reportedClosed(error)
            }
        }

        @usableFromInline
        enum HitDeadlineAction: ~Copyable {
            case failPendingCommandsAndClose(Context, UniqueDeque<PendingCommand>)
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
                    self = .closed(ValkeyClientError(.timeout))
                    var pendingCommands = state.pendingCommands
                    pendingCommands.prepend(state.pendingHelloCommand)
                    return .failPendingCommandsAndClose(state.context, pendingCommands)
                } else {
                    let deadline = state.pendingHelloCommand.deadline
                    self = .connected(state)
                    return .reschedule(deadline)
                }
            case .active(let state):
                fatalError()
//                let context = state.context
//                let pendingCommands = consume state.pendingCommands
//                let firstCommandDeadline: NIODeadline? = if pendingCommands.isEmpty { nil } else { pendingCommands[pendingCommands.startIndex].deadline }
//                if let firstCommandDeadline {
//                    if firstCommandDeadline <= now {
//                        self = .closed(ValkeyClientError(.timeout))
//                        return .failPendingCommandsAndClose(context, consume pendingCommands)
//                    } else {
//                        self = .active(ActiveState(context: context, pendingCommands: consume pendingCommands))
//                        return .reschedule(firstCommandDeadline)
//                    }
//                } else {
//                    self = .active(ActiveState(context: context, pendingCommands: pendingCommands))
//                    return .clearCallback
//                }
            case .closing(let state):
                fatalError()
//                let context = state.context
//                let pendingCommands = state.pendingCommands
//                let firstCommandDeadline = pendingCommands.isEmpty ? nil : pendingCommands[pendingCommands.startIndex].deadline
//                guard let firstCommandDeadline else {
//                    preconditionFailure("Cannot be in closing state with no pending commands")
//                }
//                if firstCommandDeadline <= now {
//                    self = .closed(ValkeyClientError(.timeout))
//                    return .failPendingCommandsAndClose(context, pendingCommands)
//                } else {
//                    self = .closing(ActiveState(context: context, pendingCommands: pendingCommands))
//                    return .reschedule(firstCommandDeadline)
//                }
            case .closed(let error):
                self = .closed(error)
                return .clearCallback
            }
        }

        @usableFromInline
        enum CancelAction: ~Copyable {
            case failPendingCommandsAndClose(Context, cancel: ActiveStateCancelAction)
            case doNothing
        }

        /// handler wants to cancel a command
        @usableFromInline
        mutating func cancel(requestID: Int) -> CancelAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot cancel when initialized")
            case .connected:
                preconditionFailure("Cannot cancel while in connected state")
            case .active(let state):
                let context = state.context
                let cancelAction = state.cancel(requestID: requestID)
                if cancelAction.cancelled.count > 0 {
                    self = .closed(ValkeyClientError(.cancelled))
                    return .failPendingCommandsAndClose(
                        context,
                        cancel: cancelAction
                    )
                } else {
                    self = .active(ActiveState(context: context, pendingCommands: cancelAction.connectionClosedDueToCancellation))
                    return .doNothing
                }
            case .closing(let state):
                let context = state.context
                let cancelAction = state.cancel(requestID: requestID)
                if cancelAction.cancelled.count > 0 {
                    self = .closed(ValkeyClientError(.cancelled))
                    return .failPendingCommandsAndClose(
                        context,
                        cancel: cancelAction
                    )
                } else {
                    self = .closing(ActiveState(context: context, pendingCommands: cancelAction.connectionClosedDueToCancellation))
                    return .doNothing
                }
            case .closed(let error):
                self = .closed(error)
                return .doNothing
            }
        }

        @usableFromInline
        enum TriggerGracefulShutdownAction {
            case closeConnection(Context)
            case doNothing
        }
        /// Want to gracefully shutdown the handler
        @usableFromInline
        mutating func triggerGracefulShutdown() -> TriggerGracefulShutdownAction {
            switch consume self.state {
            case .initialized:
                self = .closed(nil)
                return .doNothing
            case .connected(let state):
                var pendingCommands = state.pendingCommands
                pendingCommands.prepend(state.pendingHelloCommand)
                self = .closing(ActiveState(context: state.context, pendingCommands: pendingCommands))
                return .doNothing
            case .active(let state):
                if state.pendingCommands.count > 0 {
                    self = .closing(ActiveState(context: state.context, pendingCommands: state.pendingCommands))
                    return .doNothing
                } else {
                    self = .closed(nil)
                    return .closeConnection(state.context)
                }
            case .closing(let state):
                self = .closing(state)
                return .doNothing
            case .closed(let error):
                self = .closed(error)
                return .doNothing
            }
        }

        @usableFromInline
        enum CloseAction: ~Copyable {
            case failPendingCommandsAndClose(Context, UniqueDeque<PendingCommand>)
            case doNothing
        }
        /// Want to close the connection
        @usableFromInline
        mutating func close() -> CloseAction {
            switch consume self.state {
            case .initialized:
                self = .closed(nil)
                return .doNothing
            case .connected(let state):
                self = .closed(nil)
                var pendingCommands = state.pendingCommands
                pendingCommands.prepend(state.pendingHelloCommand)
                return .failPendingCommandsAndClose(state.context, pendingCommands)
            case .active(let state):
                self = .closed(nil)
                return .failPendingCommandsAndClose(state.context, state.pendingCommands)
            case .closing(let state):
                self = .closed(nil)
                return .failPendingCommandsAndClose(state.context, state.pendingCommands)
            case .closed(let error):
                self = .closed(error)
                return .doNothing
            }
        }

        @usableFromInline
        enum SetClosedAction: ~Copyable {
            case failPendingCommandsAndSubscriptions(UniqueDeque<PendingCommand>)
            case doNothing
        }

        /// The connection has been closed
        @usableFromInline
        mutating func setClosed() -> SetClosedAction {
            switch consume self.state {
            case .initialized:
                self = .closed(nil)
                return .doNothing
            case .connected(let state):
                self = .closed(nil)
                var pendingCommands = state.pendingCommands
                pendingCommands.prepend(state.pendingHelloCommand)
                return .failPendingCommandsAndSubscriptions(pendingCommands)
            case .active(let state):
                self = .closed(nil)
                return .failPendingCommandsAndSubscriptions(state.pendingCommands)
            case .closing(let state):
                self = .closed(nil)
                return .failPendingCommandsAndSubscriptions(state.pendingCommands)
            case .closed(let error):
                self = .closed(error)
                return .doNothing
            }
        }

        private static var initialized: Self {
            StateMachine(.initialized)
        }

        private static func connected(_ state: consuming ConnectedState) -> Self {
            StateMachine(.connected(state))
        }

        private static func active(_ state: consuming ActiveState) -> Self {
            StateMachine(.active(state))
        }

        private static func closing(_ state: consuming ActiveState) -> Self {
            StateMachine(.closing(state))
        }

        private static func closed(_ error: ValkeyClientError?) -> Self {
            StateMachine(.closed(error))
        }
    }
}
