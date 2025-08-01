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

import NIOCore

extension EventLoopFuture {
    /// Get the result from an `EventLoopFuture` in an `async` context.
    ///
    /// - warning: This method currently violates Structured Concurrency because cancellation isn't respected.
    ///
    /// This function can be used to bridge an `EventLoopFuture` into the `async` world. Ie. if you're in an `async`
    /// function and want to get the result of this future.
    @inlinable
    func _result() async -> Result<Value, Error> where Value: Sendable {
        await withUnsafeContinuation { (cont: UnsafeContinuation<Result<Value, Error>, Never>) in
            self.whenComplete { result in
                cont.resume(returning: result)
            }
        }
    }
}
