//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Synchronization
import Valkey

@available(valkeySwift 1.0, *)
final class MockClientFactory: ValkeyNodeConnectionPoolFactory {

    let _runningPoolsLock = Mutex([MockClient]())

    init() {}

    func makeConnectionPool(nodeDescription: ValkeyNodeDescription) -> MockClient {
        let pool = MockClient(nodeDescription: nodeDescription)
        self._runningPoolsLock.withLock {
            $0.append(pool)
        }
        return pool
    }
}

@available(valkeySwift 1.0, *)
final class MockClient: ValkeyNodeConnectionPool {
    enum State {
        case initialized
        case running(CheckedContinuation<Void, Never>)
        case finished
    }

    let nodeDescription: ValkeyNodeDescription
    let stateLock = Mutex(State.initialized)

    init(nodeDescription: ValkeyNodeDescription) {
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
