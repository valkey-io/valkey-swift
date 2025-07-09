//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// State machine for a single channel/pattern subscription
struct ValkeyChannelStateMachine<Value: Identifiable> where Value: AnyObject {
    enum State {
        case uninitialized
        case opening([Value])
        case active([Value])
        case closing
        case closed
    }
    var state: State

    init() {
        self.state = .uninitialized
    }

    enum AddAction {
        case doNothing
        case subscribe
    }
    // Add subscription to channel
    mutating func add(subscription: Value) -> AddAction {
        switch state {
        case .uninitialized:
            self.state = .opening([subscription])
            return .subscribe
        case .opening(var subscriptions):
            subscriptions.append(subscription)
            self.state = .opening(subscriptions)
            return .doNothing
        case .active(var subscriptions):
            subscriptions.append(subscription)
            self.state = .active(subscriptions)
            return .doNothing
        case .closing:
            self.state = .opening([subscription])
            return .subscribe
        case .closed:
            preconditionFailure("Closed channels should not be interacted with")
        }
    }

    /// Channel has been subscribed to
    mutating func added() {
        switch state {
        case .uninitialized, .closed:
            preconditionFailure("Inactive channels should not be interacted with")
        case .opening(let subscriptions):
            self.state = .active(subscriptions)
        case .active:
            break
        case .closing:
            preconditionFailure("Cannot add subscription to closing or closed channel")
        }
    }

    enum ReceivedMessageAction {
        case forwardMessage([Value])
        case doNothing
    }
    /// We received a message should we pass it on
    func receivedMessage() -> ReceivedMessageAction {
        switch state {
        case .active(let subscriptions):
            return .forwardMessage(subscriptions)
        case .uninitialized, .opening, .closing, .closed:
            return .doNothing
        }
    }

    enum CloseAction {
        case doNothing
        case unsubscribe
    }
    /// Subscription is being removed from Channel
    mutating func close(subscription: Value) -> CloseAction {
        switch self.state {
        case .uninitialized:
            self.state = .closing
            return .doNothing
        case .opening(var subscriptions):
            if subscriptions.count == 1 {
                precondition(subscriptions[0].id == subscription.id, "Cannot be closing a subscription without adding it")
                self.state = .closing
                return .unsubscribe
            } else {
                guard let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) else {
                    preconditionFailure("Cannot have added a subscription without adding it")
                }
                subscriptions.remove(at: index)
                self.state = .opening(subscriptions)
                return .doNothing
            }
        case .active(var subscriptions):
            if subscriptions.count == 1 {
                precondition(subscriptions[0].id == subscription.id, "Cannot be closing a subscription without adding it")
                self.state = .closing
                return .unsubscribe
            } else {
                guard let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) else {
                    preconditionFailure("Cannot have added a subscription without adding it")
                }
                subscriptions.remove(at: index)
                self.state = .active(subscriptions)
                return .doNothing
            }
        case .closing, .closed:
            preconditionFailure("Removing a subscription from a closing channel is not allowed")
        }
    }

    enum ClosedAction {
        case doNothing
        case removeChannel
    }
    /// We got the unsubscribe push notification
    mutating func closed() -> ClosedAction {
        switch self.state {
        case .uninitialized, .closed:
            preconditionFailure("Inactive channels should not be interacted with")
        case .opening, .active:
            // if we are opening then the channel was subscribed to again after the unsubscribe was initiated
            return .doNothing
        case .closing:
            return .removeChannel
        }
    }
}
