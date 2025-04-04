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
    struct StateMachine {
        enum State {
            case initializing
            case active(ActiveState)
            case closing(ClosingState)
            case closed
        }
        var state: State

        struct ActiveState {
            let context: ChannelHandlerContext
        }

        struct ClosingState {
            let context: ChannelHandlerContext
        }

        init() {
            self.state = .initializing
        }

        /// handler has become active
        mutating func setActive(context: ChannelHandlerContext) {
            switch self.state {
            case .initializing:
                self.state = .active(.init(context: context))
            case .active, .closing, .closed:
                preconditionFailure("Cannot set active state when state is \(self.state)")
            }
        }

        enum SendCommandAction {
            case sendCommand(ChannelHandlerContext)
            case throwError(Error)
        }

        /// handler wants to send a command
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

        enum GracefulShutdownAction {
            case waitForPendingCommands(ChannelHandlerContext)
            case doNothing
        }
        /// Want to gracefully shutdown the handler
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

        enum CloseAction {
            case close(ChannelHandlerContext)
            case doNothing
        }
        /// Want to close the connection
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

        enum SetClosedAction {
            case failPendingCommands
            case doNothing
        }

        /// The connection has been closed
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
