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
import NIOEmbedded
import Testing

@testable import Valkey

struct ValkeyChannelHandlerStateMachineTests {
    // Function required as the #expect macro does not work with non-copyable types
    func expect(_ value: Bool, fileID: String = #fileID, filePath: String = #filePath, line: Int = #line) {
        #expect(value, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: 1))
    }

    @Test
    func testClose() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()
        stateMachine.setActive(context: "testClose")
        expect(stateMachine.state == .active(.init(context: "testClose", pendingCommands: [])))
        switch stateMachine.close() {
        case .close(let context):
            #expect(context == "testClose")
        default:
            Issue.record("Invalid close action")
        }
        expect(stateMachine.state == .closed)
    }

    @Test
    func testClosed() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()
        stateMachine.setActive(context: "testClosed")
        switch stateMachine.setClosed(withError: ValkeyClientError(.connectionClosed)) {
        case .failSubscriptions:
            break
        default:
            Issue.record("Invalid close action")
        }
        expect(stateMachine.state == .closed)
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
        expect(stateMachine.state == .closing(.init(context: "testGracefulShutdown", pendingCommands: [])))
        switch stateMachine.close() {
        case .close(let context):
            #expect(context == "testGracefulShutdown")
        default:
            Issue.record("Invalid close action")
        }
        expect(stateMachine.state == .closed)
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
        expect(stateMachine.state == .closing(.init(context: "testClosedClosingState", pendingCommands: [])))
        switch stateMachine.setClosed(withError: ValkeyClientError(.connectionClosed)) {
        case .failSubscriptions:
            break
        default:
            Issue.record("Invalid close action")
        }
        expect(stateMachine.state == .closed)
    }

    @Test
    func testReceivedResponse() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()  // set active
        stateMachine.setActive(context: "testReceivedResponse")
        let promise = EmbeddedEventLoop().makePromise(of: RESPToken.self)
        switch stateMachine.sendCommand(.init(promise: .nio(promise), requestID: 2344)) {
        case .sendCommand:
            break
        case .throwError:
            Issue.record("Invalid sendCommand action")
        }
        switch stateMachine.receivedResponse() {
        case .respond(let command):
            #expect(command.requestID == 2344)
            command.promise.succeed(RESPToken(validated: ByteBuffer(string: "+OK\r\n")))
        case .closeWithError:
            Issue.record("Invalid receivedResponse action")
        }
        expect(stateMachine.state == .active(.init(context: "testReceivedResponse", pendingCommands: [])))
        await #expect(try promise.futureResult.get() == RESPToken(validated: ByteBuffer(string: "+OK\r\n")))
    }

    @Test
    func testReceivedResponseWithoutCommand() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()  // set active
        stateMachine.setActive(context: "testReceivedResponse")
        switch stateMachine.receivedResponse() {
        case .respond:
            Issue.record("Invalid receivedResponse action")
        case .closeWithError(let error):
            let valkeyError = try #require(error as? ValkeyClientError)
            #expect(valkeyError.errorCode == .unsolicitedToken)
        }
        expect(stateMachine.state == .closed)
    }

    @Test
    func testCancel() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()  // set active
        stateMachine.setActive(context: "testCancel")
        let promise = EmbeddedEventLoop().makePromise(of: RESPToken.self)
        switch stateMachine.sendCommand(.init(promise: .nio(promise), requestID: 23)) {
        case .sendCommand:
            break
        case .throwError:
            Issue.record("Invalid sendCommand action")
        }
        switch stateMachine.cancel(requestID: 23) {
        case .closeConnection(let context):
            #expect(context == "testCancel")
            break
        default:
            Issue.record("Invalid cancel action")
        }
        expect(stateMachine.state == .closed)
        await #expect(throws: ValkeyClientError(.cancelled)) {
            try await promise.futureResult.get()
        }
    }

    @Test
    func testCancelOfNotPendingCommand() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()  // set active
        stateMachine.setActive(context: "testCancel")
        switch stateMachine.cancel(requestID: 23) {
        case .closeConnection:
            Issue.record("Invalid cancel action")
        case .doNothing:
            break
        }
        expect(stateMachine.state != .closed)
    }

    @Test
    func testCancelGracefulShutdown() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()  // set active
        stateMachine.setActive(context: "testCancelGracefulShutdown")
        let promise = EmbeddedEventLoop().makePromise(of: RESPToken.self)
        switch stateMachine.sendCommand(.init(promise: .nio(promise), requestID: 23)) {
        case .sendCommand:
            break
        case .throwError:
            Issue.record("Invalid sendCommand action")
        }
        _ = stateMachine.gracefulShutdown()
        switch stateMachine.cancel(requestID: 23) {
        case .closeConnection(let context):
            #expect(context == "testCancelGracefulShutdown")
        default:
            Issue.record("Invalid cancel action")
        }
        expect(stateMachine.state == .closed)
        await #expect(throws: ValkeyClientError(.cancelled)) {
            try await promise.futureResult.get()
        }
    }
}

extension ValkeyChannelHandler.StateMachine<String>.State {
    public static func == (_ lhs: borrowing Self, _ rhs: borrowing Self) -> Bool {
        switch lhs {
        case .initializing:
            switch rhs {
            case .initializing:
                return true
            default:
                return false
            }
        case .active(let lhs):
            switch rhs {
            case .active(let rhs):
                return lhs.context == rhs.context
            default:
                return false
            }
        case .closing(let lhs):
            switch rhs {
            case .closing(let rhs):
                return lhs.context == rhs.context
            default:
                return false
            }
        case .closed:
            switch rhs {
            case .closed:
                return true
            default:
                return false
            }
        }
    }

    public static func != (_ lhs: borrowing Self, _ rhs: borrowing Self) -> Bool {
        !(lhs == rhs)
    }
}
