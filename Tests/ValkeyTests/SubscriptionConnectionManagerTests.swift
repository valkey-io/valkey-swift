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
            var stateMachine = SubscriptionConnectionManager.StateMachine<String, Int>()
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
            var stateMachine = SubscriptionConnectionManager.StateMachine<String, Int>()
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
            var stateMachine = SubscriptionConnectionManager.StateMachine<String, Int>()
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
                var stateMachine = SubscriptionConnectionManager.StateMachine<String, Int>()
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
                var stateMachine = SubscriptionConnectionManager.StateMachine<String, Int>()
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
            var stateMachine = SubscriptionConnectionManager.StateMachine<String, Int>()
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
            var stateMachine = SubscriptionConnectionManager.StateMachine<String, Int>()
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
            var stateMachine = SubscriptionConnectionManager.StateMachine<String, Int>()
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

    @available(valkeySwift 1.0, *)
    func testWithSubscriptionConnectionManager(
        delay: Duration? = nil,
        _ operation: @Sendable (SubscriptionConnectionManager) async throws -> Void
    ) async throws -> (Int, Int) {
        let logger = {
            var logger = Logger(label: "Subscriptions")
            logger.logLevel = .trace
            return logger
        }()
        let subscriptionConnectionManager = SubscriptionConnectionManager(logger: logger)
        return try await withThrowingTaskGroup(of: Void.self) { group in
            let leaseCount = Atomic(0)
            let releaseCount = Atomic(0)
            group.addTask {

                await subscriptionConnectionManager.run {
                    leaseCount.add(1, ordering: .relaxed)
                    if let delay {
                        try await Task.sleep(for: delay)
                    }
                    let channel = NIOAsyncTestingChannel()
                    let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
                    try await channel.processHello()
                    return connection
                } release: { connection in
                    releaseCount.add(1, ordering: .relaxed)
                    Task {
                        connection.close()
                    }
                }
            }
            try await operation(subscriptionConnectionManager)
            subscriptionConnectionManager.shutdown()
            try await group.waitForAll()
            return (leaseCount.load(ordering: .relaxed), releaseCount.load(ordering: .relaxed))
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testWithConnection() async throws {
        let stats = try await testWithSubscriptionConnectionManager { subscriptionConnectionManager in
            try await subscriptionConnectionManager.withConnection { _ in
            }
        }
        #expect(stats.0 == 1)
        #expect(stats.1 == 1)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testWithConnectionTwice() async throws {
        let stats = try await testWithSubscriptionConnectionManager { subscriptionConnectionManager in
            try await subscriptionConnectionManager.withConnection { _ in
            }
            try await subscriptionConnectionManager.withConnection { _ in
            }
        }
        #expect(stats.0 == 2)
        #expect(stats.1 == 2)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testConcurrentWithConnection() async throws {
        let stats = try await testWithSubscriptionConnectionManager { subscriptionConnectionManager in
            await withThrowingTaskGroup(of: Void.self) { group in
                for _ in 0..<50 {
                    group.addTask {
                        try await subscriptionConnectionManager.withConnection { _ in
                            try await Task.sleep(for: .milliseconds(2))
                        }
                    }
                }
            }
        }
        #expect(stats.0 == 1)
        #expect(stats.1 == 1)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testConcurrentWithConnectionOnceAcquired() async throws {
        let stats = try await testWithSubscriptionConnectionManager { subscriptionConnectionManager in
            await withThrowingTaskGroup(of: Void.self) { group in
                let (stream, cont) = AsyncStream.makeStream(of: Void.self)
                group.addTask {
                    try await subscriptionConnectionManager.withConnection { _ in
                        cont.finish()
                        try await Task.sleep(for: .milliseconds(2))
                    }
                }
                group.addTask {
                    await stream.first { _ in true }
                    try await subscriptionConnectionManager.withConnection { _ in
                    }
                }
            }
        }
        #expect(stats.0 == 1)
        #expect(stats.1 == 1)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testCancel() async throws {
        let stats = try await testWithSubscriptionConnectionManager(delay: .seconds(1)) { subscriptionConnectionManager in
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await subscriptionConnectionManager.withConnection { _ in
                        try await Task.sleep(for: .milliseconds(2))
                    }
                }
                try await Task.sleep(for: .milliseconds(1))
                group.cancelAll()
            }
        }
        #expect(stats.0 == 1)
        #expect(stats.1 == 1)
    }
}

@available(valkeySwift 1.0, *)
extension SubscriptionConnectionManager.StateMachine.GetAction: Equatable where Value: Equatable, Request: Equatable {
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
extension SubscriptionConnectionManager.StateMachine.AcquiredAction: Equatable where Value: Equatable, Request: Equatable & Comparable {
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
extension SubscriptionConnectionManager.StateMachine.CancelAction: Equatable where Value: Equatable, Request: Equatable {
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
extension SubscriptionConnectionManager.StateMachine.ReleaseAction: Equatable where Value: Equatable, Request: Equatable {
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
