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

@usableFromInline
enum ValkeySubscriptionFilter: Equatable, Sendable {
    case channels(Set<String>)
    case patterns(Set<String>)

    func filter(_ value: String) -> Bool {
        switch self {
        case .channels(let channels):
            channels.contains(value)
        case .patterns(let patterns):
            patterns.contains(value)
        }
    }

    func addingChannel(_ channel: String) -> Self {
        switch self {
        case .channels(var channels):
            channels.insert(channel)
            return .channels(channels)
        case .patterns:
            preconditionFailure("Cannot add channel to pattern filter")
        }
    }

    func removingChannel(_ channel: String) -> Self {
        switch self {
        case .channels(var channels):
            channels.remove(channel)
            return .channels(channels)
        case .patterns:
            preconditionFailure("Cannot remove channel from pattern filter")
        }
    }

    func addingPattern(_ channel: String) -> Self {
        switch self {
        case .channels:
            preconditionFailure("Cannot add pattern to channel filter")
        case .patterns(var patterns):
            patterns.insert(channel)
            return .patterns(patterns)
        }
    }

    func removingPattern(_ channel: String) -> Self {
        switch self {
        case .channels:
            preconditionFailure("Cannot remove pattern from channel filter")
        case .patterns(var patterns):
            patterns.remove(channel)
            return .patterns(patterns)
        }
    }

    var isEmpty: Bool {
        switch self {
        case .channels(let channels):
            return channels.isEmpty
        case .patterns(let patterns):
            return patterns.isEmpty
        }
    }
}
