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
import Synchronization
import Testing

@testable import Valkey

@Suite("AsyncInitializedReferencedObject Tests")
struct AsyncInitializedReferenceTests {
    /// Test Identifiable object
    final class Test: Sendable, Identifiable {
        let id: String

        init() {
            self.id = UUID().uuidString
        }
    }
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
        let referencedObject = Box(AsyncInitializedReferencedObject<Test>())
        let test = try await referencedObject.value.acquire {
            return Test()
        }
        let test2 = try await referencedObject.value.acquire {
            return Test()
        }
        // verify we get the same object twice
        #expect(test.id == test2.id)
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
        let referencedObject = Box(AsyncInitializedReferencedObject<Test>())
        let test = try await referencedObject.value.acquire {
            return Test()
        }
        let test2 = try await referencedObject.value.acquire {
            return Test()
        }
        let called = Atomic(0)
        referencedObject.value.release(id: test.id) { _ in
            called.add(1, ordering: .relaxed)
        }
        referencedObject.value.release(id: test2.id) { _ in
            called.add(2, ordering: .relaxed)
        }
        #expect(called.load(ordering: .relaxed) == 2)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testMultipleConcurrentAcquire() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            let referencedObject = Box(AsyncInitializedReferencedObject<Test>())
            for _ in 0..<500 {
                group.addTask {
                    let test = try await referencedObject.value.acquire {
                        try await Task.sleep(for: .milliseconds(50))
                        return Test()
                    }
                    let test2 = try await referencedObject.value.acquire {
                        try await Task.sleep(for: .milliseconds(50))
                        return Test()
                    }
                    #expect(test.id == test2.id)

                    referencedObject.value.release(id: test.id) { _ in }
                    referencedObject.value.release(id: test2.id) { _ in }
                }
            }
            for _ in 0..<100 {
                group.addTask {
                    let test = try await referencedObject.value.acquire {
                        try await Task.sleep(for: .milliseconds(50))
                        return Test()
                    }
                    referencedObject.value.release(id: test.id) { _ in }
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
        let referencedObject = Box(AsyncInitializedReferencedObject<Test>())
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
                    return Test()
                }
            }
            group.addTask {
                _ = try await referencedObject.value.acquire {
                    try await Task.sleep(for: .milliseconds(50))
                    return Test()
                }
            }
            try await Task.sleep(for: .milliseconds(50))
            cont2.finish()
        }
        // Verify we have two connections
        let value: Test = try #require(
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
        referencedObject.value.release(id: value.id) { _ in }
        referencedObject.value.release(id: value.id) { _ in }
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
        let referencedObject = Box(AsyncInitializedReferencedObject<Test>())
        let operationCalledCount = Box(Atomic(0))
        let acquireCalledCount = Box(Atomic(0))
        let releaseCalledCount = Box(Atomic(0))
        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<3 {
                group.addTask {
                    try await referencedObject.value.withValue { _ in
                        try await Task.sleep(for: .milliseconds(20))
                        operationCalledCount.value.add(1, ordering: .relaxed)
                    } acquire: {
                        try await Task.sleep(for: .milliseconds(20))
                        acquireCalledCount.value.add(1, ordering: .relaxed)
                        return Test()
                    } release: { _ in
                        releaseCalledCount.value.add(1, ordering: .relaxed)
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
