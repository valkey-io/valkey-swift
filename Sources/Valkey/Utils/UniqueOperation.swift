//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import Synchronization

@available(valkeySwift 1.0, *)
let idGenerator: Atomic<Int> = .init(0)

@available(valkeySwift 1.0, *)
struct UniqueOperation<Returns: Sendable>: ~Copyable {
    enum State {
        typealias WaiterID = Int
        typealias Waiter = CheckedContinuation<Returns?, any Error>

        struct ProcessingState {
            var waiters: [WaiterID: Waiter]

            init() {
                self.waiters = [:]
            }
        }
        case idle
        case processing(ProcessingState)

        enum TriggerAction {
            case perform
            case wait
        }
        mutating func triggerOperation() -> TriggerAction {
            switch self {
            case .idle:
                self = .processing(.init())
                return .perform
            case .processing:
                return .wait
            }
        }

        mutating func waitOnOperation(id: WaiterID, waiter: Waiter) {
            switch self {
            case .idle:
                self = .processing(.init())
                waiter.resume(returning: nil)
            case .processing(var state):
                state.waiters[id] = waiter
                self = .processing(state)
            }
        }

        mutating func updateWaiters() -> [WaiterID: Waiter].Values {
            switch self {
            case .idle:
                fatalError()
            case .processing(let state):
                let waiters = state.waiters.values
                self = .idle
                return waiters
            }
        }
    }

    let state: Mutex<State>
    let operation: @Sendable () async throws -> Returns

    init(_ operation: @escaping @Sendable () async throws -> Returns) {
        self.state = .init(.idle)
        self.operation = operation
    }

    func getResult() async throws -> Returns {
        let action = self.state.withLock {
            $0.triggerOperation()
        }
        switch action {
        case .perform:
            return try await performOperation()

        case .wait:
            let id = idGenerator.add(1, ordering: .relaxed).newValue
            let rt = try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Returns?, any Error>) in
                    self.state.withLock {
                        $0.waitOnOperation(id: id, waiter: cont)
                    }
                }
            } onCancel: {

            }
            if let rt {
                return rt
            } else {
                return try await performOperation()
            }
        }
    }

    func performOperation() async throws -> Returns {
        do {
            let result = try await self.operation()
            let waiters = self.state.withLock {
                $0.updateWaiters()
            }
            for waiter in waiters {
                waiter.resume(returning: result)
            }
            return result
        } catch {
            let waiters = self.state.withLock {
                $0.updateWaiters()
            }
            for waiter in waiters {
                waiter.resume(throwing: error)
            }
            throw error
        }
    }
}
