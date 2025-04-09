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
    var subscriptionIDMap: [Int: ValkeySubscription]
    var subscribeCommandStack: ValkeySubscriptionCommandStack<ValkeySubscription>
    var unsubscribeCommandStack: ValkeySubscriptionCommandStack<[ValkeySubscriptionFilter]>
    private var subscriptionMap: [ValkeySubscriptionFilter: [ValkeySubscription]]
    let logger: Logger

    static let globalSubscriptionId = Atomic<Int>(0)

    init(logger: Logger) {
        self.subscriptionIDMap = [:]
        self.logger = logger
        self.subscribeCommandStack = .init()
        self.unsubscribeCommandStack = .init()
        self.subscriptionMap = [:]
    }

    /// We received a push notification
    mutating func notify(_ token: RESPToken) throws -> Bool {
        let pushToken: PushToken
        do {
            pushToken = try PushToken(from: token)
        } catch {
            // push error to all subscriptions on this channel. We're about to close
            // the channel we should tell them why
            for subscription in subscriptionIDMap.values {
                subscription.sendError(error)
            }
            subscriptionIDMap = [:]
            throw error
        }

        self.logger.trace("\(pushToken)")

        var returnValue = false
        switch pushToken.type {
        case .subscribe, .psubscribe:
            if let subscription = try subscribeCommandStack.received(pushToken.value) {
                for filter in subscription.filters {
                    if self.subscriptionMap[filter] == nil {
                        self.subscriptionMap[filter] = [subscription]
                    } else {
                        self.subscriptionMap[filter]?.append(subscription)
                    }
                }
                returnValue = true
            }
        case .unsubscribe, .punsubscribe:
            if let unsubscribedFilters = try unsubscribeCommandStack.received(pushToken.value) {
                returnValue = true

                for filter in unsubscribedFilters {
                    precondition(self.subscriptionMap[filter]?.count == 0, "Filter should have no subscriptions attached to it")
                    self.subscriptionMap.removeValue(forKey: filter)
                }
            }
        case .message(let channel, let message), .pmessage(let channel, let message):
            guard let subscriptions = subscriptionMap[pushToken.value] else {
                self.logger.trace("Received message for unrecognised subscription")
                return false
            }
            for subscription in subscriptions {
                subscription.sendMessage(.init(channel: channel, message: message))
            }
        }
        return returnValue
    }

    /// Connection is closing lets inform all the subscriptions
    mutating func close() {
        for subscription in subscriptionIDMap.values {
            subscription.sendError(ValkeyClientError(.connectionClosed))
        }
        self.subscriptionIDMap = [:]
    }

    static func getSubscriptionID() -> Int {
        Self.globalSubscriptionId.wrappingAdd(1, ordering: .relaxed).newValue
    }

    /// Add subscription to channel.
    ///
    /// This subscription is not considered active until is has received all the associated
    /// subscribe/psubscribe/ssubscribe push messages
    mutating func addSubscription(continuation: ValkeySubscriptionAsyncStream.Continuation, filters: [ValkeySubscriptionFilter]) -> ValkeySubscription
    {
        let id = Self.getSubscriptionID()
        let subscription = ValkeySubscription(id: id, continuation: continuation, filters: filters, logger: self.logger)
        subscriptionIDMap[id] = subscription
        return subscription
    }

    enum UnsubscribeAction {
        case doNothing
        case unsubscribe([String])
        case punsubscribe([String])
    }

    /// Add unsubscribe
    ///
    /// This subscription is not considered active until is has received all the associated
    /// subscribe/psubscribe/ssubscribe push messages
    mutating func unsubscribe(id: Int) -> UnsubscribeAction {
        var action: UnsubscribeAction = .doNothing
        guard let subscription = subscriptionIDMap[id] else { return .doNothing }
        for filter in subscription.filters {
            self.subscriptionMap[filter]?.removeAll { $0.id == id }
            if self.subscriptionMap[filter]?.count == 0 {
                switch (filter, action) {
                case (.channel(let string), .doNothing):
                    action = .unsubscribe([string])
                case (.pattern(let string), .doNothing):
                    action = .punsubscribe([string])
                case (.channel(let string), .unsubscribe(var channels)):
                    channels.append(string)
                    action = .unsubscribe(channels)
                case (.pattern(let string), .punsubscribe(var patterns)):
                    patterns.append(string)
                    action = .punsubscribe(patterns)
                default:
                    preconditionFailure("Cannot mix channels and patterns")
                }
            }
        }
        subscriptionIDMap[id] = nil
        return action
    }

    mutating func pushUnsubscribeCommand(filters: [ValkeySubscriptionFilter]) {
        unsubscribeCommandStack.pushCommand(filters, value: filters)
    }

    mutating func pushSubscribeCommand(filters: [ValkeySubscriptionFilter], subscription: ValkeySubscription) {
        subscribeCommandStack.pushCommand(filters, value: subscription)
    }

    /// Remove subscription
    ///
    /// Called when associated subscribe command fails
    mutating func removeSubscription(id: Int) {
        subscriptionIDMap[id] = nil
    }
}

/// Individual subscription associated with one subscribe command
final class ValkeySubscription {
    let id: Int
    let filters: [ValkeySubscriptionFilter]
    let continuation: ValkeySubscriptionAsyncStream.Continuation
    let logger: Logger

    init(id: Int, continuation: ValkeySubscriptionAsyncStream.Continuation, filters: [ValkeySubscriptionFilter], logger: Logger) {
        self.id = id
        self.filters = filters
        self.continuation = continuation
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
