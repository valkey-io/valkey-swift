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

struct ActionStream<Action: Sendable>: Sendable {
    let stream: AsyncStream<Action>
    let continuation: AsyncStream<Action>.Continuation

    init() {
        (self.stream, self.continuation) = AsyncStream.makeStream()
    }
}

protocol ActionRunner: Sendable {
    associatedtype Action: Sendable

    /// stream of actions to execute.
    var actionStream: ActionStream<Action> { get }

    /// Run action
    func runAction(_ action: Action) async
}

@available(valkeySwift 1.0, *)
extension ActionRunner {
    /// Run discarding task group running actions
    func runActionTaskGroup() async {
        await withDiscardingTaskGroup { group in
            for await action in actionStream.stream {
                group.addTask {
                    await self.runAction(action)
                }
            }
        }
    }

    /// Queue action to be run
    func queueAction(_ action: Action) {
        self.actionStream.continuation.yield(action)
    }
}
