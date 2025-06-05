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

import DequeModule
import NIOCore

extension ValkeyChannelHandler {
    @usableFromInline
    struct StateMachine<Context>: ~Copyable {
        @usableFromInline
        enum State: ~Copyable {
            case initializing
            case active(ActiveState)
            case closing(ActiveState)
            case closed

            @usableFromInline
            var description: String {
                borrowing get {
                    switch self {
                    case .initializing: "initializing"
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

        init() {
            self.state = .initializing
        }

        private init(_ state: consuming State) {
            self.state = state
        }

        /// handler has become active
        @usableFromInline
        mutating func setActive(context: Context) {
            switch consume self.state {
            case .initializing:
                self = .active(.init(context: context, pendingCommands: []))
            case .active:
                preconditionFailure("Cannot set active state when state is active")
            case .closing:
                preconditionFailure("Cannot set active state when state is closing")
            case .closed:
                preconditionFailure("Cannot set active state when state is closed")
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
            case .initializing:
                preconditionFailure("Cannot send command when initializing")
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
        enum ReceivedResponseAction {
            case respond(PendingCommand)
            case respondAndClose(PendingCommand)
            case closeWithError(Error)
        }

        /// handler wants to send a command
        @usableFromInline
        mutating func receivedResponse() -> ReceivedResponseAction {
            switch consume self.state {
            case .initializing:
                preconditionFailure("Cannot send command when initializing")
            case .active(var state):
                guard let command = state.pendingCommands.popFirst() else {
                    self = .closed
                    return .closeWithError(ValkeyClientError(.unsolicitedToken, message: "Received a token without having sent a command"))
                }
                self = .active(state)
                return .respond(command)
            case .closing(var state):
                guard let command = state.pendingCommands.popFirst() else {
                    preconditionFailure("Cannot be in closing state with no pending commands")
                }
                if state.pendingCommands.count == 0 {
                    self = .closed
                    return .respondAndClose(command)
                } else {
                    self = .closing(state)
                    return .respond(command)
                }
            case .closed:
                preconditionFailure("Cannot receive command on closed connection")
            }
        }

        @usableFromInline
        enum HitDeadlineAction {
            case failPendingCommandsAndClose(Context, Deque<PendingCommand>)
            case reschedule(NIODeadline)
            case doNothing
        }
        @usableFromInline
        mutating func hitDeadline(now: NIODeadline) -> HitDeadlineAction {
            switch consume self.state {
            case .initializing:
                preconditionFailure("Cannot cancel when initializing")
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
                    return .doNothing
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
                return .doNothing
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
            case .initializing:
                preconditionFailure("Cannot cancel when initializing")
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
            case .initializing:
                self = .closed
                return .doNothing
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
            case .initializing:
                self = .closed
                return .doNothing
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
            case .initializing:
                self = .closed
                return .doNothing
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

        private static var initializing: Self {
            StateMachine(.initializing)
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
