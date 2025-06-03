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

            mutating func failPendingCommands(_ error: Error) {
                while let command = self.pendingCommands.popFirst() {
                    command.promise.fail(error)
                }
            }

            mutating func cancel(requestID: Int) -> Bool {
                // if pending commands include request then we are still waiting for its result.
                // We should cancel that command, cancel all the other pending commands with error
                // code `.connectionClosedDueToCancellation` and close the connection
                if self.pendingCommands.contains(where: { $0.requestID == requestID }) {
                    while let command = self.pendingCommands.popFirst() {
                        if command.requestID == requestID {
                            command.promise.fail(ValkeyClientError(.cancelled))
                        } else {
                            command.promise.fail(ValkeyClientError(.connectionClosedDueToCancellation))
                        }
                    }
                    return true
                }
                return false
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
            switch consume self.state {
            case .initializing:
                preconditionFailure("Cannot send command when initializing")
            case .active(var state):
                state.pendingCommands.append(pendingCommand)
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

        /// handler wants to send pipelined commands
        @usableFromInline
        mutating func sendCommands(_ pendingCommands: [PendingCommand]) -> SendCommandAction {
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
                    self = .closed
                    return .closeWithError(ValkeyClientError(.unsolicitedToken, message: "Received a token without having sent a command"))
                }
                self = .closing(state)
                return .respond(command)
            case .closed:
                preconditionFailure("Cannot receive command on closed connection")
            }
        }

        @usableFromInline
        enum CancelAction {
            case closeConnection(Context)
            case doNothing
        }

        /// handler wants to send a command
        @usableFromInline
        mutating func cancel(requestID: Int) -> CancelAction {
            switch consume self.state {
            case .initializing:
                preconditionFailure("Cannot cancel when initializing")
            case .active(var state):
                if state.cancel(requestID: requestID) {
                    self = .closed
                    return .closeConnection(state.context)
                } else {
                    self = .active(state)
                    return .doNothing
                }
            case .closing(var state):
                if state.cancel(requestID: requestID) {
                    self = .closed
                    return .closeConnection(state.context)
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
                self = .closing(.init(context: state.context, pendingCommands: state.pendingCommands))
                return .waitForPendingCommands(state.context)
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
            case close(Context)
            case doNothing
        }
        /// Want to close the connection
        @usableFromInline
        mutating func close(withError error: Error = ValkeyClientError(.connectionClosed)) -> CloseAction {
            switch consume self.state {
            case .initializing:
                self = .closed
                return .doNothing
            case .active(var state):
                state.failPendingCommands(error)
                self = .closed
                return .close(state.context)
            case .closing(var state):
                state.failPendingCommands(error)
                self = .closed
                return .close(state.context)
            case .closed:
                self = .closed
                return .doNothing
            }
        }

        @usableFromInline
        enum SetClosedAction {
            case failSubscriptions
            case doNothing
        }

        /// The connection has been closed
        @usableFromInline
        mutating func setClosed(withError error: Error) -> SetClosedAction {
            switch consume self.state {
            case .initializing:
                self = .closed
                return .doNothing
            case .active(var state):
                state.failPendingCommands(error)
                self = .closed
                return .failSubscriptions
            case .closing(var state):
                state.failPendingCommands(error)
                self = .closed
                return .failSubscriptions
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
