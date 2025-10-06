//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore

extension EventLoopFuture {
    /// Get the result from an `EventLoopFuture` in an `async` context.
    ///
    /// - warning: This method currently violates Structured Concurrency because cancellation isn't respected.
    ///
    /// This function can be used to bridge an `EventLoopFuture` into the `async` world. Ie. if you're in an `async`
    /// function and want to get the result of this future.
    @inlinable
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    func _result() async -> Result<Value, any Error> where Value: Sendable {
        await withUnsafeContinuation { (cont: UnsafeContinuation<Result<Value, Error>, Never>) in
            self.whenComplete { result in
                cont.resume(returning: result)
            }
        }
    }
}
