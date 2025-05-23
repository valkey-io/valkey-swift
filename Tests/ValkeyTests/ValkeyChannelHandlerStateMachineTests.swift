//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey open source project
//
// Copyright (c) 2025 Apple Inc. and the swift-valkey project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-valkey project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore
import Testing

@testable import Valkey

struct ValkeyChannelHandlerStateMachineTests {
    @Test
    func testClose() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()
        stateMachine.setActive(context: "testClose")
        #expect(stateMachine.state == .active(.init(context: "testClose")))
        switch stateMachine.close() {
        case .close(let context):
            #expect(context == "testClose")
        default:
            Issue.record("Invalid close action")
        }
        #expect(stateMachine.state == .closed)
    }

    @Test
    func testClosed() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()
        stateMachine.setActive(context: "testClosed")
        switch stateMachine.setClosed() {
        case .failPendingCommands:
            break
        default:
            Issue.record("Invalid close action")
        }
        #expect(stateMachine.state == .closed)
    }

    @Test
    func testGracefulShutdown() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()
        stateMachine.setActive(context: "testGracefulShutdown")
        switch stateMachine.gracefulShutdown() {
        case .waitForPendingCommands(let context):
            #expect(context == "testGracefulShutdown")
        default:
            Issue.record("Invalid waitForPendingCommands action")
        }
        #expect(stateMachine.state == .closing(.init(context: "testGracefulShutdown")))
        switch stateMachine.close() {
        case .close(let context):
            #expect(context == "testGracefulShutdown")
        default:
            Issue.record("Invalid close action")
        }
        #expect(stateMachine.state == .closed)
    }

    @Test
    func testClosedClosingState() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()
        stateMachine.setActive(context: "testClosedClosingState")
        switch stateMachine.gracefulShutdown() {
        case .waitForPendingCommands(let context):
            #expect(context == "testClosedClosingState")
        default:
            Issue.record("Invalid waitForPendingCommands action")
        }
        #expect(stateMachine.state == .closing(.init(context: "testClosedClosingState")))
        switch stateMachine.setClosed() {
        case .failPendingCommands:
            break
        default:
            Issue.record("Invalid close action")
        }
        #expect(stateMachine.state == .closed)
    }

    @Test
    func testCancel() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()  // set active
        stateMachine.setActive(context: "testCancel")
        switch stateMachine.cancel() {
        case .cancelPendingCommands:
            break
        default:
            Issue.record("Invalid cancel action")
        }
        _ = stateMachine.gracefulShutdown()
        switch stateMachine.cancel() {
        case .cancelPendingCommands:
            break
        default:
            Issue.record("Invalid cancel action")
        }
        _ = stateMachine.setClosed()
        switch stateMachine.cancel() {
        case .doNothing:
            break
        default:
            Issue.record("Invalid cancel action")
        }
    }
}

extension ValkeyChannelHandler.StateMachine<String>.State: Equatable {
    public static func == (_ lhs: Self, _ rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.initializing, .initializing):
            return true
        case (.active(let lhs), .active(let rhs)):
            return lhs.context == rhs.context
        case (.closing(let lhs), .closing(let rhs)):
            return lhs.context == rhs.context
        case (.closed, .closed):
            return true
        default:
            return false
        }
    }
}
