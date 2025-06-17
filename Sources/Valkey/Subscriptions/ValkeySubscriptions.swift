//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 Apple Inc. and the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of valkey-swift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Logging
import Synchronization

/// Container for all subscriptions on one connection
@available(valkeySwift 1.0, *)
@usableFromInline
struct ValkeySubscriptions {
    /// invalidation subscription channelAdd commentMore actions
    @usableFromInline
    static let invalidateChannel = "__redis__:invalidate"
    var subscriptionIDMap: [Int: SubscriptionRef]
    private var commandStack: ValkeySubscriptionCommandStack
    private var subscriptionMap: [ValkeySubscriptionFilter: ValkeyChannelStateMachine<SubscriptionRef>]
    let logger: Logger

    static let globalSubscriptionID = Atomic<Int>(0)

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
            pushToken = try PushToken(fromRESP: token)
        } catch {
            // push error to all subscriptions on this channel. We're about to close
            // the channel we should tell them why
            for subscription in self.subscriptionIDMap.values {
                subscription.sendError(error)
            }
            self.subscriptionIDMap = [:]
            throw error
        }

        self.logger.trace("Received PUSH token", metadata: ["subscription": "\(pushToken.value)", "type": "\(pushToken.type)"])

        var returnValue = false
        switch pushToken.type {
        case .subscribe:
            if let _ = try self.commandStack.received(pushToken.value) {
                returnValue = true
            }
            self.subscriptionMap[pushToken.value, default: .init()].added()

        case .unsubscribe:
            if let _ = try self.commandStack.received(pushToken.value) {
                returnValue = true
            }
            switch self.subscriptionMap[pushToken.value]?.closed() {
            case .removeChannel:
                self.subscriptionMap.removeValue(forKey: pushToken.value)
            case .doNothing, .none:
                break
            }

        case .message(let channel, let message):
            switch self.subscriptionMap[pushToken.value]?.receivedMessage() {
            case .forwardMessage(let subscriptions):
                for subscription in subscriptions {
                    subscription.sendMessage(.init(channel: channel, message: message))
                }
            case .doNothing, .none:
                self.logger.trace("Received message for inactive subscription", metadata: ["subscription": "\(pushToken.value)"])
            }

        case .invalidate(let keys):
            switch self.subscriptionMap[pushToken.value]?.receivedMessage() {
            case .forwardMessage(let subscriptions):
                for subscription in subscriptions {
                    for key in keys {
                        subscription.sendMessage(.init(channel: Self.invalidateChannel, message: key.rawValue))
                    }
                }
            case .doNothing, .none:
                self.logger.trace("Received message for inactive subscription \(pushToken.value)")
            }
        }
        return returnValue
    }

    /// Connection is closing lets inform all the subscriptions
    mutating func close(error: any Error) {
        for subscription in subscriptionIDMap.values {
            subscription.sendError(error)
        }
        self.subscriptionIDMap = [:]
    }

    static func getSubscriptionID() -> Int {
        Self.globalSubscriptionID.wrappingAdd(1, ordering: .relaxed).newValue
    }

    enum SubscribeAction {
        case doNothing(Int)
        case subscribe(SubscriptionRef, [ValkeySubscriptionFilter])
    }

    /// Add subscription to channel.
    ///
    /// This subscription is not considered active until is has received all the associated
    /// subscribe/psubscribe/ssubscribe push messages
    mutating func addSubscription(
        continuation: ValkeySubscription.Continuation,
        filters: [ValkeySubscriptionFilter]
    ) -> SubscribeAction {
        let id = Self.getSubscriptionID()
        let subscription = SubscriptionRef(id: id, continuation: continuation, filters: filters, logger: self.logger)
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
            let closeAction = self.subscriptionMap[filter]?.close(subscription: subscription)
            switch closeAction {
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
            case .doNothing, .none:
                break
            }
        }
        self.subscriptionIDMap[id] = nil
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
        guard let subscription = subscriptionIDMap[id] else { return }
        for filter in subscription.filters {
            switch self.subscriptionMap[filter]?.close(subscription: subscription) {
            case .doNothing, .none:
                break
            case .unsubscribe:
                self.subscriptionMap[filter] = nil
            }
        }
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
final class SubscriptionRef: Identifiable {
    let id: Int
    let filters: [ValkeySubscriptionFilter]
    let continuation: ValkeySubscription.Continuation
    let logger: Logger

    init(id: Int, continuation: ValkeySubscription.Continuation, filters: [ValkeySubscriptionFilter], logger: Logger) {
        self.id = id
        self.filters = filters
        self.continuation = continuation
        self.logger = logger
    }

    func sendMessage(_ message: ValkeySubscriptionMessage) {
        self.continuation.yield(message)
    }

    func sendError(_ error: Error) {
        self.continuation.finish(throwing: error)
    }

    func finish() {
        self.continuation.finish()
    }
}
