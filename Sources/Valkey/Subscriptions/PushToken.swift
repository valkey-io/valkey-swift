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

struct PushToken: RESPTokenRepresentable {
    enum TokenType {
        case subscribe(subscriptionCount: Int)
        case unsubscribe(subscriptionCount: Int)
        case message(channel: String, message: String)
        case psubscribe(subscriptionCount: Int)
        case punsubscribe(subscriptionCount: Int)
        case pmessage(channel: String, message: String)
        case ssubscribe(subscriptionCount: Int)
        case sunsubscribe(subscriptionCount: Int)
        case smessage(channel: String, message: String)
    }
    let value: ValkeySubscriptionFilter
    let type: TokenType

    init(from token: RESPToken) throws {
        switch token.value {
        case .push(let respArray):
            var arrayIterator = respArray.makeIterator()
            guard let first = arrayIterator.next() else {
                throw ValkeyClientError(.subscriptionError, message: "Received empty notification")
            }
            let notification = try String(from: first)
            switch notification {
            case "subscribe":
                guard respArray.count == 3 else {
                    throw ValkeyClientError(.subscriptionError, message: "Received invalid subscribe push notification")
                }
                self.value = .channel(try String(from: arrayIterator.next()!))
                self.type = try TokenType.subscribe(subscriptionCount: Int(from: arrayIterator.next()!))

            case "unsubscribe":
                guard respArray.count == 3 else {
                    throw ValkeyClientError(.subscriptionError, message: "Received invalid unsubscribe push notification")
                }
                self.value = .channel(try String(from: arrayIterator.next()!))
                self.type = try TokenType.unsubscribe(subscriptionCount: Int(from: arrayIterator.next()!))

            case "message":
                guard respArray.count == 3 else {
                    throw ValkeyClientError(.subscriptionError, message: "Received invalid message push notification")
                }
                let channel = try String(from: arrayIterator.next()!)
                self.value = .channel(channel)
                self.type = try TokenType.message(channel: channel, message: String(from: arrayIterator.next()!))

            case "psubscribe":
                guard respArray.count == 3 else {
                    throw ValkeyClientError(.subscriptionError, message: "Received invalid psubscribe push notification")
                }
                self.value = .pattern(try String(from: arrayIterator.next()!))
                self.type = try TokenType.psubscribe(subscriptionCount: Int(from: arrayIterator.next()!))

            case "punsubscribe":
                guard respArray.count == 3 else {
                    throw ValkeyClientError(.subscriptionError, message: "Received invalid punsubscribe push notification")
                }
                self.value = .pattern(try String(from: arrayIterator.next()!))
                self.type = try TokenType.punsubscribe(subscriptionCount: Int(from: arrayIterator.next()!))

            case "pmessage":
                guard respArray.count == 4 else {
                    throw ValkeyClientError(.subscriptionError, message: "Received invalid pmessage push notification")
                }
                self.value = .pattern(try String(from: arrayIterator.next()!))
                self.type = try TokenType.pmessage(
                    channel: String(from: arrayIterator.next()!),
                    message: String(from: arrayIterator.next()!)
                )

            case "ssubscribe":
                guard respArray.count == 3 else {
                    throw ValkeyClientError(.subscriptionError, message: "Received invalid ssubscribe push notification")
                }
                self.value = .shardChannel(try String(from: arrayIterator.next()!))
                self.type = try TokenType.ssubscribe(subscriptionCount: Int(from: arrayIterator.next()!))

            case "sunsubscribe":
                guard respArray.count == 3 else {
                    throw ValkeyClientError(.subscriptionError, message: "Received invalid sunsubscribe push notification")
                }
                self.value = .shardChannel(try String(from: arrayIterator.next()!))
                self.type = try TokenType.sunsubscribe(subscriptionCount: Int(from: arrayIterator.next()!))

            case "smessage":
                guard respArray.count == 3 else {
                    throw ValkeyClientError(.subscriptionError, message: "Received invalid smessage push notification")
                }
                let channel = try String(from: arrayIterator.next()!)
                self.value = .shardChannel(channel)
                self.type = try TokenType.smessage(channel: channel, message: String(from: arrayIterator.next()!))

            default:
                throw ValkeyClientError(.subscriptionError, message: "Received unrecognised notification \(notification)")
            }
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
}
