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

@Suite("AsyncInitializedReferencedObject Tests")
struct SubscriptionConnectionManagerTests {
    /// Box for non-Copyable type so we can pass it around more easily
    final class Box<Value: ~Copyable & Sendable>: Sendable {
        let value: Value

        init(_ value: consuming Value) {
            self.value = value
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testReferenceCount() async throws {
        let referencedObject = Box(SubscriptionConnectionManager())
        let connection = try await referencedObject.value.acquire {
            return try await ValkeyConnection.setupChannelAndConnect(NIOAsyncTestingChannel(), configuration: .init(), logger: Logger(label: "test"))
        }
        let connection2 = try await referencedObject.value.acquire {
            return try await ValkeyConnection.setupChannelAndConnect(NIOAsyncTestingChannel(), configuration: .init(), logger: Logger(label: "test"))
        }
        // verify we get the same object twice
        #expect(connection === connection2)
        // Verify we have two references
        referencedObject.value.state.withLock { state in
            switch state {
            case .available(_, let count):
                #expect(count == 2)
            case .acquiring, .uninitialized:
                Issue.record("Should have a connection")
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testReleaseGetsCalledOnce() async throws {
        let referencedObject = Box(SubscriptionConnectionManager())
        let connection = try await referencedObject.value.acquire {
            return try await ValkeyConnection.setupChannelAndConnect(NIOAsyncTestingChannel(), configuration: .init(), logger: Logger(label: "test"))
        }
        let connection2 = try await referencedObject.value.acquire {
            return try await ValkeyConnection.setupChannelAndConnect(NIOAsyncTestingChannel(), configuration: .init(), logger: Logger(label: "test"))
        }
        let called = Atomic(0)
        referencedObject.value.release(connection: connection) { connection in
            called.add(1, ordering: .relaxed)
            connection.close()
        }
        referencedObject.value.release(connection: connection2) { connection in
            called.add(2, ordering: .relaxed)
            connection.close()
        }
        #expect(called.load(ordering: .relaxed) == 2)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testMultipleConcurrentAcquire() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            let referencedObject = Box(SubscriptionConnectionManager())
            for _ in 0..<500 {
                group.addTask {
                    let connection = try await referencedObject.value.acquire {
                        try await Task.sleep(for: .milliseconds(50))
                        return try await ValkeyConnection.setupChannelAndConnect(
                            NIOAsyncTestingChannel(),
                            configuration: .init(),
                            logger: Logger(label: "test")
                        )
                    }
                    let connection2 = try await referencedObject.value.acquire {
                        try await Task.sleep(for: .milliseconds(50))
                        return try await ValkeyConnection.setupChannelAndConnect(
                            NIOAsyncTestingChannel(),
                            configuration: .init(),
                            logger: Logger(label: "test")
                        )
                    }
                    #expect(connection === connection2)

                    referencedObject.value.release(connection: connection) { $0.close() }
                    referencedObject.value.release(connection: connection2) { $0.close() }
                }
            }
            for _ in 0..<100 {
                group.addTask {
                    let connection = try await referencedObject.value.acquire {
                        try await Task.sleep(for: .milliseconds(50))
                        return try await ValkeyConnection.setupChannelAndConnect(
                            NIOAsyncTestingChannel(),
                            configuration: .init(),
                            logger: Logger(label: "test")
                        )
                    }
                    referencedObject.value.release(connection: connection) { _ in }
                }
            }
            try await group.waitForAll()
            referencedObject.value.state.withLock { state in
                if case .uninitialized = state {
                } else {
                    Issue.record("Subscription channel should have been relesed")
                }
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testCancellationWhileAcquiring() async throws {
        let referencedObject = Box(SubscriptionConnectionManager())
        try await withThrowingTaskGroup(of: Void.self) { group in
            let (stream1, cont1) = AsyncStream.makeStream(of: Void.self)
            let (stream2, cont2) = AsyncStream.makeStream(of: Void.self)
            // Run acquire three times, with the first one throwing a cancellation error. Use
            // AsyncStream to ensure all acquires are active at the same time
            group.addTask {
                _ = try await referencedObject.value.acquire {
                    cont1.finish()
                    await stream2.first { _ in true }
                    throw CancellationError()
                }
            }
            await stream1.first { _ in true }
            group.addTask {
                _ = try await referencedObject.value.acquire {
                    try await Task.sleep(for: .milliseconds(50))
                    return try await ValkeyConnection.setupChannelAndConnect(
                        NIOAsyncTestingChannel(),
                        configuration: .init(),
                        logger: Logger(label: "test")
                    )
                }
            }
            group.addTask {
                _ = try await referencedObject.value.acquire {
                    try await Task.sleep(for: .milliseconds(50))
                    return try await ValkeyConnection.setupChannelAndConnect(
                        NIOAsyncTestingChannel(),
                        configuration: .init(),
                        logger: Logger(label: "test")
                    )
                }
            }
            try await Task.sleep(for: .milliseconds(50))
            cont2.finish()
        }
        // Verify we have two connections
        let value: ValkeyConnection = try #require(
            referencedObject.value.state.withLock { state in
                switch state {
                case .available(let value, let count):
                    #expect(count == 2)
                    return value
                case .acquiring, .uninitialized:
                    Issue.record("Should have a connection")
                    return nil
                }
            }
        )
        // Verify once we run release twice we have no connection
        referencedObject.value.release(connection: value) { _ in }
        referencedObject.value.release(connection: value) { _ in }
        referencedObject.value.state.withLock { state in
            switch state {
            case .uninitialized:
                break
            case .acquiring, .available:
                Issue.record("Should have a connection")
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testWithValue() async throws {
        let referencedObject = Box(SubscriptionConnectionManager())
        let operationCalledCount = Box(Atomic(0))
        let acquireCalledCount = Box(Atomic(0))
        let releaseCalledCount = Box(Atomic(0))
        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<3 {
                group.addTask {
                    try await referencedObject.value.withConnection { _ in
                        try await Task.sleep(for: .milliseconds(20))
                        operationCalledCount.value.add(1, ordering: .relaxed)
                    } acquire: {
                        try await Task.sleep(for: .milliseconds(20))
                        acquireCalledCount.value.add(1, ordering: .relaxed)
                        return try await ValkeyConnection.setupChannelAndConnect(
                            NIOAsyncTestingChannel(),
                            configuration: .init(),
                            logger: Logger(label: "test")
                        )
                    } release: { connection in
                        releaseCalledCount.value.add(1, ordering: .relaxed)
                        connection.close()
                    }
                }
            }
            try await group.waitForAll()
        }
        #expect(operationCalledCount.value.load(ordering: .relaxed) == 3)
        #expect(acquireCalledCount.value.load(ordering: .relaxed) == 1)
        #expect(releaseCalledCount.value.load(ordering: .relaxed) == 1)
    }
}
