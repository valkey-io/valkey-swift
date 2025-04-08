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

import Logging
import Synchronization

/// Container for all subscriptions on one connection
struct ValkeySubscriptions {
    struct Subscription {
        let id: Int
        let subscription: ValkeySubscription
        var stateMachine: ValkeySubscriptionStateMachine
    }

    static let globalSubscriptionId = Atomic<Int>(0)

    init(logger: Logger) {
        self.subscriptions = []
        self.logger = logger
    }

    /// We received a push notification
    mutating func notify(_ token: RESPToken) throws -> Bool {
        let pushToken: PushToken
        do {
            pushToken = try PushToken(from: token)
        } catch {
            // push error to all subscriptions on this channel. We're about to close
            // the channel we should tell them why
            for subscription in subscriptions {
                subscription.subscription.sendError(error)
            }
            subscriptions = []
            throw error
        }

        self.logger.trace("\(pushToken)")

        //var returnValue = false
        for index in subscriptions.indices.reversed() {
            switch subscriptions[index].stateMachine.receivedToken(pushToken) {
            case .sendMessage(let message):
                subscriptions[index].subscription.sendMessage(message)
            case .fail(let error):
                subscriptions[index].subscription.sendError(error)
                subscriptions.remove(at: index)
            case .deleteSubscriptionAndReturnOk:
                subscriptions[index].subscription.finish()
                subscriptions.remove(at: index)
                return true
            case .returnOk:
                // push message is associated with a command. Given successful commands don't return
                // anything unless there is an error we catch the associated push message and then
                // return ok
                return true
            case .doNothing:
                break
            }
        }
        return false
    }

    /// Connection is closing lets inform all the subscriptions
    mutating func close() {
        for subscription in subscriptions {
            subscription.subscription.sendError(ValkeyClientError(.connectionClosed))
        }
        self.subscriptions = []
    }

    static func getSubscriptionID() -> Int {
        Self.globalSubscriptionId.wrappingAdd(1, ordering: .relaxed).newValue
    }

    /// Add subscription to channel.
    ///
    /// This subscription is not considered active until is has received all the associated
    /// subscribe/psubscribe/ssubscribe push messages
    mutating func addSubscription(id: Int, continuation: ValkeySubscriptionAsyncStream.Continuation, filter: ValkeySubscriptionFilter) {
        subscriptions.append(
            .init(
                id: id,
                subscription: .init(continuation: continuation, filter: filter, logger: self.logger),
                stateMachine: .init(filter: filter)
            )
        )
    }

    /// Remove subscription
    ///
    /// Called when associated subscribe command fails
    mutating func removeSubscription(id: Int) {
        subscriptions.removeAll { $0.id == id }
    }

    var subscriptions: [Subscription]
    let logger: Logger
}

/// Individual subscription associated with one subscribe command
struct ValkeySubscription {
    var stateMachine: ValkeySubscriptionStateMachine
    let continuation: ValkeySubscriptionAsyncStream.Continuation
    let logger: Logger

    init(continuation: ValkeySubscriptionAsyncStream.Continuation, filter: ValkeySubscriptionFilter, logger: Logger) {
        self.continuation = continuation
        self.stateMachine = .init(filter: filter)
        self.logger = logger
    }

    func sendMessage(_ message: ValkeySubscriptionMessage) {
        continuation.yield(message)
    }

    func sendError(_ error: Error) {
        continuation.finish(throwing: error)
    }

    func finish() {
        continuation.finish()
    }
}
