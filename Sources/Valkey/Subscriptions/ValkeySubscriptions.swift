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
@usableFromInline
struct ValkeySubscriptions {
    var subscriptionIDMap: [Int: ValkeySubscription]
    private var commandStack: ValkeySubscriptionCommandStack
    private var subscriptionMap: [ValkeySubscriptionFilter: ValkeyChannelStateMachine<ValkeySubscription>]
    let logger: Logger

    static let globalSubscriptionId = Atomic<Int>(0)

    init(logger: Logger) {
        self.subscriptionIDMap = [:]
        self.logger = logger
        self.commandStack = .init()
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

        self.logger.trace("Received PUSH token", metadata: ["subscription": "\(pushToken.value)", "type": "\(pushToken.type)"])

        var returnValue = false
        switch pushToken.type {
        case .subscribe:
            if let _ = try commandStack.received(pushToken.value) {
                returnValue = true
            }
            self.subscriptionMap[pushToken.value, default: .init()].added()

        case .unsubscribe:
            if let _ = try commandStack.received(pushToken.value) {
                returnValue = true
            }
            switch self.subscriptionMap[pushToken.value, default: .init()].closed() {
            case .removeChannel:
                self.subscriptionMap.removeValue(forKey: pushToken.value)
            case .doNothing:
                break
            }

        case .message(let channel, let message):
            switch self.subscriptionMap[pushToken.value, default: .init()].receivedMessage() {
            case .forwardMessage(let subscriptions):
                for subscription in subscriptions {
                    subscription.sendMessage(.init(channel: channel, message: message))
                }
            case .doNothing:
                self.logger.trace("Received message for inactive subscription", metadata: ["subscription": "\(pushToken.value)"])
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

    enum SubscribeAction {
        case doNothing(Int)
        case subscribe(ValkeySubscription, [ValkeySubscriptionFilter])
    }

    /// Add subscription to channel.
    ///
    /// This subscription is not considered active until is has received all the associated
    /// subscribe/psubscribe/ssubscribe push messages
    mutating func addSubscription(
        continuation: ValkeySubscriptionSequence.Continuation,
        filters: [ValkeySubscriptionFilter]
    ) -> SubscribeAction {
        let id = Self.getSubscriptionID()
        let subscription = ValkeySubscription(id: id, continuation: continuation, filters: filters, logger: self.logger)
        subscriptionIDMap[id] = subscription
        var action = SubscribeAction.doNothing(id)
        for filter in filters {
            switch subscriptionMap[filter, default: .init()].add(subscription: subscription) {
            case .subscribe:
                switch action {
                case .doNothing:
                    action = .subscribe(subscription, [filter])
                case .subscribe(let subscription, var filters):
                    filters.append(filter)
                    action = .subscribe(subscription, filters)
                }
            case .doNothing:
                break
            }
        }
        return action
    }

    enum UnsubscribeAction {
        case doNothing
        case unsubscribe([String])
        case punsubscribe([String])
        case sunsubscribe([String])
    }

    /// Add unsubscribe
    ///
    /// Remove subscription from all the message filters. If a message filter ends up with no
    /// subscriptions then add to list of filters to unsubscribe from
    mutating func unsubscribe(id: Int) -> UnsubscribeAction {
        var action: UnsubscribeAction = .doNothing
        guard let subscription = subscriptionIDMap[id] else { return .doNothing }
        for filter in subscription.filters {
            switch self.subscriptionMap[filter, default: .init()].close(subscription: subscription) {
            case .unsubscribe:
                switch (filter, action) {
                case (.channel(let string), .doNothing):
                    action = .unsubscribe([string])
                case (.pattern(let string), .doNothing):
                    action = .punsubscribe([string])
                case (.shardChannel(let string), .doNothing):
                    action = .sunsubscribe([string])
                case (.channel(let string), .unsubscribe(var channels)):
                    channels.append(string)
                    action = .unsubscribe(channels)
                case (.pattern(let string), .punsubscribe(var patterns)):
                    patterns.append(string)
                    action = .punsubscribe(patterns)
                case (.shardChannel(let string), .sunsubscribe(var patterns)):
                    patterns.append(string)
                    action = .sunsubscribe(patterns)
                default:
                    preconditionFailure("Cannot mix channels and patterns")
                }
            case .doNothing:
                break
            }
        }
        subscriptionIDMap[id] = nil
        return action
    }

    mutating func pushCommand(filters: [ValkeySubscriptionFilter]) {
        commandStack.pushCommand(filters)
    }

    mutating func removeUnhandledCommand() {
        _ = commandStack.popCommand()
    }

    /// Remove subscription
    ///
    /// Called when associated subscribe command fails
    mutating func removeSubscription(id: Int) {
        subscriptionIDMap[id] = nil
    }

    /// Used in tests
    var isEmpty: Bool {
        self.subscriptionIDMap.isEmpty
            || self.subscriptionMap.isEmpty
            || self.commandStack.commands.isEmpty
    }
}

/// Individual subscription associated with one subscribe command
final class ValkeySubscription: Identifiable {
    let id: Int
    let filters: [ValkeySubscriptionFilter]
    let continuation: ValkeySubscriptionSequence.Continuation
    let logger: Logger

    init(id: Int, continuation: ValkeySubscriptionSequence.Continuation, filters: [ValkeySubscriptionFilter], logger: Logger) {
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
