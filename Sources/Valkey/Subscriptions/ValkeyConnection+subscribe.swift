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

import NIOCore

extension ValkeyConnection {
    /// Subscribe to list of channels and run closure with subscription
    ///
    /// When the closure is exited the channels are automatically unsubscribed from. It is
    /// possible to have multiple subscriptions running on the same connection and unsubscribe
    /// commands will only be sent to Valkey when there are no subscriptions active for that
    /// channel
    ///
    /// - Parameters:
    ///   - channels: list of channels to subscribe to
    ///   - process: Closure that is called with subscription async sequence
    /// - Returns: Return value of closure
    @inlinable
    public func subscribe<Value>(
        to channels: String...,
        isolation: isolated (any Actor)? = #isolation,
        process: (ValkeySubscriptionSequence) async throws -> sending Value
    ) async throws -> Value {
        try await self.subscribe(to: channels, process: process)
    }

    @inlinable
    /// Subscribe to list of channels and run closure with subscription
    ///
    /// When the closure is exited the channels are automatically unsubscribed from. It is
    /// possible to have multiple subscriptions running on the same connection and unsubscribe
    /// commands will only be sent to Valkey when there are no subscriptions active for that
    /// channel
    ///
    /// - Parameters:
    ///   - channels: list of channels to subscribe to
    ///   - process: Closure that is called with subscription async sequence
    /// - Returns: Return value of closure
    public func subscribe<Value>(
        to channels: [String],
        isolation: isolated (any Actor)? = #isolation,
        process: (ValkeySubscriptionSequence) async throws -> sending Value
    ) async throws -> Value {
        let command = SUBSCRIBE(channel: channels)
        let (id, stream) = try await subscribe(command: command, filters: channels.map { .channel($0) })
        let value: Value
        do {
            value = try await process(stream)
        } catch {
            _ = try? await unsubscribe(id: id)
            throw error
        }
        _ = try await unsubscribe(id: id)
        return value
    }

    /// Subscribe to list of channel patterns and run closure with subscription
    ///
    /// When the closure is exited the patterns are automatically unsubscribed from. It is
    /// possible to have multiple subscriptions running on the same connection and unsubscribe
    /// commands will only be sent to Valkey when there are no subscriptions active for that
    /// pattern
    ///
    /// - Parameters:
    ///   - channels: list of channels to subscribe to
    ///   - process: Closure that is called with subscription async sequence
    /// - Returns: Return value of closure
    @inlinable
    public func psubscribe<Value>(
        to patterns: String...,
        isolation: isolated (any Actor)? = #isolation,
        process: (ValkeySubscriptionSequence) async throws -> sending Value
    ) async throws -> Value {
        try await self.psubscribe(to: patterns, process: process)
    }

    /// Subscribe to list of pattern matching channels and run closure with subscription
    ///
    /// When the closure is exited the patterns are automatically unsubscribed from. It is
    /// possible to have multiple subscriptions running on the same connection and unsubscribe
    /// commands will only be sent to Valkey when there are no subscriptions active for that
    /// pattern
    ///
    /// - Parameters:
    ///   - channels: list of channels to subscribe to
    ///   - process: Closure that is called with subscription async sequence
    /// - Returns: Return value of closure
    @inlinable
    public func psubscribe<Value>(
        to patterns: [String],
        isolation: isolated (any Actor)? = #isolation,
        process: (ValkeySubscriptionSequence) async throws -> sending Value
    ) async throws -> Value {
        let command = PSUBSCRIBE(pattern: patterns)
        let (id, stream) = try await subscribe(command: command, filters: patterns.map { .pattern($0) })
        let value: Value
        do {
            value = try await process(stream)
        } catch {
            _ = try? await unsubscribe(id: id)
            throw error
        }
        _ = try await unsubscribe(id: id)
        return value
    }

    /// Subscribe to list of channel patterns and run closure with subscription
    ///
    /// When the closure is exited the patterns are automatically unsubscribed from. It is
    /// possible to have multiple subscriptions running on the same connection and unsubscribe
    /// commands will only be sent to Valkey when there are no subscriptions active for that
    /// pattern
    ///
    /// - Parameters:
    ///   - channels: list of channels to subscribe to
    ///   - process: Closure that is called with subscription async sequence
    /// - Returns: Return value of closure
    @inlinable
    public func ssubscribe<Value>(
        to shardchannel: String...,
        isolation: isolated (any Actor)? = #isolation,
        process: (ValkeySubscriptionSequence) async throws -> sending Value
    ) async throws -> Value {
        try await self.ssubscribe(to: shardchannel, process: process)
    }

    /// Subscribe to list of pattern matching channels and run closure with subscription
    ///
    /// When the closure is exited the patterns are automatically unsubscribed from. It is
    /// possible to have multiple subscriptions running on the same connection and unsubscribe
    /// commands will only be sent to Valkey when there are no subscriptions active for that
    /// pattern
    ///
    /// - Parameters:
    ///   - channels: list of channels to subscribe to
    ///   - process: Closure that is called with subscription async sequence
    /// - Returns: Return value of closure
    @inlinable
    public func ssubscribe<Value>(
        to shardchannel: [String],
        isolation: isolated (any Actor)? = #isolation,
        process: (ValkeySubscriptionSequence) async throws -> sending Value
    ) async throws -> Value {
        let command = SSUBSCRIBE(shardchannel: shardchannel)
        let (id, stream) = try await subscribe(command: command, filters: shardchannel.map { .shardChannel($0) })
        let value: Value
        do {
            value = try await process(stream)
        } catch {
            _ = try? await unsubscribe(id: id)
            throw error
        }
        _ = try await unsubscribe(id: id)
        return value
    }

    @usableFromInline
    func subscribe(
        command: some ValkeyCommand,
        filters: [ValkeySubscriptionFilter],
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> (Int, ValkeySubscriptionSequence) {
        let (stream, streamContinuation) = ValkeySubscriptionSequence.makeStream()
        let subscriptionID: Int = try await withCheckedThrowingContinuation { continuation in
            if self.channel.eventLoop.inEventLoop {
                self.channelHandler.value.subscribe(
                    command: command,
                    streamContinuation: streamContinuation,
                    filters: filters,
                    promise: .swift(continuation)
                )
            } else {
                self.channel.eventLoop.execute {
                    self.channelHandler.value.subscribe(
                        command: command,
                        streamContinuation: streamContinuation,
                        filters: filters,
                        promise: .swift(continuation)
                    )
                }
            }
        }
        return (subscriptionID, stream)
    }

    @usableFromInline
    func unsubscribe(
        id: Int,
        isolation: isolated (any Actor)? = #isolation
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            if self.channel.eventLoop.inEventLoop {
                self.channelHandler.value.unsubscribe(id: id, promise: .swift(continuation))
            } else {
                self.channel.eventLoop.execute {
                    self.channelHandler.value.unsubscribe(id: id, promise: .swift(continuation))
                }
            }
        }
    }
}
