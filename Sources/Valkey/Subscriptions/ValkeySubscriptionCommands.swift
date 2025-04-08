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

struct ValkeySubscriptionCommandStack {
    struct Command {
        enum CommandType {
            case subscribe
            case unsubscribe
            case psubscribe
            case punsubscribe
        }
        let type: CommandType
        var values: [String]

        mutating func process(token: PushToken) throws -> Bool {
            switch (self.type, token.type) {
            case (.subscribe, .subscribe), (.unsubscribe, .unsubscribe), (.psubscribe, .psubscribe), (.punsubscribe, .punsubscribe):
                try self.removeEntry(token.value)
                if self.values.isEmpty {
                    return true
                } else {
                    return false
                }
            case (_, .pmessage), (_, .message):
                return false
            default:
                throw ValkeyClientError(.subscriptionError, message: "Received unexpected push")
            }
        }

        mutating func removeEntry(_ entry: String) throws {
            guard let index = self.values.firstIndex(of: entry) else {
                throw ValkeyClientError(.subscriptionError, message: "Received unexpected push")
            }
            self.values.remove(at: index)
        }
    }
    var commands: Deque<Command>

    mutating func addCommand(_ command: Command) {
        commands.append(command)
    }

    mutating func process(token: PushToken) throws -> Bool {
        if try commands[commands.startIndex].process(token: token) {
            _ = commands.popFirst()
            return true
        } else {
            return false
        }
    }
}
