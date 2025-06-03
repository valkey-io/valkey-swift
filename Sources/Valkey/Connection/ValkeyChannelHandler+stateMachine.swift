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
    struct StateMachine<Context> {
        @usableFromInline
        enum State {
            case initializing
            case active(ActiveState)
            case closing(ActiveState)
            case closed
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

        /// handler has become active
        @usableFromInline
        mutating func setActive(context: Context) {
            switch self.state {
            case .initializing:
                self.state = .active(.init(context: context, pendingCommands: []))
            case .active, .closing, .closed:
                preconditionFailure("Cannot set active state when state is \(self.state)")
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
            switch self.state {
            case .initializing:
                preconditionFailure("Cannot send command when initializing")
            case .active(var state):
                state.pendingCommands.append(pendingCommand)
                self.state = .active(state)
                return .sendCommand(state.context)
            case .closing:
                return .throwError(ValkeyClientError(.connectionClosing))
            case .closed:
                return .throwError(ValkeyClientError(.connectionClosed))
            }
        }

        /// handler wants to send pipelined commands
        @usableFromInline
        mutating func sendCommands(_ pendingCommands: [PendingCommand]) -> SendCommandAction {
            switch self.state {
            case .initializing:
                preconditionFailure("Cannot send command when initializing")
            case .active(var state):
                state.pendingCommands.append(contentsOf: pendingCommands)
                self.state = .active(state)
                return .sendCommand(state.context)
            case .closing:
                return .throwError(ValkeyClientError(.connectionClosing))
            case .closed:
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
            switch self.state {
            case .initializing:
                preconditionFailure("Cannot send command when initializing")
            case .active(var state):
                guard let command = state.pendingCommands.popFirst() else {
                    self.state = .closed
                    return .closeWithError(ValkeyClientError(.unsolicitedToken, message: "Received a token without having sent a command"))
                }
                self.state = .active(state)
                return .respond(command)
            case .closing(var state):
                guard let command = state.pendingCommands.popFirst() else {
                    self.state = .closed
                    return .closeWithError(ValkeyClientError(.unsolicitedToken, message: "Received a token without having sent a command"))
                }
                self.state = .closing(state)
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
            switch self.state {
            case .initializing:
                preconditionFailure("Cannot cancel when initializing")
            case .active(var state), .closing(var state):
                if state.cancel(requestID: requestID) {
                    self.state = .closed
                    return .closeConnection(state.context)
                } else {
                    return .doNothing
                }
            case .closed:
                return .doNothing
            }
        }

        @usableFromInline
        enum FailPendingCommandsAction {
            case closeConnection(Context)
            case doNothing
        }

        /// fail pending commands
        @usableFromInline
        mutating func failPendingCommands(_ error: Error) -> FailPendingCommandsAction {
            switch self.state {
            case .initializing:
                preconditionFailure("Cannot cancel when initializing")
            case .active(var state), .closing(var state):
                state.failPendingCommands(error)
                self.state = .closed
                return .closeConnection(state.context)
            case .closed:
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
            switch self.state {
            case .initializing:
                self.state = .closed
                return .doNothing
            case .active(let state):
                self.state = .closing(.init(context: state.context, pendingCommands: state.pendingCommands))
                return .waitForPendingCommands(state.context)
            case .closed, .closing:
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
            switch self.state {
            case .initializing:
                self.state = .closed
                return .doNothing
            case .active(var state), .closing(var state):
                state.failPendingCommands(error)
                self.state = .closed
                return .close(state.context)
            case .closed:
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
            switch self.state {
            case .initializing:
                self.state = .closed
                return .doNothing
            case .active(var state), .closing(var state):
                state.failPendingCommands(error)
                self.state = .closed
                return .failSubscriptions
            case .closed:
                return .doNothing
            }
        }
    }
}
