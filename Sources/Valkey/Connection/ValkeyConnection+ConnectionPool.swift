//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey project
//
// Copyright (c) 2025 the swift-valkey authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See swift-valkey/CONTRIBUTORS.txt for the list of swift-valkey authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import _ConnectionPoolModule

extension ValkeyConnection: PooledConnection {
    // connection id
    public typealias ID = Int
    // on close
    public func onClose(_ closure: @escaping @Sendable ((any Error)?) -> Void) {
        self.channel.closeFuture.whenComplete { _ in closure(nil) }
    }
}
