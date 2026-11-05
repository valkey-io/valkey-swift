//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import Synchronization
import Testing
import Valkey

struct UniqueOperationTests {
    @Test
    @available(valkeySwift 1.0, *)
    func testRun() async throws {
        let operation = UniqueOperation {
            1
        }
        await #expect(try operation.run() == 1)
    }
    @Test
    @available(valkeySwift 1.0, *)
    func testSubsequentRun() async throws {
        let value = Atomic(0)
        let operation = UniqueOperation {
            value.add(1, ordering: .relaxed).newValue
        }
        await #expect(try operation.run() == 1)
        await #expect(try operation.run() == 2)
    }
    @Test
    @available(valkeySwift 1.0, *)
    func testCancellation() async throws {
        let barrier = AsyncStream.makeStream(of: Void.self)
        let operation = UniqueOperation {
            barrier.continuation.yield()
            try await Task.sleep(for: .seconds(30))
        }
        await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await operation.run()
            }
            await barrier.stream.first { _ in true }
            group.cancelAll()
            await #expect(throws: CancellationError.self) {
                try await group.waitForAll()
            }
        }
    }
    @Test
    @available(valkeySwift 1.0, *)
    func testWaiter() async throws {
        let value = Atomic(0)
        let operation = UniqueOperation {
            let value = value.add(1, ordering: .relaxed).newValue
            try await Task.sleep(for: .milliseconds(100))
            return value
        }
        try await withThrowingTaskGroup(of: Int.self) { group in
            for _ in 0..<8 {
                group.addTask {
                    try await operation.run()
                }
            }
            for try await result in group {
                #expect(result == 1)
            }
        }
        // verify this is only the second time the operation runs
        await #expect(try operation.run() == 2)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testCancellationOfWaiter() async throws {
        let value = Atomic(0)
        let operation = UniqueOperation {
            let value = value.add(1, ordering: .relaxed).newValue
            try await Task.sleep(for: .milliseconds(100))
            return value
        }
        try await withThrowingTaskGroup(of: Int.self) { group in
            for _ in 0..<8 {
                group.addTask {
                    try await operation.run()
                }
            }
            await withThrowingTaskGroup(of: Int.self) { group in
                group.addTask {
                    try await operation.run()
                }
                group.cancelAll()
            }

            for try await result in group {
                #expect(result == 1)
            }
        }
        // verify this is only the second time the operation runs
        await #expect(try operation.run() == 2)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testCancellationOfAlreadyCancelledWaiter() async throws {
        let value = Atomic(0)
        let operation = UniqueOperation {
            let value = value.add(1, ordering: .relaxed).newValue
            try await Task.sleep(for: .milliseconds(100))
            return value
        }
        try await withThrowingTaskGroup(of: Int.self) { group in
            group.addTask {
                try await operation.run()
            }
            await withThrowingTaskGroup(of: Int.self) { group in
                group.cancelAll()
                group.addTask {
                    try await operation.run()
                }
            }

            for try await result in group {
                #expect(result == 1)
            }
        }
        // verify this is only the second time the operation runs
        await #expect(try operation.run() == 2)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testTransferOfOperationToWaiter() async throws {
        let value = Atomic(0)
        let barrier = AsyncStream.makeStream(of: Void.self)
        let operation = UniqueOperation {
            let value = value.add(1, ordering: .relaxed).newValue
            barrier.continuation.yield()
            try await Task.sleep(for: .milliseconds(100))
            return value
        }
        try await withThrowingTaskGroup(of: Int.self) { group in
            await withThrowingTaskGroup(of: Int.self) { group in
                group.addTask {
                    try await operation.run()
                }
                // make sure operation is running before cancelling it
                await barrier.stream.first { _ in true }
                group.cancelAll()
            }
            group.addTask {
                try await operation.run()
            }

            for try await result in group {
                #expect(result == 2)
            }
        }
        // verify this is the third time the operation runs
        await #expect(try operation.run() == 3)
    }
}
