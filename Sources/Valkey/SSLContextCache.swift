//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import DequeModule
import NIOSSL
import Synchronization

@usableFromInline
@available(valkeySwift 1.0, *)
package protocol ValkeySSLContextProvider: Sendable {

    func getSSLContext() async throws -> NIOSSLContext
}

@available(valkeySwift 1.0, *)
final class SSLContextCache: ValkeySSLContextProvider {

    let tlsConfiguration: TLSConfiguration
    let stateLock = Mutex(State.initialized)

    enum State: ~Copyable {
        case initialized
        case producing(UniqueDeque<ValkeyPromise<NIOSSLContext>>)
        case cached(NIOSSLContext)
        case failed(any Error)
    }

    init(tlsConfiguration: TLSConfiguration) {
        self.tlsConfiguration = tlsConfiguration
    }

    func getSSLContext() async throws -> NIOSSLContext {
        enum Action: ~Copyable {
            case produce
            case succeed(NIOSSLContext, Continuation<NIOSSLContext, any Error>)
            case fail(any Error, Continuation<NIOSSLContext, any Error>)
            case wait
        }

        return try await withThrowingContinuation(of: NIOSSLContext.self) { continuation in
            var continuation: Optional<Continuation<NIOSSLContext, any Error>> = continuation
            let action = self.stateLock.withLock { state -> Action in
                let continuation = continuation.take()!
                switch consume state {
                case .initialized:
                    var deque = UniqueDeque<ValkeyPromise<NIOSSLContext>>()
                    deque.append(.swift(continuation))
                    state = .producing(deque)
                    return .produce

                case .cached(let context):
                    state = .cached(context)
                    return .succeed(context, continuation)

                case .failed(let error):
                    state = .failed(error)
                    return .fail(error, continuation)

                case .producing(var continuations):
                    continuations.append(.swift(continuation))
                    state = .producing(continuations)
                    return .wait
                }
            }

            switch consume action {
            case .wait:
                break

            case .produce:
                // TBD: we might want to consider moving this off the concurrent executor
                self.reportProduceSSLContextResult(
                    Result(catching: { try NIOSSLContext(configuration: tlsConfiguration) }),
                    for: tlsConfiguration
                )

            case .succeed(let context, let continuation):
                continuation.resume(returning: context)

            case .fail(let error, let continuation):
                continuation.resume(throwing: error)
            }
        }
    }

    private func reportProduceSSLContextResult(_ result: Result<NIOSSLContext, any Error>, for tlsConfiguration: TLSConfiguration) {
        enum Action: ~Copyable {
            case fail(any Error, UniqueDeque<ValkeyPromise<NIOSSLContext>>)
            case succeed(NIOSSLContext, UniqueDeque<ValkeyPromise<NIOSSLContext>>)
            case none
        }

        let action = self.stateLock.withLock { state -> Action in
            switch consume state {
            case .initialized:
                preconditionFailure("Invalid state: initialized")

            case .cached(let cached):
                state = .cached(cached)
                return .none

            case .failed(let error):
                state = .failed(error)
                return .none

            case .producing(let continuations):
                switch result {
                case .success(let context):
                    state = .cached(context)
                    return .succeed(context, continuations)

                case .failure(let failure):
                    state = .failed(failure)
                    return .fail(failure, continuations)
                }
            }
        }

        switch action {
        case .none:
            break

        case .succeed(let context, var continuations):
            while let continuation = continuations.popFirst() {
                continuation.succeed(context)
            }

        case .fail(let error, var continuations):
            while let continuation = continuations.popFirst() {
                continuation.fail(error)
            }
        }
    }
}
