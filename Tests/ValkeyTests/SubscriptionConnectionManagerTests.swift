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
            var stateMachine = SubscriptionConnectionStateMachine<String, Int, Int>()
            let action1 = stateMachine.get(id: 0, request: 10)
            let action2 = stateMachine.acquired("Connection", releaseRequest: 100)
            let action3 = stateMachine.release(id: 0)
            #expect(action1 == .startAcquire)
            #expect(action2 == .yield([10]))
            #expect(action3 == .release(100))
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testAcquireReleaseTwice() {
            var stateMachine = SubscriptionConnectionStateMachine<String, Int, Int>()
            do {
                let action1 = stateMachine.get(id: 0, request: 10)
                let action2 = stateMachine.acquired("Connection", releaseRequest: 100)
                let action3 = stateMachine.release(id: 0)
                #expect(action1 == .startAcquire)
                #expect(action2 == .yield([10]))
                #expect(action3 == .release(100))
            }
            do {
                let action1 = stateMachine.get(id: 1, request: 11)
                let action2 = stateMachine.acquired("Connection", releaseRequest: 100)
                let action3 = stateMachine.release(id: 1)
                #expect(action1 == .startAcquire)
                #expect(action2 == .yield([11]))
                #expect(action3 == .release(100))
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testConcurrentAcquireRelease() {
            var stateMachine = SubscriptionConnectionStateMachine<String, Int, Int>()
            let action1 = stateMachine.get(id: 0, request: 10)
            let action2 = stateMachine.get(id: 1, request: 11)
            let action3 = stateMachine.acquired("Connection", releaseRequest: 100)
            let action4 = stateMachine.release(id: 1)
            let action5 = stateMachine.release(id: 0)
            #expect(action1 == .startAcquire)
            #expect(action2 == .doNothing)
            #expect(action3 == .yield([10, 11]))
            #expect(action4 == .doNothing)
            #expect(action5 == .release(100))
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testGetAfterAcquire() {
            do {
                var stateMachine = SubscriptionConnectionStateMachine<String, Int, Int>()
                let action1 = stateMachine.get(id: 0, request: 10)
                let action2 = stateMachine.acquired("Connection", releaseRequest: 100)
                let action3 = stateMachine.get(id: 1, request: 11)
                let action4 = stateMachine.release(id: 1)
                let action5 = stateMachine.release(id: 0)
                #expect(action1 == .startAcquire)
                #expect(action2 == .yield([10]))
                #expect(action3 == .completeRequest("Connection"))
                #expect(action4 == .doNothing)
                #expect(action5 == .release(100))
            }
            do {
                var stateMachine = SubscriptionConnectionStateMachine<String, Int, Int>()
                let action1 = stateMachine.get(id: 0, request: 10)
                let action2 = stateMachine.acquired("Connection", releaseRequest: 100)
                let action3 = stateMachine.get(id: 1, request: 11)
                let action4 = stateMachine.release(id: 0)
                let action5 = stateMachine.release(id: 1)
                #expect(action1 == .startAcquire)
                #expect(action2 == .yield([10]))
                #expect(action3 == .completeRequest("Connection"))
                #expect(action4 == .doNothing)
                #expect(action5 == .release(100))
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testCancelWhileAcquiring() {
            var stateMachine = SubscriptionConnectionStateMachine<String, Int, Int>()
            let action1 = stateMachine.get(id: 0, request: 10)
            let action2 = stateMachine.cancel(id: 0)
            #expect(action1 == .startAcquire)
            #expect(action2 == .cancel(10))
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testCancelAfterAcquiring() {
            var stateMachine = SubscriptionConnectionStateMachine<String, Int, Int>()
            let action1 = stateMachine.get(id: 0, request: 10)
            let action2 = stateMachine.acquired("Connection", releaseRequest: 100)
            let action3 = stateMachine.cancel(id: 0)
            #expect(action1 == .startAcquire)
            #expect(action2 == .yield([10]))
            #expect(action3 == .release(100))
        }

        @Test
        @available(valkeySwift 1.0, *)
        func testCancelWhileMulitpleAcquiring() {
            var stateMachine = SubscriptionConnectionStateMachine<String, Int, Int>()
            let action1 = stateMachine.get(id: 0, request: 10)
            let action2 = stateMachine.get(id: 1, request: 11)
            let action3 = stateMachine.cancel(id: 0)
            let action4 = stateMachine.acquired("Connection", releaseRequest: 100)
            let action5 = stateMachine.release(id: 1)
            #expect(action1 == .startAcquire)
            #expect(action2 == .doNothing)
            #expect(action3 == .cancel(10))
            #expect(action4 == .yield([11]))
            #expect(action5 == .release(100))
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
        case (.yield(let lhs), .yield(let rhs)):
            lhs.sorted() == rhs.sorted()
        }
    }
}

@available(valkeySwift 1.0, *)
extension SubscriptionConnectionStateMachine.CancelAction: Equatable where Value: Equatable, Request: Equatable, ReleaseRequest: Equatable {
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
extension SubscriptionConnectionStateMachine.ReleaseAction: Equatable where Value: Equatable, Request: Equatable, ReleaseRequest: Equatable {
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
