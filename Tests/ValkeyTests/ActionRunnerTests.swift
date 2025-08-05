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

import Synchronization
import Testing

@testable import Valkey

struct ActionRunnerTests {
    @available(valkeySwift 1.0, *)
    @Test
    func testRunsAction() async throws {
        final class TestActionRunner: ActionRunner {
            let (stream, cont) = AsyncStream.makeStream(of: Void.self)
            let actionStream: ActionStream<Action> = .init()

            enum Action {
                case action1
            }
            func runAction(_ action: Action) async {
                switch action {
                case .action1:
                    cont.yield()
                }
            }
        }
        let test = TestActionRunner()
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await test.runActionTaskGroup()
            }
            test.queueAction(.action1)
            await test.stream.first { _ in true }
            group.cancelAll()
        }
    }

    @available(valkeySwift 1.0, *)
    @Test
    func testRunsMultipleActions() async throws {
        final class TestActionRunner: ActionRunner {
            let (stream, cont) = AsyncStream.makeStream(of: Void.self)
            let actionStream: ActionStream<Action> = .init()
            let value = Mutex<Int>(0)
            enum Action {
                case action1
                case action2
            }
            func runAction(_ action: Action) async {
                switch action {
                case .action1:
                    value.withLock { $0 = $0 + 1 }
                    cont.yield()
                case .action2:
                    value.withLock { $0 = $0 + 2 }
                    cont.yield()
                }
            }
        }
        let test = TestActionRunner()
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await test.runActionTaskGroup()
            }
            test.queueAction(.action1)
            test.queueAction(.action2)
            await test.stream.first { _ in true }
            await test.stream.first { _ in true }
            test.value.withLock {
                #expect($0 == 3)
            }
            group.cancelAll()
        }
    }

    @available(valkeySwift 1.0, *)
    @Test
    func testCancellationPropagatesToActions() async throws {
        final class TestActionRunner: ActionRunner {
            let (stream, cont) = AsyncStream.makeStream(of: Void.self)
            let actionStream: ActionStream<Action> = .init()
            enum Action {
                case action1
            }
            func runAction(_ action: Action) async {
                switch action {
                case .action1:
                    cont.yield()
                    try? await Task.sleep(for: .seconds(60))
                }
            }
        }
        let test = TestActionRunner()
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await test.runActionTaskGroup()
            }
            test.queueAction(.action1)
            await test.stream.first { _ in true }
            let now = ContinuousClock.now
            group.cancelAll()
            #expect(.now - now < .seconds(1))
        }
    }
}
