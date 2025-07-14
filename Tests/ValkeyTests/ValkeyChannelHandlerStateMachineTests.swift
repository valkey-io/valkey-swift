//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 the valkey-swift project authors
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
        stateMachine.setConnected(context: "testClose")
        stateMachine.receiveHelloResponse()
        expect(stateMachine.state == .active(.init(context: "testClose", pendingCommands: [])))
        switch stateMachine.close() {
        case .failPendingCommandsAndClose(let context, let commands):
            #expect(context == "testClose")
            #expect(commands.count == 0)
        default:
            Issue.record("Invalid close action")
        }
        expect(stateMachine.state == .closed(nil))
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testClosed() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()
        stateMachine.setConnected(context: "testClosed")
        stateMachine.receiveHelloResponse()
        switch stateMachine.setClosed() {
        case .failPendingCommandsAndSubscriptions(let commands):
            #expect(commands.count == 0)
        default:
            Issue.record("Invalid close action")
        }
        expect(stateMachine.state == .closed(nil))
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testConnectedFailsAfterReceive() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()
        stateMachine.setConnected(context: "testClosed")
        switch stateMachine.receivedResponse(token: RESPToken(.bulkError("Connect failed"))) {
        case .respondAndClose(let command, let error):
            #expect(command.requestID == 0)
            let valkeyError = try #require(error as? ValkeyClientError)
            #expect(valkeyError.errorCode == .commandError)
            #expect(valkeyError.message == "Connect failed")
            command.promise.fail(error ?? ValkeyClientError(.commandError))
        case .respond, .closeWithError:
            Issue.record("Invalid receivedResponse action")
        }
        switch stateMachine.waitOnActive() {
        case .reportedClosed(let error):
            let valkeyError = try #require(error as? ValkeyClientError)
            #expect(valkeyError.errorCode == .commandError)
            #expect(valkeyError.message == "Connect failed")
        case .done, .waitForPromise:
            Issue.record("Invalid waitOnActive action")
        }
        expect(stateMachine.state == .closed(ValkeyClientError(.commandError, message: "Connect failed")))
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testConnectedReturnsPromiseBeforeReceive() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()
        stateMachine.setConnected(context: "testClosed")
        switch stateMachine.waitOnActive() {
        case .waitForPromise:
            break
        case .done, .reportedClosed:
            Issue.record("Invalid waitOnActive action")
        }
        switch stateMachine.receivedResponse(token: RESPToken(.bulkError("Connect failed"))) {
        case .respondAndClose(let command, let error):
            #expect(command.requestID == 0)
            let valkeyError = try #require(error as? ValkeyClientError)
            #expect(valkeyError.errorCode == .commandError)
            #expect(valkeyError.message == "Connect failed")
            command.promise.fail(error ?? ValkeyClientError(.commandError))
        case .respond, .closeWithError:
            Issue.record("Invalid receivedResponse action")
        }
        switch stateMachine.setClosed() {
        case .doNothing:
            break
        default:
            Issue.record("Invalid close action")
        }
        expect(stateMachine.state == .closed(ValkeyClientError(.commandError, message: "Connect failed")))
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testConnectedTimeout() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()
        stateMachine.setConnected(context: "testClosed")
        switch stateMachine.waitOnActive() {
        case .waitForPromise:
            break
        case .done, .reportedClosed:
            Issue.record("Invalid waitOnActive action")
        }
        switch stateMachine.hitDeadline(now: .now() + .seconds(10)) {
        case .reschedule:
            break
        case .clearCallback, .failPendingCommandsAndClose:
            Issue.record("Invalid hitDeadline action")
        }
        switch stateMachine.hitDeadline(now: .now() + .seconds(60)) {
        case .failPendingCommandsAndClose(_, let commands):
            let hello = try #require(commands.first)
            #expect(hello.requestID == 0)
            hello.promise.fail(ValkeyClientError(.timeout))
        case .clearCallback, .reschedule:
            Issue.record("Invalid hitDeadline action")
        }
        switch stateMachine.waitOnActive() {
        case .reportedClosed(let error):
            let valkeyError = try #require(error as? ValkeyClientError)
            #expect(valkeyError.errorCode == .timeout)
        case .done, .waitForPromise:
            Issue.record("Invalid waitOnActive action")
        }
        expect(stateMachine.state == .closed(ValkeyClientError(.timeout)))
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testGracefulShutdown() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()
        stateMachine.setConnected(context: "testGracefulShutdown")
        stateMachine.receiveHelloResponse()
        switch stateMachine.gracefulShutdown() {
        case .closeConnection(let context):
            #expect(context == "testGracefulShutdown")
        default:
            Issue.record("Invalid waitForPendingCommands action")
        }
        expect(stateMachine.state == .closed(nil))
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testGracefulShutdownWithPendingCommands() async throws {
        let promise = EmbeddedEventLoop().makePromise(of: RESPToken.self)
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()
        stateMachine.setConnected(context: "testGracefulShutdown")
        stateMachine.receiveHelloResponse()
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
        switch stateMachine.receivedResponse(token: .ok) {
        case .respondAndClose(let command, let error):
            #expect(error == nil)
            #expect(command.requestID == 23)
        case .respond, .closeWithError:
            Issue.record("Invalid receivedResponse action")
        }
        expect(stateMachine.state == .closed(nil))
        promise.fail(CancellationError())
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testClosedClosingState() async throws {
        let promise = EmbeddedEventLoop().makePromise(of: RESPToken.self)
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()
        stateMachine.setConnected(context: "testClosedClosingState")
        stateMachine.receiveHelloResponse()
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
        expect(stateMachine.state == .closed(nil))
        promise.fail(CancellationError())
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testReceivedResponse() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()  // set active
        stateMachine.setConnected(context: "testReceivedResponse")
        stateMachine.receiveHelloResponse()
        let promise = EmbeddedEventLoop().makePromise(of: RESPToken.self)
        switch stateMachine.sendCommand(.init(promise: .nio(promise), requestID: 2344, deadline: .now())) {
        case .sendCommand:
            break
        case .throwError:
            Issue.record("Invalid sendCommand action")
        }
        switch stateMachine.receivedResponse(token: .ok) {
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
    @available(valkeySwift 1.0, *)
    func testReceivedResponseWithoutCommand() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()  // set active
        stateMachine.setConnected(context: "testReceivedResponse")
        stateMachine.receiveHelloResponse()
        switch stateMachine.receivedResponse(token: .ok) {
        case .respond, .respondAndClose:
            Issue.record("Invalid receivedResponse action")
        case .closeWithError(let error):
            let valkeyError = try #require(error as? ValkeyClientError)
            #expect(valkeyError.errorCode == .unsolicitedToken)
        }
        expect(stateMachine.state == .closed(nil))
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testCancel() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()  // set active
        stateMachine.setConnected(context: "testCancel")
        stateMachine.receiveHelloResponse()
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
        expect(stateMachine.state == .closed(CancellationError()))
        promise.fail(CancellationError())
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testCancelOfNotPendingCommand() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()  // set active
        stateMachine.setConnected(context: "testCancel")
        stateMachine.receiveHelloResponse()
        switch stateMachine.cancel(requestID: 23) {
        case .failPendingCommandsAndClose:
            Issue.record("Invalid cancel action")
        case .doNothing:
            break
        }
        expect(stateMachine.state != .closed(nil))
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testCancelGracefulShutdown() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()  // set active
        stateMachine.setConnected(context: "testCancelGracefulShutdown")
        stateMachine.receiveHelloResponse()
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
        expect(stateMachine.state == .closed(CancellationError()))
        promise.fail(CancellationError())
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testTimeout() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()  // set active
        stateMachine.setConnected(context: "testTimeout")
        stateMachine.receiveHelloResponse()
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
        switch stateMachine.receivedResponse(token: .ok) {
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
        expect(stateMachine.state == .closed(ValkeyClientError(.timeout)))
        promise.fail(CancellationError())
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testTimeoutWithDeadlineInversion() async throws {
        var stateMachine = ValkeyChannelHandler.StateMachine<String>()  // set active
        stateMachine.setConnected(context: "testTimeout")
        stateMachine.receiveHelloResponse()
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
        switch stateMachine.receivedResponse(token: .ok) {
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
        expect(stateMachine.state == .closed(ValkeyClientError(.timeout)))
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
        case .connected(let lhs):
            switch rhs {
            case .connected(let rhs):
                return lhs.context == rhs.context && lhs.pendingHelloCommand.requestID == rhs.pendingHelloCommand.requestID
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
        case .closed(let lhs):
            switch rhs {
            case .closed(let rhs):
                switch (lhs, rhs) {
                case (.some(let lhs), .some(let rhs)):
                    if let lhsError = lhs as? ValkeyClientError, let rhsError = rhs as? ValkeyClientError {
                        return lhsError == rhsError
                    }
                    return type(of: lhs) == type(of: rhs)
                case (.none, .none):
                    return true
                default:
                    return false
                }
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
extension ValkeyChannelHandler.StateMachine {
    mutating func setConnected(context: Context) {
        let promise = EmbeddedEventLoop().makePromise(of: RESPToken.self)
        self.setConnected(
            context: context,
            pendingHelloCommand: .init(promise: .nio(promise), requestID: 0, deadline: .now() + .seconds(30))
        )
    }

    mutating func receiveHelloResponse() {
        switch self.receivedResponse(token: .hello) {
        case .respond(let command, let deadlineAction):
            #expect(command.requestID == 0)
            #expect(deadlineAction == .cancel)
            command.promise.succeed(RESPToken(validated: ByteBuffer(string: "+OK\r\n")))
        case .closeWithError, .respondAndClose:
            Issue.record("Invalid receivedResponse action")
        }
    }
}
