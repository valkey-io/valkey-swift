//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of valkey-swift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// This file is autogenerated by ValkeyCommandsBuilder

import NIOCore

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A container for Pub/Sub commands.
@_documentation(visibility: internal)
public enum PUBSUB {
    /// Returns the active channels.
    @_documentation(visibility: internal)
    public struct CHANNELS: ValkeyCommand {
        public typealias Response = RESPToken.Array

        public var pattern: String?

        @inlinable public init(pattern: String? = nil) {
            self.pattern = pattern
        }

        @inlinable public func encode(into commandEncoder: inout ValkeyCommandEncoder) {
            commandEncoder.encodeArray("PUBSUB", "CHANNELS", pattern)
        }
    }

    /// Returns helpful text about the different subcommands.
    @_documentation(visibility: internal)
    public struct HELP: ValkeyCommand {
        public typealias Response = RESPToken.Array

        @inlinable public init() {
        }

        @inlinable public func encode(into commandEncoder: inout ValkeyCommandEncoder) {
            commandEncoder.encodeArray("PUBSUB", "HELP")
        }
    }

    /// Returns a count of unique pattern subscriptions.
    @_documentation(visibility: internal)
    public struct NUMPAT: ValkeyCommand {
        public typealias Response = Int

        @inlinable public init() {
        }

        @inlinable public func encode(into commandEncoder: inout ValkeyCommandEncoder) {
            commandEncoder.encodeArray("PUBSUB", "NUMPAT")
        }
    }

    /// Returns a count of subscribers to channels.
    @_documentation(visibility: internal)
    public struct NUMSUB: ValkeyCommand {
        public typealias Response = RESPToken.Array

        public var channels: [String]

        @inlinable public init(channels: [String] = []) {
            self.channels = channels
        }

        @inlinable public func encode(into commandEncoder: inout ValkeyCommandEncoder) {
            commandEncoder.encodeArray("PUBSUB", "NUMSUB", channels)
        }
    }

    /// Returns the active shard channels.
    @_documentation(visibility: internal)
    public struct SHARDCHANNELS: ValkeyCommand {
        public typealias Response = RESPToken.Array

        public var pattern: String?

        @inlinable public init(pattern: String? = nil) {
            self.pattern = pattern
        }

        @inlinable public func encode(into commandEncoder: inout ValkeyCommandEncoder) {
            commandEncoder.encodeArray("PUBSUB", "SHARDCHANNELS", pattern)
        }
    }

    /// Returns the count of subscribers of shard channels.
    @_documentation(visibility: internal)
    public struct SHARDNUMSUB: ValkeyCommand {
        public typealias Response = RESPToken.Array

        public var shardchannels: [String]

        @inlinable public init(shardchannels: [String] = []) {
            self.shardchannels = shardchannels
        }

        @inlinable public func encode(into commandEncoder: inout ValkeyCommandEncoder) {
            commandEncoder.encodeArray("PUBSUB", "SHARDNUMSUB", shardchannels)
        }
    }

}

/// Listens for messages published to channels that match one or more patterns.
@_documentation(visibility: internal)
public struct PSUBSCRIBE: ValkeyCommand {
    public var patterns: [String]

    @inlinable public init(patterns: [String]) {
        self.patterns = patterns
    }

    @inlinable public func encode(into commandEncoder: inout ValkeyCommandEncoder) {
        commandEncoder.encodeArray("PSUBSCRIBE", patterns)
    }
}

/// Posts a message to a channel.
@_documentation(visibility: internal)
public struct PUBLISH<Channel: RESPStringRenderable, Message: RESPStringRenderable>: ValkeyCommand {
    public typealias Response = Int

    public var channel: Channel
    public var message: Message

    @inlinable public init(channel: Channel, message: Message) {
        self.channel = channel
        self.message = message
    }

    @inlinable public func encode(into commandEncoder: inout ValkeyCommandEncoder) {
        commandEncoder.encodeArray("PUBLISH", RESPBulkString(channel), RESPBulkString(message))
    }
}

/// Stops listening to messages published to channels that match one or more patterns.
@_documentation(visibility: internal)
public struct PUNSUBSCRIBE: ValkeyCommand {
    public var patterns: [String]

    @inlinable public init(patterns: [String] = []) {
        self.patterns = patterns
    }

    @inlinable public func encode(into commandEncoder: inout ValkeyCommandEncoder) {
        commandEncoder.encodeArray("PUNSUBSCRIBE", patterns)
    }
}

/// Post a message to a shard channel
@_documentation(visibility: internal)
public struct SPUBLISH<Shardchannel: RESPStringRenderable, Message: RESPStringRenderable>: ValkeyCommand {
    public typealias Response = Int

    public var shardchannel: Shardchannel
    public var message: Message

    @inlinable public init(shardchannel: Shardchannel, message: Message) {
        self.shardchannel = shardchannel
        self.message = message
    }

    @inlinable public func encode(into commandEncoder: inout ValkeyCommandEncoder) {
        commandEncoder.encodeArray("SPUBLISH", RESPBulkString(shardchannel), RESPBulkString(message))
    }
}

/// Listens for messages published to shard channels.
@_documentation(visibility: internal)
public struct SSUBSCRIBE<Shardchannel: RESPStringRenderable>: ValkeyCommand {
    public var shardchannels: [Shardchannel]

    @inlinable public init(shardchannels: [Shardchannel]) {
        self.shardchannels = shardchannels
    }

    @inlinable public func encode(into commandEncoder: inout ValkeyCommandEncoder) {
        commandEncoder.encodeArray("SSUBSCRIBE", shardchannels.map { RESPBulkString($0) })
    }
}

/// Listens for messages published to channels.
@_documentation(visibility: internal)
public struct SUBSCRIBE<Channel: RESPStringRenderable>: ValkeyCommand {
    public var channels: [Channel]

    @inlinable public init(channels: [Channel]) {
        self.channels = channels
    }

    @inlinable public func encode(into commandEncoder: inout ValkeyCommandEncoder) {
        commandEncoder.encodeArray("SUBSCRIBE", channels.map { RESPBulkString($0) })
    }
}

/// Stops listening to messages posted to shard channels.
@_documentation(visibility: internal)
public struct SUNSUBSCRIBE: ValkeyCommand {
    public var shardchannels: [String]

    @inlinable public init(shardchannels: [String] = []) {
        self.shardchannels = shardchannels
    }

    @inlinable public func encode(into commandEncoder: inout ValkeyCommandEncoder) {
        commandEncoder.encodeArray("SUNSUBSCRIBE", shardchannels)
    }
}

/// Stops listening to messages posted to channels.
@_documentation(visibility: internal)
public struct UNSUBSCRIBE: ValkeyCommand {
    public var channels: [String]

    @inlinable public init(channels: [String] = []) {
        self.channels = channels
    }

    @inlinable public func encode(into commandEncoder: inout ValkeyCommandEncoder) {
        commandEncoder.encodeArray("UNSUBSCRIBE", channels)
    }
}

extension ValkeyClientProtocol {
    /// Posts a message to a channel.
    ///
    /// - Documentation: [PUBLISH](https://valkey.io/commands/publish)
    /// - Available: 2.0.0
    /// - Complexity: O(N+M) where N is the number of clients subscribed to the receiving channel and M is the total number of subscribed patterns (by any client).
    /// - Response: [Integer]: The number of clients that received the message. Note that in a Cluster, only clients that are connected to the same node as the publishing client are included in the count.
    @inlinable
    @discardableResult
    public func publish<Channel: RESPStringRenderable, Message: RESPStringRenderable>(channel: Channel, message: Message) async throws -> Int {
        try await execute(PUBLISH(channel: channel, message: message))
    }

    /// Returns the active channels.
    ///
    /// - Documentation: [PUBSUB CHANNELS](https://valkey.io/commands/pubsub-channels)
    /// - Available: 2.8.0
    /// - Complexity: O(N) where N is the number of active channels, and assuming constant time pattern matching (relatively short channels and patterns)
    /// - Response: [Array]: A list of active channels, optionally matching the specified pattern.
    @inlinable
    @discardableResult
    public func pubsubChannels(pattern: String? = nil) async throws -> RESPToken.Array {
        try await execute(PUBSUB.CHANNELS(pattern: pattern))
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [PUBSUB HELP](https://valkey.io/commands/pubsub-help)
    /// - Available: 6.2.0
    /// - Complexity: O(1)
    /// - Response: [Array]: Helpful text about subcommands.
    @inlinable
    @discardableResult
    public func pubsubHelp() async throws -> RESPToken.Array {
        try await execute(PUBSUB.HELP())
    }

    /// Returns a count of unique pattern subscriptions.
    ///
    /// - Documentation: [PUBSUB NUMPAT](https://valkey.io/commands/pubsub-numpat)
    /// - Available: 2.8.0
    /// - Complexity: O(1)
    /// - Response: [Integer]: The number of patterns all the clients are subscribed to.
    @inlinable
    @discardableResult
    public func pubsubNumpat() async throws -> Int {
        try await execute(PUBSUB.NUMPAT())
    }

    /// Returns a count of subscribers to channels.
    ///
    /// - Documentation: [PUBSUB NUMSUB](https://valkey.io/commands/pubsub-numsub)
    /// - Available: 2.8.0
    /// - Complexity: O(N) for the NUMSUB subcommand, where N is the number of requested channels
    /// - Response: [Array]: The number of subscribers per channel, each even element (including 0th) is channel name, each odd element is the number of subscribers.
    @inlinable
    @discardableResult
    public func pubsubNumsub(channels: [String] = []) async throws -> RESPToken.Array {
        try await execute(PUBSUB.NUMSUB(channels: channels))
    }

    /// Returns the active shard channels.
    ///
    /// - Documentation: [PUBSUB SHARDCHANNELS](https://valkey.io/commands/pubsub-shardchannels)
    /// - Available: 7.0.0
    /// - Complexity: O(N) where N is the number of active shard channels, and assuming constant time pattern matching (relatively short shard channels).
    /// - Response: [Array]: A list of active channels, optionally matching the specified pattern.
    @inlinable
    @discardableResult
    public func pubsubShardchannels(pattern: String? = nil) async throws -> RESPToken.Array {
        try await execute(PUBSUB.SHARDCHANNELS(pattern: pattern))
    }

    /// Returns the count of subscribers of shard channels.
    ///
    /// - Documentation: [PUBSUB SHARDNUMSUB](https://valkey.io/commands/pubsub-shardnumsub)
    /// - Available: 7.0.0
    /// - Complexity: O(N) for the SHARDNUMSUB subcommand, where N is the number of requested shard channels
    /// - Response: [Array]: The number of subscribers per shard channel, each even element (including 0th) is channel name, each odd element is the number of subscribers.
    @inlinable
    @discardableResult
    public func pubsubShardnumsub(shardchannels: [String] = []) async throws -> RESPToken.Array {
        try await execute(PUBSUB.SHARDNUMSUB(shardchannels: shardchannels))
    }

    /// Post a message to a shard channel
    ///
    /// - Documentation: [SPUBLISH](https://valkey.io/commands/spublish)
    /// - Available: 7.0.0
    /// - Complexity: O(N) where N is the number of clients subscribed to the receiving shard channel.
    /// - Response: [Integer]: The number of clients that received the message. Note that in a Cluster, only clients that are connected to the same node as the publishing client are included in the count.
    @inlinable
    @discardableResult
    public func spublish<Shardchannel: RESPStringRenderable, Message: RESPStringRenderable>(
        shardchannel: Shardchannel,
        message: Message
    ) async throws -> Int {
        try await execute(SPUBLISH(shardchannel: shardchannel, message: message))
    }

}
