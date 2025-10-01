//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
/// Protocol for command that initiates a subscription
public protocol ValkeySubscribeCommand: ValkeyCommand {
    /// Array of subscription filters
    var filters: [ValkeySubscriptionFilter] { get }
}

extension SUBSCRIBE: ValkeySubscribeCommand {
    /// Channels as an array of subscription filters
    public var filters: [ValkeySubscriptionFilter] { self.channels.map { .channel($0) } }
}

extension PSUBSCRIBE: ValkeySubscribeCommand {
    /// Patterns as an array of subscription filters
    public var filters: [ValkeySubscriptionFilter] { self.patterns.map { .pattern($0) } }
}

extension SSUBSCRIBE: ValkeySubscribeCommand {
    /// Shard channels as an array of subscription filters
    public var filters: [ValkeySubscriptionFilter] { self.shardchannels.map { .shardChannel($0) } }
}
