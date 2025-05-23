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

import NIOCore

extension ValkeyChannelHandler {
    @usableFromInline
    struct StateMachine<Context> {
        @usableFromInline
        enum State {
            case initializing
            case active(ActiveState)
            case closing(ClosingState)
            case closed
        }
        @usableFromInline
        var state: State

        @usableFromInline
        struct ActiveState {
            let context: Context
        }

        @usableFromInline
        struct ClosingState {
            let context: Context
        }

        init() {
            self.state = .initializing
        }

        /// handler has become active
        @usableFromInline
        mutating func setActive(context: Context) {
            switch self.state {
            case .initializing:
                self.state = .active(.init(context: context))
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
        func sendCommand() -> SendCommandAction {
            switch self.state {
            case .initializing:
                preconditionFailure("Cannot send command when initializing")
            case .active(let state):
                return .sendCommand(state.context)
            case .closing:
                return .throwError(ValkeyClientError(.connectionClosing))
            case .closed:
                return .throwError(ValkeyClientError(.connectionClosed))
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
                self.state = .closing(ClosingState(context: state.context))
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
        mutating func close() -> CloseAction {
            switch self.state {
            case .initializing:
                self.state = .closed
                return .doNothing
            case .active(let state):
                self.state = .closed
                return .close(state.context)
            case .closing(let state):
                self.state = .closed
                return .close(state.context)
            case .closed:
                return .doNothing
            }
        }

        @usableFromInline
        enum SetClosedAction {
            case failPendingCommands
            case doNothing
        }

        /// The connection has been closed
        @usableFromInline
        mutating func setClosed() -> SetClosedAction {
            switch self.state {
            case .initializing:
                self.state = .closed
                return .doNothing
            case .active, .closing:
                self.state = .closed
                return .failPendingCommands
            case .closed:
                return .doNothing
            }
        }
    }
}
