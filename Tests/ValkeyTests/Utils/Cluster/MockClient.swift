//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import Synchronization
import Valkey

@available(valkeySwift 1.0, *)
final class MockClientFactory<NodeDescription: Sendable>: ValkeyNodeConnectionPoolFactory {

    let _runningPoolsLock = Mutex([MockClient<NodeDescription>]())

    init() {}

    func makeConnectionPool(nodeDescription: NodeDescription) -> MockClient<NodeDescription> {
        let pool = MockClient(nodeDescription: nodeDescription)
        self._runningPoolsLock.withLock {
            $0.append(pool)
        }
        return pool
    }
}

@available(valkeySwift 1.0, *)
final class MockClient<NodeDescription: Sendable>: ValkeyNodeConnectionPool {
    enum State {
        case initialized
        case running(CheckedContinuation<Void, Never>)
        case finished
    }

    let nodeDescription: NodeDescription
    let stateLock = Mutex(State.initialized)

    init(nodeDescription: NodeDescription) {
        self.nodeDescription = nodeDescription
    }

    func run() async {
        await withCheckedContinuation { continuation in
            self.stateLock.withLock { state in
                switch state {
                case .initialized:
                    state = .running(continuation)
                case .finished, .running:
                    preconditionFailure("Invalid state: \(state)")
                }
            }
        }
    }

    func triggerGracefulShutdown() {
        let continuation = self.stateLock.withLock { state -> CheckedContinuation<Void, Never>? in
            switch state {
            case .running(let continuation):
                state = .finished
                return continuation
            case .finished, .initialized:
                return nil
            }
        }

        continuation?.resume()
    }
}
