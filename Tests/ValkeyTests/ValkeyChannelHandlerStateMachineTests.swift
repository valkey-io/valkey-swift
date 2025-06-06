//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 Apple Inc. and the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of valkey-swift project authors
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
        case .failPendingCommandsAndClose(let context, let commands):
            #expect(context == "testClose")
            #expect(commands.count == 0)
        default:
            Issue.record("Invalid close action")
        }
        expect(stateMachine.state == .closed)
    }

    @Test
    func testClosed() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()
        stateMachine.setActive(context: "testClosed")
        switch stateMachine.setClosed() {
        case .failPendingCommandsAndSubscriptions(let commands):
            #expect(commands.count == 0)
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
        case .closeConnection(let context):
            #expect(context == "testGracefulShutdown")
        default:
            Issue.record("Invalid waitForPendingCommands action")
        }
        expect(stateMachine.state == .closed)
    }

    @Test
    func testGracefulShutdownWithPendingCommands() async throws {
        let promise = EmbeddedEventLoop().makePromise(of: RESPToken.self)
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()
        stateMachine.setActive(context: "testGracefulShutdown")
        switch stateMachine.sendCommand(.init(promise: .nio(promise), requestID: 23, deadline: .now())) {
        case .sendCommand:
            break
        case .throwError:
            Issue.record("Invalid sendCommand action")
        }
        switch stateMachine.gracefulShutdown() {
        case .waitForPendingCommands(let context):
            #expect(context == "testGracefulShutdown")
        default:
            Issue.record("Invalid waitForPendingCommands action")
        }
        expect(
            stateMachine.state
                == .closing(.init(context: "testGracefulShutdown", pendingCommands: [.init(promise: .nio(promise), requestID: 23, deadline: .now())]))
        )
        switch stateMachine.receivedResponse() {
        case .respondAndClose(let command):
            #expect(command.requestID == 23)
        case .respond, .closeWithError:
            Issue.record("Invalid receivedResponse action")
        }
        expect(stateMachine.state == .closed)
        promise.fail(CancellationError())
    }

    @Test
    func testClosedClosingState() async throws {
        let promise = EmbeddedEventLoop().makePromise(of: RESPToken.self)
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()
        stateMachine.setActive(context: "testClosedClosingState")
        switch stateMachine.sendCommand(.init(promise: .nio(promise), requestID: 17, deadline: .now())) {
        case .sendCommand:
            break
        case .throwError:
            Issue.record("Invalid sendCommand action")
        }
        switch stateMachine.gracefulShutdown() {
        case .waitForPendingCommands(let context):
            #expect(context == "testClosedClosingState")
        default:
            Issue.record("Invalid waitForPendingCommands action")
        }
        expect(
            stateMachine.state
                == .closing(
                    .init(context: "testClosedClosingState", pendingCommands: [.init(promise: .nio(promise), requestID: 17, deadline: .now())])
                )
        )
        switch stateMachine.setClosed() {
        case .failPendingCommandsAndSubscriptions(let commands):
            #expect(commands.map { $0.requestID } == [17])
        default:
            Issue.record("Invalid close action")
        }
        expect(stateMachine.state == .closed)
        promise.fail(CancellationError())
    }

    @Test
    func testReceivedResponse() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()  // set active
        stateMachine.setActive(context: "testReceivedResponse")
        let promise = EmbeddedEventLoop().makePromise(of: RESPToken.self)
        switch stateMachine.sendCommand(.init(promise: .nio(promise), requestID: 2344, deadline: .now())) {
        case .sendCommand:
            break
        case .throwError:
            Issue.record("Invalid sendCommand action")
        }
        switch stateMachine.receivedResponse() {
        case .respond(let command, let deadlineAction):
            #expect(command.requestID == 2344)
            #expect(deadlineAction == .cancel)
            command.promise.succeed(RESPToken(validated: ByteBuffer(string: "+OK\r\n")))
        case .closeWithError, .respondAndClose:
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
        case .respond, .respondAndClose:
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
        switch stateMachine.sendCommand(.init(promise: .nio(promise), requestID: 23, deadline: .now())) {
        case .sendCommand:
            break
        case .throwError:
            Issue.record("Invalid sendCommand action")
        }
        switch stateMachine.sendCommand(.init(promise: .nio(promise), requestID: 48, deadline: .now())) {
        case .sendCommand:
            break
        case .throwError:
            Issue.record("Invalid sendCommand action")
        }
        switch stateMachine.cancel(requestID: 23) {
        case .failPendingCommandsAndClose(let context, let cancel, let closeConnectionDueToCancel):
            #expect(context == "testCancel")
            #expect(cancel.map { $0.requestID } == [23])
            #expect(closeConnectionDueToCancel.map { $0.requestID } == [48])
            break
        default:
            Issue.record("Invalid cancel action")
        }
        expect(stateMachine.state == .closed)
        promise.fail(CancellationError())
    }

    @Test
    func testCancelOfNotPendingCommand() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()  // set active
        stateMachine.setActive(context: "testCancel")
        switch stateMachine.cancel(requestID: 23) {
        case .failPendingCommandsAndClose:
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
        switch stateMachine.sendCommand(.init(promise: .nio(promise), requestID: 23, deadline: .now())) {
        case .sendCommand:
            break
        case .throwError:
            Issue.record("Invalid sendCommand action")
        }
        _ = stateMachine.gracefulShutdown()
        switch stateMachine.cancel(requestID: 23) {
        case .failPendingCommandsAndClose(let context, let cancel, let closeConnectionDueToCancel):
            #expect(context == "testCancelGracefulShutdown")
            #expect(cancel.map { $0.requestID } == [23])
            #expect(closeConnectionDueToCancel.count == 0)
        default:
            Issue.record("Invalid cancel action")
        }
        expect(stateMachine.state == .closed)
        promise.fail(CancellationError())
    }

    @Test
    func testTimeout() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()  // set active
        stateMachine.setActive(context: "testTimeout")
        let promise = EmbeddedEventLoop().makePromise(of: RESPToken.self)
        let now = NIODeadline.now()
        switch stateMachine.hitDeadline(now: now) {
        case .clearCallback:
            break
        case .reschedule, .failPendingCommandsAndClose:
            Issue.record("Invalid hitDeadline action")
        }
        switch stateMachine.sendCommand(.init(promise: .nio(promise), requestID: 2344, deadline: now + .seconds(1))) {
        case .sendCommand:
            break
        case .throwError:
            Issue.record("Invalid sendCommand action")
        }
        switch stateMachine.hitDeadline(now: now + .milliseconds(500)) {
        case .reschedule(let deadline):
            #expect(deadline == now + .seconds(1))
        case .clearCallback, .failPendingCommandsAndClose:
            Issue.record("Invalid hitDeadline action")
        }
        switch stateMachine.sendCommand(.init(promise: .nio(promise), requestID: 2345, deadline: now + .seconds(2))) {
        case .sendCommand:
            break
        case .throwError:
            Issue.record("Invalid sendCommand action")
        }
        switch stateMachine.receivedResponse() {
        case .respond(let command, let deadlineAction):
            #expect(command.requestID == 2344)
            #expect(deadlineAction == .doNothing)
        case .closeWithError, .respondAndClose:
            Issue.record("Invalid receivedResponse action")
        }
        switch stateMachine.hitDeadline(now: now + .seconds(1)) {
        case .reschedule(let deadline):
            #expect(deadline == now + .seconds(2))
        case .clearCallback, .failPendingCommandsAndClose:
            Issue.record("Invalid hitDeadline action")
        }
        switch stateMachine.hitDeadline(now: now + .seconds(3)) {
        case .failPendingCommandsAndClose(let context, let commands):
            #expect(context == "testTimeout")
            #expect(commands.map { $0.requestID } == [2345])
        case .clearCallback, .reschedule:
            Issue.record("Invalid hitDeadline action")
        }
        expect(stateMachine.state == .closed)
        promise.fail(CancellationError())
    }

    @Test
    func testTimeoutWithDeadlineInversion() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()  // set active
        stateMachine.setActive(context: "testTimeout")
        let promise = EmbeddedEventLoop().makePromise(of: RESPToken.self)
        let now = NIODeadline.now()
        switch stateMachine.hitDeadline(now: now) {
        case .clearCallback:
            break
        case .reschedule, .failPendingCommandsAndClose:
            Issue.record("Invalid hitDeadline action")
        }
        switch stateMachine.sendCommand(.init(promise: .nio(promise), requestID: 2344, deadline: now + .seconds(3))) {
        case .sendCommand:
            break
        case .throwError:
            Issue.record("Invalid sendCommand action")
        }
        switch stateMachine.sendCommand(.init(promise: .nio(promise), requestID: 2345, deadline: now + .seconds(2))) {
        case .sendCommand:
            break
        case .throwError:
            Issue.record("Invalid sendCommand action")
        }
        switch stateMachine.receivedResponse() {
        case .respond(let command, let deadlineAction):
            #expect(command.requestID == 2344)
            #expect(deadlineAction == .reschedule(now + .seconds(2)))
        case .closeWithError, .respondAndClose:
            Issue.record("Invalid receivedResponse action")
        }
        switch stateMachine.hitDeadline(now: now + .seconds(2)) {
        case .failPendingCommandsAndClose(let context, let commands):
            #expect(context == "testTimeout")
            #expect(commands.map { $0.requestID } == [2345])
        case .clearCallback, .reschedule:
            Issue.record("Invalid hitDeadline action")
        }
        expect(stateMachine.state == .closed)
        promise.fail(CancellationError())
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
                return lhs.context == rhs.context && lhs.pendingCommands.map { $0.requestID } == rhs.pendingCommands.map { $0.requestID }
            default:
                return false
            }
        case .closing(let lhs):
            switch rhs {
            case .closing(let rhs):
                return lhs.context == rhs.context && lhs.pendingCommands.map { $0.requestID } == rhs.pendingCommands.map { $0.requestID }
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

extension ValkeyChannelHandler.StateMachine.DeadlineCallbackAction: Equatable {
    public static func == (_ lhs: Self, _ rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.doNothing, .doNothing):
            true
        case (.cancel, .cancel):
            true
        case (.reschedule(let lhs), .reschedule(let rhs)):
            lhs == rhs
        default:
            false
        }
    }
}
