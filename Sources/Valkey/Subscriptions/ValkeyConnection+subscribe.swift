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

public struct ValkeySubscriptionMessage: Sendable, Equatable {
    public let channel: String
    public let message: String

    package init(channel: String, message: String) {
        self.channel = channel
        self.message = message
    }
}

extension ValkeyConnection {
    public func subscribe<Value>(
        to channels: String...,
        process: (ValkeySubscriptionAsyncStream) async throws -> Value
    ) async throws -> Value {
        try await self.subscribe(to: channels, process: process)
    }

    public func subscribe<Value>(to channels: [String], process: (ValkeySubscriptionAsyncStream) async throws -> Value) async throws -> Value {
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

    public func psubscribe<Value>(
        to patterns: String...,
        process: (ValkeySubscriptionAsyncStream) async throws -> Value
    ) async throws -> Value {
        try await self.psubscribe(to: patterns, process: process)
    }

    public func psubscribe<Value>(to patterns: [String], process: (ValkeySubscriptionAsyncStream) async throws -> Value) async throws -> Value {
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

    func subscribe(command: some RESPCommand, filters: [ValkeySubscriptionFilter]) async throws -> (Int, ValkeySubscriptionAsyncStream) {
        let (stream, streamContinuation) = ValkeySubscriptionAsyncStream.makeStream()
        let subscriptionID: Int
        if self.channel.eventLoop.inEventLoop {
            subscriptionID = self.channelHandler.value.addSubscription(
                continuation: streamContinuation,
                filters: filters
            )
            _ = try await self.channelHandler.value._send(command: command)
                .flatMapErrorThrowing { error in
                    self.channelHandler.value.subscriptions.removeSubscription(id: subscriptionID)
                    throw error
                }
                .get()
        } else {
            subscriptionID = try await self.channel.eventLoop.flatSubmit {
                let subscriptionID = self.channelHandler.value.addSubscription(
                    continuation: streamContinuation,
                    filters: filters
                )
                return self.channelHandler.value._send(command: command)
                    .flatMapErrorThrowing { error in
                        self.channelHandler.value.subscriptions.removeSubscription(id: subscriptionID)
                        throw error
                    }
                    .map { _ in subscriptionID }
            }.get()
        }
        return (subscriptionID, stream)
    }

    @usableFromInline
    func unsubscribe(id: Int) async throws {
        if self.channel.eventLoop.inEventLoop {
            try await self.channelHandler.value.unsubscribe(id: id).get()
        } else {
            _ = try await self.channel.eventLoop.flatSubmit {
                self.channelHandler.value.unsubscribe(id: id)
            }.get()
        }
        return
    }
}
