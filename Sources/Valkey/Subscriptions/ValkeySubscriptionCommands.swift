//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey open source project
//
// Copyright (c) 2025 Apple Inc. and the swift-valkey project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-valkey project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import DequeModule

/// A subscription command does not return any values instead it pushes messages for each
/// channel/pattern that has been subscribed/unsubscribed to. This struct catches each
/// push notification and at the point we have received all the pushes required it returns
/// the associated value
struct ValkeySubscriptionCommandStack {
    struct SubscribeCommand {
        var filters: [ValkeySubscriptionFilter]

        mutating func received(_ subscription: ValkeySubscriptionFilter) throws -> Bool {
            guard let index = self.filters.firstIndex(of: subscription) else {
                throw ValkeyClientError(.subscriptionError, message: "Received unexpected push")
            }
            self.filters.remove(at: index)
            if self.filters.isEmpty {
                return true
            } else {
                return false
            }
        }
    }
    var commands: Deque<SubscribeCommand>

    init() {
        self.commands = []
    }

    mutating func pushCommand(_ subscriptions: [ValkeySubscriptionFilter]) {
        self.commands.append(.init(filters: subscriptions))
    }

    mutating func popCommand() -> SubscribeCommand? {
        self.commands.popFirst()
    }

    mutating func received(_ subscription: ValkeySubscriptionFilter) throws -> SubscribeCommand? {
        if try commands[commands.startIndex].received(subscription) {
            let command = commands.popFirst()
            return command
        } else {
            return nil
        }
    }
}
