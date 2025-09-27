//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
/// A sequence of subscription messages from multiple sequential Valkey subscriptions.
///
/// The sequence is passed a subscription and a continuation which is resumes when it has
/// finished with a subscription sequence. The async iterator iterates through messages
/// from the subscription until it receives a connection closed/closing error and at that
/// point asks for a new connection from the connection stream.
@available(valkeySwift 1.0, *)
public struct ValkeyClientSubscription: AsyncSequence, Sendable {
    @usableFromInline
    struct Connection: Sendable {
        @inlinable
        init(subscription: ValkeySubscription, continuation: CheckedContinuation<Void, Error>) {
            self.subscription = subscription
            self.continuation = continuation
        }
        @usableFromInline
        let subscription: ValkeySubscription
        @usableFromInline
        let continuation: CheckedContinuation<Void, Error>
    }
    @usableFromInline
    let connectionStream: AsyncStream<Connection>

    @usableFromInline
    static func makeStream() -> (Self, AsyncStream<Connection>.Continuation) {
        let (stream, cont) = AsyncStream.makeStream(of: Connection.self)
        return (.init(connectionStream: stream), cont)
    }

    /// Creates a sequence of subscription messages.
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(connectionIterator: connectionStream.makeAsyncIterator())
    }

    /// An iterator that provides subscription messages.
    public struct AsyncIterator: AsyncIteratorProtocol {
        @usableFromInline
        final class ConnectionIterator {
            @usableFromInline
            init(_ connection: Connection) {
                self.subscriptionIterator = connection.subscription.makeAsyncIterator()
                self.continuation = connection.continuation
            }
            private var subscriptionIterator: ValkeySubscription.AsyncIterator
            private var continuation: CheckedContinuation<Void, Error>?

            @usableFromInline
            func next() async throws -> ValkeySubscriptionMessage? {
                try await subscriptionIterator.next()
            }

            @usableFromInline
            func returnError(_ error: any Error) {
                self.continuation?.resume(throwing: error)
                self.continuation = nil
            }
            deinit {
                continuation?.resume()
            }
        }
        @usableFromInline
        var connectionIterator: AsyncStream<Connection>.AsyncIterator
        @usableFromInline
        var currentConnectionIterator: ConnectionIterator? = nil

        @usableFromInline
        init(connectionIterator: AsyncStream<Connection>.AsyncIterator) {
            self.connectionIterator = connectionIterator
        }

        @inlinable
        public mutating func next() async throws -> ValkeySubscriptionMessage? {
            if self.currentConnectionIterator == nil {
                guard let connection = await connectionIterator.next() else { return nil }
                print("Got connection")
                self.currentConnectionIterator = .init(connection)
            }
            let currentConnection = self.currentConnectionIterator!
            do {
                let message = try await self.currentConnectionIterator!.next()
                if message == nil {
                    self.currentConnectionIterator = nil
                }
                return message
            } catch let error as ValkeyClientError {
                // if connection closes for some reason don't exit loop so it opens a new connection
                switch error.errorCode {
                case .connectionClosed, .connectionClosedDueToCancellation, .connectionClosing:
                    currentConnection.returnError(error)
                    self.currentConnectionIterator = nil
                    return try await next()
                default:
                    currentConnection.returnError(error)
                    self.currentConnectionIterator = nil
                    return nil
                }
            } catch {
                currentConnection.returnError(error)
                self.currentConnectionIterator = nil
                return nil
            }
        }
    }
}
