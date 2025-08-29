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
        case producing([ValkeyPromise<NIOSSLContext>])
        case cached(NIOSSLContext)
        case failed(any Error)
    }

    init(tlsConfiguration: TLSConfiguration) {
        self.tlsConfiguration = tlsConfiguration
    }

    func getSSLContext() async throws -> NIOSSLContext {
        enum Action {
            case produce
            case succeed(NIOSSLContext)
            case fail(any Error)
            case wait
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<NIOSSLContext, any Error>) in
            let action = self.stateLock.withLock { state -> Action in
                switch consume state {
                case .initialized:
                    state = .producing([.swift(continuation)])
                    return .produce

                case .cached(let context):
                    state = .cached(context)
                    return .succeed(context)

                case .failed(let error):
                    state = .failed(error)
                    return .fail(error)

                case .producing(var continuations):
                    continuations.append(.swift(continuation))
                    state = .producing(continuations)
                    return .wait
                }
            }

            switch action {
            case .wait:
                break

            case .produce:
                // TBD: we might want to consider moving this off the concurrent executor
                self.reportProduceSSLContextResult(
                    Result(catching: { try NIOSSLContext(configuration: tlsConfiguration) }),
                    for: tlsConfiguration
                )

            case .succeed(let context):
                continuation.resume(returning: context)

            case .fail(let error):
                continuation.resume(throwing: error)
            }
        }
    }

    private func reportProduceSSLContextResult(_ result: Result<NIOSSLContext, any Error>, for tlsConfiguration: TLSConfiguration) {
        enum Action {
            case fail(any Error, [ValkeyPromise<NIOSSLContext>])
            case succeed(NIOSSLContext, [ValkeyPromise<NIOSSLContext>])
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

        case .succeed(let context, let continuations):
            for continuation in continuations { continuation.succeed(context) }

        case .fail(let error, let continuations):
            for continuation in continuations { continuation.fail(error) }
        }
    }
}
