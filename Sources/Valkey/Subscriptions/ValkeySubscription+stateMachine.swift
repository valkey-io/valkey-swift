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

/// State machine for one subscription.
struct ValkeySubscriptionStateMachine {
    enum State {
        case initialized
        case starting(filter: ValkeySubscriptionFilter)
        case listening
        case failed(Error)
    }
    var state: State
    var filter: ValkeySubscriptionFilter

    init(filter: ValkeySubscriptionFilter) {
        self.state = .initialized
        self.filter = filter
    }

    enum ReceivedTokenAction {
        case sendMessage(ValkeySubscriptionMessage)
        case deleteSubscriptionAndReturnOk
        case returnOk
        case doNothing
        case fail(Error)
    }

    /// On receiving a push notification
    mutating func receivedToken(_ token: PushToken) -> ReceivedTokenAction {
        // does this notification affect this subscription
        guard filter.filter(token.value) else { return .doNothing }
        switch token.type {
        case .subscribe:
            return receivedSubscribe(channel: token.value)
        case .unsubscribe:
            return receivedUnsubscribe(channel: token.value)
        case .message(let message):
            return receivedMessage(channel: token.value, message: message)
        case .psubscribe:
            return receivedPatternSubscribe(channel: token.value)
        case .punsubscribe:
            return receivedPatternUnsubscribe(channel: token.value)
        case .pmessage(let channel, let message):
            return receivedMessage(channel: channel, message: message)
        }
    }

    mutating func receivedSubscribe(channel: String) -> ReceivedTokenAction {
        switch state {
        case .initialized:
            let filter = ValkeySubscriptionFilter.channels([channel])
            if self.filter == filter {
                self.state = .listening
                return .returnOk
            } else {
                self.state = .starting(filter: filter)
                return .doNothing
            }

        case .starting(let filter):
            let filter = filter.addingChannel(channel)
            if self.filter == filter {
                self.state = .listening
                return .returnOk
            } else {
                self.state = .starting(filter: filter)
                return .doNothing
            }

        case .listening:
            return .doNothing

        case .failed(let error):
            return .fail(error)
        }
    }

    mutating func receivedUnsubscribe(channel: String) -> ReceivedTokenAction {
        switch state {
        case .initialized, .starting:
            let error = ValkeyClientError(.subscriptionError, message: "Received unsubscribe before in listening state")
            self.state = .failed(error)
            return .fail(error)
        case .listening:
            self.filter = self.filter.removingChannel(channel)
            if self.filter.isEmpty {
                return .deleteSubscriptionAndReturnOk
            } else {
                return .returnOk
            }
        case .failed(let error):
            return .fail(error)
        }
    }

    mutating func receivedMessage(channel: String, message: String) -> ReceivedTokenAction {
        switch state {
        case .initialized, .starting:
            // it is possible another subscription is already running on this connection so it
            // is perfectly valid to receive messages before we receive the subscribe push notification
            return .doNothing
        case .listening:
            return .sendMessage(.init(channel: channel, message: message))
        case .failed(let error):
            return .fail(error)
        }
    }

    mutating func receivedPatternSubscribe(channel: String) -> ReceivedTokenAction {
        switch state {
        case .initialized:
            let filter = ValkeySubscriptionFilter.patterns([channel])
            if self.filter == filter {
                self.state = .listening
                return .returnOk
            } else {
                self.state = .starting(filter: filter)
                return .doNothing
            }

        case .starting(let filter):
            let filter = filter.addingPattern(channel)
            if self.filter == filter {
                self.state = .listening
                return .returnOk
            } else {
                self.state = .starting(filter: filter)
                return .doNothing
            }

        case .listening:
            return .doNothing

        case .failed(let error):
            return .fail(error)
        }
    }

    mutating func receivedPatternUnsubscribe(channel: String) -> ReceivedTokenAction {
        switch state {
        case .initialized, .starting:
            let error = ValkeyClientError(.subscriptionError, message: "Received unsubscribe before in listening state")
            self.state = .failed(error)
            return .fail(error)
        case .listening:
            self.filter = self.filter.removingPattern(channel)
            if self.filter.isEmpty {
                return .deleteSubscriptionAndReturnOk
            } else {
                return .returnOk
            }
        case .failed(let error):
            return .fail(error)
        }
    }
}
