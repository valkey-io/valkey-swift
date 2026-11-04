//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import Synchronization

/// A UniqueOperation holds a closure that can only ever have one instance of itself running
@available(valkeySwift 1.0, *)
package struct UniqueOperation<Returns: Sendable>: ~Copyable {
    struct StateMachine<Waiter>: ~Copyable {
        enum State: ~Copyable {
            struct ProcessingState {
                var waiters: [Int: Waiter]
            }
            case idle
            case processing(ProcessingState)
        }

        var state: State

        init() {
            self.state = .idle
        }

        private init(state: consuming State) {
            self.state = state
        }

        enum RunAction {
            case run
            case wait
        }
        mutating func runOperation() -> RunAction {
            switch consume self.state {
            case .idle:
                self = .processing(.init(waiters: [:]))
                return .run
            case .processing(let state):
                self = .processing(state)
                return .wait
            }
        }

        enum WaitOnOperationAction {
            case doNothing
            case takeOverRunningOperation
        }
        mutating func waitOnOperation(id: Int, waiter: Waiter) -> WaitOnOperationAction {
            switch consume self.state {
            case .idle:
                self = .processing(.init(waiters: [:]))
                return .takeOverRunningOperation
            case .processing(var state):
                state.waiters[id] = waiter
                self = .processing(state)
                return .doNothing
            }
        }

        mutating func updateWaiters() -> [Int: Waiter].Values {
            switch consume self.state {
            case .idle:
                preconditionFailure("Cannot update waiters while in idle state")
            case .processing(let state):
                let waiters = state.waiters.values
                self = .idle
                return waiters
            }
        }

        mutating func cancelWaiter(id: Int) -> Waiter? {
            switch consume self.state {
            case .idle:
                preconditionFailure("Cannot cancel waiter in idle state")
            case .processing(var state):
                let waiter = state.waiters.removeValue(forKey: id)
                self = .processing(state)
                return waiter
            }
        }

        mutating func transferProcess() -> Waiter? {
            switch consume self.state {
            case .idle:
                preconditionFailure("Cannot transfer control of process in idle state")
            case .processing(var state):
                if let first = state.waiters.first {
                    state.waiters.remove(at: state.waiters.startIndex)
                    self = .processing(state)
                    return first.value
                } else {
                    self = .idle
                    return nil
                }
            }
        }

        static var idle: Self { .init(state: .idle) }
        static func processing(_ state: State.ProcessingState) -> Self { .init(state: .processing(state)) }
    }

    let stateMachine: Mutex<StateMachine<CheckedContinuation<Returns?, any Error>>>
    let operation: @Sendable () async throws -> Returns
    let idGenerator: Atomic<Int> = .init(0)

    package init(_ operation: @escaping @Sendable () async throws -> Returns) {
        self.stateMachine = .init(.init())
        self.operation = operation
    }

    package func run() async throws -> Returns {
        let action = self.stateMachine.withLock {
            $0.runOperation()
        }
        switch action {
        case .run:
            return try await runOperation()

        case .wait:
            let id = idGenerator.add(1, ordering: .relaxed).newValue
            let rt = try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Returns?, any Error>) in
                    if Task.isCancelled {
                        cont.resume(throwing: CancellationError())
                        return
                    }
                    self.stateMachine.withLock {
                        switch $0.waitOnOperation(id: id, waiter: cont) {
                        case .takeOverRunningOperation:
                            cont.resume(returning: nil)
                        case .doNothing:
                            break
                        }
                    }
                }
            } onCancel: {
                if let waiter = self.stateMachine.withLock({ $0.cancelWaiter(id: id) }) {
                    waiter.resume(throwing: CancellationError())
                }
            }
            // continuation returns result of operation or nil. Nil means control of the process
            // has been transfered to this task
            if let rt {
                return rt
            } else {
                return try await runOperation()
            }
        }
    }

    func runOperation() async throws -> Returns {
        do {
            let result = try await self.operation()
            self.updateWaiters(.success(result))
            return result
        } catch {
            self.updateWaiters(.failure(error))
            throw error
        }
    }

    func updateWaiters(_ result: Result<Returns?, any Error>) {
        guard !Task.isCancelled else {
            if let waiter = self.stateMachine.withLock({ $0.transferProcess() }) {
                waiter.resume(returning: nil)
            }
            return
        }
        let waiters = self.stateMachine.withLock {
            $0.updateWaiters()
        }
        for waiter in waiters {
            waiter.resume(with: result)
        }
    }
}
