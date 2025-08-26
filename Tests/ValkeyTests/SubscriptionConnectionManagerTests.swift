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

import Foundation
import Logging
import NIOEmbedded
import Synchronization
import Testing

@testable import Valkey

@Suite("SubscriptionConnectionManager Tests")
struct SubscriptionConnectionManagerTests {
    struct StateMachine {
        @Test
        @available(valkeySwift 1.0, *)
        func testAcquireRelease() {
            var stateMachine = SubscriptionConnectionStateMachine<String, Int>()
            let action1 = stateMachine.get(id: 0, request: 10)
            let action2 = stateMachine.acquired(result: .success("Connection"))
            let action3 = stateMachine.release(id: 0)
            #expect(action1 == .startAcquire)
            #expect(action2 == .yield([10]))
            #expect(action3 == .release("Connection"))
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testAcquireReleaseTwice() {
            var stateMachine = SubscriptionConnectionStateMachine<String, Int>()
            do {
                let action1 = stateMachine.get(id: 0, request: 10)
                let action2 = stateMachine.acquired(result: .success("Connection"))
                let action3 = stateMachine.release(id: 0)
                #expect(action1 == .startAcquire)
                #expect(action2 == .yield([10]))
                #expect(action3 == .release("Connection"))
            }
            do {
                let action1 = stateMachine.get(id: 1, request: 11)
                let action2 = stateMachine.acquired(result: .success("Connection"))
                let action3 = stateMachine.release(id: 1)
                #expect(action1 == .startAcquire)
                #expect(action2 == .yield([11]))
                #expect(action3 == .release("Connection"))
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testConcurrentAcquireRelease() {
            var stateMachine = SubscriptionConnectionStateMachine<String, Int>()
            let action1 = stateMachine.get(id: 0, request: 10)
            let action2 = stateMachine.get(id: 1, request: 11)
            let action3 = stateMachine.acquired(result: .success("Connection"))
            let action4 = stateMachine.release(id: 1)
            let action5 = stateMachine.release(id: 0)
            #expect(action1 == .startAcquire)
            #expect(action2 == .doNothing)
            #expect(action3 == .yield([10, 11]))
            #expect(action4 == .doNothing)
            #expect(action5 == .release("Connection"))
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testGetAfterAcquire() {
            do {
                var stateMachine = SubscriptionConnectionStateMachine<String, Int>()
                let action1 = stateMachine.get(id: 0, request: 10)
                let action3 = stateMachine.acquired(result: .success("Connection"))
                let action2 = stateMachine.get(id: 1, request: 11)
                let action4 = stateMachine.release(id: 1)
                let action5 = stateMachine.release(id: 0)
                #expect(action1 == .startAcquire)
                #expect(action3 == .yield([10]))
                #expect(action2 == .completeRequest("Connection"))
                #expect(action4 == .doNothing)
                #expect(action5 == .release("Connection"))
            }
            do {
                var stateMachine = SubscriptionConnectionStateMachine<String, Int>()
                let action1 = stateMachine.get(id: 0, request: 10)
                let action3 = stateMachine.acquired(result: .success("Connection"))
                let action2 = stateMachine.get(id: 1, request: 11)
                let action4 = stateMachine.release(id: 0)
                let action5 = stateMachine.release(id: 1)
                #expect(action1 == .startAcquire)
                #expect(action3 == .yield([10]))
                #expect(action2 == .completeRequest("Connection"))
                #expect(action4 == .doNothing)
                #expect(action5 == .release("Connection"))
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testCancelWhileAcquiring() {
            var stateMachine = SubscriptionConnectionStateMachine<String, Int>()
            let action1 = stateMachine.get(id: 0, request: 10)
            let action2 = stateMachine.cancel(id: 0)
            let action3 = stateMachine.acquired(result: .success("Connection"))
            #expect(action1 == .startAcquire)
            #expect(action2 == .cancel(10))
            #expect(action3 == .release("Connection"))
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testCancelAfterAcquiring() {
            var stateMachine = SubscriptionConnectionStateMachine<String, Int>()
            let action1 = stateMachine.get(id: 0, request: 10)
            let action2 = stateMachine.acquired(result: .success("Connection"))
            let action3 = stateMachine.cancel(id: 0)
            #expect(action1 == .startAcquire)
            #expect(action2 == .yield([10]))
            #expect(action3 == .release("Connection"))
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testCancelWhileMulitpleAcquiring() {
            var stateMachine = SubscriptionConnectionStateMachine<String, Int>()
            let action1 = stateMachine.get(id: 0, request: 10)
            let action2 = stateMachine.get(id: 1, request: 11)
            let action3 = stateMachine.cancel(id: 0)
            let action4 = stateMachine.acquired(result: .success("Connection"))
            let action5 = stateMachine.release(id: 1)
            #expect(action1 == .startAcquire)
            #expect(action2 == .doNothing)
            #expect(action3 == .cancel(10))
            #expect(action4 == .yield([11]))
            #expect(action5 == .release("Connection"))
        }
    }
}

@available(valkeySwift 1.0, *)
extension SubscriptionConnectionStateMachine.GetAction: Equatable where Value: Equatable, Request: Equatable {
    public static func == (_ lhs: Self, _ rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.startAcquire, .startAcquire), (.doNothing, .doNothing):
            true
        case (.completeRequest(let lhs), .completeRequest(let rhs)):
            lhs == rhs
        default:
            false
        }
    }
}

@available(valkeySwift 1.0, *)
extension SubscriptionConnectionStateMachine.AcquiredAction: Equatable where Value: Equatable, Request: Equatable & Comparable {
    public static func == (_ lhs: Self, _ rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.doNothing, .doNothing):
            true
        case (.yield(let lhs), .yield(let rhs)):
            lhs.sorted() == rhs.sorted()
        case (.release(let lhs), .release(let rhs)):
            lhs == rhs
        default:
            false
        }
    }
}

@available(valkeySwift 1.0, *)
extension SubscriptionConnectionStateMachine.CancelAction: Equatable where Value: Equatable, Request: Equatable {
    public static func == (_ lhs: Self, _ rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.doNothing, .doNothing):
            true
        case (.cancel(let lhs), .cancel(let rhs)):
            lhs == rhs
        case (.release(let lhs), .release(let rhs)):
            lhs == rhs
        default:
            false
        }
    }
}

@available(valkeySwift 1.0, *)
extension SubscriptionConnectionStateMachine.ReleaseAction: Equatable where Value: Equatable, Request: Equatable {
    public static func == (_ lhs: Self, _ rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.doNothing, .doNothing):
            true
        case (.release(let lhs), .release(let rhs)):
            lhs == rhs
        default:
            false
        }
    }
}
