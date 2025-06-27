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
    @available(valkeySwift 1.0, *)
    func testClose() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()
        stateMachine.setActive(context: "testClose")
        stateMachine.receivedResponse(.hello).ensureSucceedPromises()
        expect(stateMachine.state == .active(.init(context: "testClose", pendingCommands: [])))
        switch stateMachine.close() {
        case .failPendingCommandsAndClose(let context, let commands, let startupPromises):
            #expect(context == "testClose")
            #expect(commands.count == 0)
            #expect(startupPromises.count == 0)
        default:
            Issue.record("Invalid close action")
        }
        expect(stateMachine.state == .closed)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testClosed() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()
        stateMachine.setActive(context: "testClosed")
        stateMachine.receivedResponse(.hello).ensureSucceedPromises()
        switch stateMachine.setClosed() {
        case .failPendingCommandsAndSubscriptions(let commands, let startupPromises):
            #expect(commands.count == 0)
            #expect(startupPromises.count == 0)
        default:
            Issue.record("Invalid close action")
        }
        expect(stateMachine.state == .closed)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testGracefulShutdown() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()
        stateMachine.setActive(context: "testGracefulShutdown")
        stateMachine.receivedResponse(.hello).ensureSucceedPromises()
        switch stateMachine.gracefulShutdown() {
        case .closeConnection(let context, let startupPromises):
            #expect(context == "testGracefulShutdown")
            #expect(startupPromises.count == 0)
        default:
            Issue.record("Invalid waitForPendingCommands action")
        }
        expect(stateMachine.state == .closed)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testGracefulShutdownWithPendingCommands() async throws {
        let promise = EmbeddedEventLoop().makePromise(of: RESPToken.self)
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()
        stateMachine.setActive(context: "testGracefulShutdown")
        stateMachine.receivedResponse(.hello).ensureSucceedPromises()
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
        switch stateMachine.receivedResponse(.ok) {
        case .respondAndClose(let command):
            #expect(command.requestID == 23)
        case .respond, .closeWithError, .failHelloPromisesAndClose, .succeedHelloPromises, .none:
            Issue.record("Invalid receivedResponse action")
        }
        expect(stateMachine.state == .closed)
        promise.fail(CancellationError())
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testClosedClosingState() async throws {
        let promise = EmbeddedEventLoop().makePromise(of: RESPToken.self)
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()
        stateMachine.setActive(context: "testClosedClosingState")
        stateMachine.receivedResponse(.hello).ensureSucceedPromises()
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
        case .failPendingCommandsAndSubscriptions(let commands, let startupPromises):
            #expect(commands.map { $0.requestID } == [17])
            #expect(startupPromises.isEmpty)
        default:
            Issue.record("Invalid close action")
        }
        expect(stateMachine.state == .closed)
        promise.fail(CancellationError())
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testReceivedResponse() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()  // set active
        stateMachine.setActive(context: "testReceivedResponse")
        stateMachine.receivedResponse(.hello).ensureSucceedPromises()
        let promise = EmbeddedEventLoop().makePromise(of: RESPToken.self)
        switch stateMachine.sendCommand(.init(promise: .nio(promise), requestID: 2344, deadline: .now())) {
        case .sendCommand:
            break
        case .throwError:
            Issue.record("Invalid sendCommand action")
        }
        let token = RESPToken(validated: ByteBuffer(string: "+OK\r\n"))
        switch stateMachine.receivedResponse(token) {
        case .respond(let command, let deadlineAction):
            #expect(command.requestID == 2344)
            #expect(deadlineAction == .cancel)
            command.promise.succeed(token)
        case .closeWithError, .respondAndClose, .failHelloPromisesAndClose, .succeedHelloPromises, .none:
            Issue.record("Invalid receivedResponse action")
        }
        expect(stateMachine.state == .active(.init(context: "testReceivedResponse", pendingCommands: [])))
        await #expect(try promise.futureResult.get() == RESPToken(validated: ByteBuffer(string: "+OK\r\n")))
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testReceivedResponseWithoutCommand() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()  // set active
        stateMachine.setActive(context: "testReceivedResponse")
        stateMachine.receivedResponse(.hello).ensureSucceedPromises()
        let token = RESPToken(validated: ByteBuffer(string: "+OK\r\n"))
        switch stateMachine.receivedResponse(token) {
        case .respond, .respondAndClose, .failHelloPromisesAndClose, .succeedHelloPromises, .none:
            Issue.record("Invalid receivedResponse action")
        case .closeWithError(let error):
            let valkeyError = try #require(error as? ValkeyClientError)
            #expect(valkeyError.errorCode == .unsolicitedToken)
        }
        expect(stateMachine.state == .closed)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testCancel() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()  // set active
        stateMachine.setActive(context: "testCancel")
        stateMachine.receivedResponse(.hello).ensureSucceedPromises()
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
    @available(valkeySwift 1.0, *)
    func testCancelOfNotPendingCommand() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()  // set active
        stateMachine.setActive(context: "testCancel")
        stateMachine.receivedResponse(.hello).ensureSucceedPromises()
        switch stateMachine.cancel(requestID: 23) {
        case .failPendingCommandsAndClose:
            Issue.record("Invalid cancel action")
        case .doNothing:
            break
        }
        expect(stateMachine.state != .closed)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testCancelGracefulShutdown() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()  // set active
        stateMachine.setActive(context: "testCancelGracefulShutdown")
        stateMachine.receivedResponse(.hello).ensureSucceedPromises()
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
    @available(valkeySwift 1.0, *)
    func testTimeout() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()  // set active
        stateMachine.setActive(context: "testTimeout")
        stateMachine.receivedResponse(.hello).ensureSucceedPromises()
        let promise = EmbeddedEventLoop().makePromise(of: RESPToken.self)
        let now = NIODeadline.now()
        switch stateMachine.hitDeadline(now: now) {
        case .clearCallback:
            break
        case .reschedule, .failPendingCommandsAndClose, .failStartupAndClose:
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
        case .clearCallback, .failPendingCommandsAndClose, .failStartupAndClose:
            Issue.record("Invalid hitDeadline action")
        }
        switch stateMachine.sendCommand(.init(promise: .nio(promise), requestID: 2345, deadline: now + .seconds(2))) {
        case .sendCommand:
            break
        case .throwError:
            Issue.record("Invalid sendCommand action")
        }
        switch stateMachine.receivedResponse(.ok) {
        case .respond(let command, let deadlineAction):
            #expect(command.requestID == 2344)
            #expect(deadlineAction == .doNothing)
        case .closeWithError, .respondAndClose, .failHelloPromisesAndClose, .succeedHelloPromises, .none:
            Issue.record("Invalid receivedResponse action")
        }
        switch stateMachine.hitDeadline(now: now + .seconds(1)) {
        case .reschedule(let deadline):
            #expect(deadline == now + .seconds(2))
        case .clearCallback, .failPendingCommandsAndClose, .failStartupAndClose:
            Issue.record("Invalid hitDeadline action")
        }
        switch stateMachine.hitDeadline(now: now + .seconds(3)) {
        case .failPendingCommandsAndClose(let context, let commands):
            #expect(context == "testTimeout")
            #expect(commands.map { $0.requestID } == [2345])
        case .clearCallback, .reschedule, .failStartupAndClose:
            Issue.record("Invalid hitDeadline action")
        }
        expect(stateMachine.state == .closed)
        promise.fail(CancellationError())
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testTimeoutWithDeadlineInversion() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()  // set active
        stateMachine.setActive(context: "testTimeout")
        stateMachine.receivedResponse(.hello).ensureSucceedPromises()
        let promise = EmbeddedEventLoop().makePromise(of: RESPToken.self)
        let now = NIODeadline.now()
        switch stateMachine.hitDeadline(now: now) {
        case .clearCallback:
            break
        case .reschedule, .failPendingCommandsAndClose, .failStartupAndClose:
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
        switch stateMachine.receivedResponse(.ok) {
        case .respond(let command, let deadlineAction):
            #expect(command.requestID == 2344)
            #expect(deadlineAction == .reschedule(now + .seconds(2)))
        case .closeWithError, .respondAndClose, .failHelloPromisesAndClose, .succeedHelloPromises, .none:
            Issue.record("Invalid receivedResponse action")
        }
        switch stateMachine.hitDeadline(now: now + .seconds(2)) {
        case .failPendingCommandsAndClose(let context, let commands):
            #expect(context == "testTimeout")
            #expect(commands.map { $0.requestID } == [2345])
        case .clearCallback, .reschedule, .failStartupAndClose:
            Issue.record("Invalid hitDeadline action")
        }
        expect(stateMachine.state == .closed)
        promise.fail(CancellationError())
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyChannelHandler.StateMachine<String>.State {
    public static func == (_ lhs: borrowing Self, _ rhs: borrowing Self) -> Bool {
        switch lhs {
        case .initialized:
            switch rhs {
            case .initialized:
                return true
            default:
                return false
            }

        case .connected(let lhsPromises, let lhsState):
            switch rhs {
            case .connected(let rhsPromises, let rhsState):
                return rhsPromises.count == lhsPromises.count
                && lhsState.context == rhsState.context
                && lhsState.pendingCommands.map { $0.requestID } == rhsState.pendingCommands.map { $0.requestID }
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

@available(valkeySwift 1.0, *)
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

extension RESPToken {
    static var ok: RESPToken {
        RESPToken(.simpleString("OK"))
    }

    static var hello: RESPToken {
        RESPToken(.map([:]))
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyChannelHandler.StateMachine.ReceivedResponseAction {
    func ensureSucceedPromises(sourceLocation: SourceLocation = #_sourceLocation) {
        switch self {
        case .succeedHelloPromises:
            break
        case .closeWithError, .failHelloPromisesAndClose, .none, .respond, .respondAndClose:
            Issue.record("Unexpected ReceivedResponseAction: \(self)", sourceLocation: sourceLocation)
        }
    }
}
