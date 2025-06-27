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
            case connected([ValkeyPromise<Void>], ActiveState)
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

        init() {
            self.state = .initialized
        }

        private init(_ state: consuming State) {
            self.state = state
        }

        /// handler has become active
        @usableFromInline
        mutating func setActive(context: Context) {
            switch consume self.state {
            case .initialized:
                self = .connected([], .init(context: context, pendingCommands: []))
            case .connected:
                preconditionFailure("Cannot set active state when state is connected")
            case .active:
                preconditionFailure("Cannot set active state when state is active")
            case .closing:
                preconditionFailure("Cannot set active state when state is closing")
            case .closed:
                preconditionFailure("Cannot set active state when state is closed")
            }
        }

        @usableFromInline
        enum RegisterStartupPromiseAction {
            case failPromise(any Error)
            case succeedPromise
            case none
        }

        @usableFromInline
        mutating func registerStartupPromise(_ promise: ValkeyPromise<Void>) -> RegisterStartupPromiseAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot register startup promises before connect has succeeded")
            case .connected(var promises, let state):
                promises.append(promise)
                self = .connected(promises, state)
                return .none
            case .active(let state):
                self = .active(state)
                return .succeedPromise
            case .closing(let state):
                self = .closing(state)
                return .none
            case .closed:
                self = .closed
                return .failPromise(ValkeyClientError(.connectionClosed))
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
                preconditionFailure("Cannot send command when initializing")
            case .connected:
                preconditionFailure("Cannot send command while waiting for HELLO response")
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
            case failHelloPromisesAndClose([ValkeyPromise<Void>], any Error)
            case succeedHelloPromises([ValkeyPromise<Void>])

            case respond(PendingCommand, DeadlineCallbackAction)
            case respondAndClose(PendingCommand)
            case closeWithError(Error)
        }

        /// handler wants to send a command
        @usableFromInline
        mutating func receivedResponse(_ token: RESPToken) -> ReceivedResponseAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot receive responses before connection is established")

            case .connected(let promises, let state):
                switch token.identifier {
                case .bulkError, .simpleError:
                    let error = ValkeyClientError(.commandError, message: token.errorString.map { String(buffer: $0) })
                    self = .closed
                    return .failHelloPromisesAndClose(promises, error)

                case .map:
                    self = .active(state)
                    return .succeedHelloPromises(promises)

                default:
                    let error = ValkeyClientError(.unsolicitedToken, message: "Unexpected Response token for HELLO command: \(token.identifier)")
                    self = .closed
                    return .failHelloPromisesAndClose(promises, error)
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
                    return .respondAndClose(command)
                }

            case .closed:
                preconditionFailure("Cannot receive command on closed connection")
            }
        }

        @usableFromInline
        enum HitDeadlineAction {
            case failStartupAndClose([ValkeyPromise<Void>], any Error)
            case failPendingCommandsAndClose(Context, Deque<PendingCommand>)
            case reschedule(NIODeadline)
            case clearCallback
        }

        @usableFromInline
        mutating func hitDeadline(now: NIODeadline) -> HitDeadlineAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot cancel when initializing")

            case .connected(let promises, let state):
                let error = ValkeyClientError(.timeout, message: "Server did not respond to HELLO command within timeout interval.")
                self = .closed
                return .failStartupAndClose(promises, error)

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
                preconditionFailure("Cannot cancel when initializing")
            case .connected:
                preconditionFailure("Cannot cancel commands while waiting for HELLO response")
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
            case closeConnection(Context, failStartUpPromises: [ValkeyPromise<Void>])
            case doNothing
        }
        /// Want to gracefully shutdown the handler
        @usableFromInline
        mutating func gracefulShutdown() -> GracefulShutdownAction {
            switch consume self.state {
            case .initialized:
                self = .closed
                return .doNothing
            case .connected(let promises, let state):
                self = .closed
                return .closeConnection(state.context, failStartUpPromises: promises)
            case .active(let state):
                if state.pendingCommands.count > 0 {
                    self = .closing(.init(context: state.context, pendingCommands: state.pendingCommands))
                    return .waitForPendingCommands(state.context)
                } else {
                    self = .closed
                    return .closeConnection(state.context, failStartUpPromises: [])
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
            case failPendingCommandsAndClose(Context, Deque<PendingCommand>, [ValkeyPromise<Void>])
            case doNothing
        }
        /// Want to close the connection
        @usableFromInline
        mutating func close() -> CloseAction {
            switch consume self.state {
            case .initialized:
                self = .closed
                return .doNothing
            case .connected(let promises, let state):
                self = .closed
                return .failPendingCommandsAndClose(state.context, [], promises)
            case .active(let state):
                self = .closed
                return .failPendingCommandsAndClose(state.context, state.pendingCommands, [])
            case .closing(let state):
                self = .closed
                return .failPendingCommandsAndClose(state.context, state.pendingCommands, [])
            case .closed:
                self = .closed
                return .doNothing
            }
        }

        @usableFromInline
        enum SetClosedAction {
            case failPendingCommandsAndSubscriptions(Deque<PendingCommand>, [ValkeyPromise<Void>])
            case doNothing
        }

        /// The connection has been closed
        @usableFromInline
        mutating func setClosed() -> SetClosedAction {
            switch consume self.state {
            case .initialized:
                self = .closed
                return .doNothing
            case .connected(let promises, let state):
                self = .closed
                return .failPendingCommandsAndSubscriptions([], promises)
            case .active(let state):
                self = .closed
                return .failPendingCommandsAndSubscriptions(state.pendingCommands, [])
            case .closing(let state):
                self = .closed
                return .failPendingCommandsAndSubscriptions(state.pendingCommands, [])
            case .closed:
                self = .closed
                return .doNothing
            }
        }

        private static var initialized: Self {
            StateMachine(.initialized)
        }

        private static func connected(_ promises: [ValkeyPromise<Void>], _ state: ActiveState) -> Self {
            StateMachine(.connected(promises, state))
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
