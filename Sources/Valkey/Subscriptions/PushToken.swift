//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey open source project
//
// Copyright (c) 2025 the swift-valkey project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-valkey project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore

struct PushToken: RESPTokenRepresentable {
    static let subscribeString = ByteBuffer(string: "subscribe")
    static let unsubscribeString = ByteBuffer(string: "unsubscribe")
    static let messageString = ByteBuffer(string: "message")
    static let psubscribeString = ByteBuffer(string: "psubscribe")
    static let punsubscribeString = ByteBuffer(string: "punsubscribe")
    static let pmessageString = ByteBuffer(string: "pmessage")
    static let ssubscribeString = ByteBuffer(string: "ssubscribe")
    static let sunsubscribeString = ByteBuffer(string: "sunsubscribe")
    static let smessageString = ByteBuffer(string: "smessage")

    enum TokenType: CustomStringConvertible {
        case subscribe(subscriptionCount: Int)
        case unsubscribe(subscriptionCount: Int)
        case message(channel: String, message: String)

        var description: String {
            switch self {
            case .subscribe: "subscribe"
            case .unsubscribe: "unsubscribe"
            case .message: "message"
            }
        }
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
            guard case .bulkString(let notification) = first.value else {
                throw ValkeyClientError(.subscriptionError, message: "Invalid notification identifier")
            }
            switch notification {
            case Self.subscribeString:
                guard respArray.count == 3 else {
                    throw ValkeyClientError(.subscriptionError, message: "Received invalid subscribe push notification")
                }
                self.value = .channel(try String(from: arrayIterator.next()!))
                self.type = try TokenType.subscribe(subscriptionCount: Int(from: arrayIterator.next()!))

            case Self.unsubscribeString:
                guard respArray.count == 3 else {
                    throw ValkeyClientError(.subscriptionError, message: "Received invalid unsubscribe push notification")
                }
                self.value = .channel(try String(from: arrayIterator.next()!))
                self.type = try TokenType.unsubscribe(subscriptionCount: Int(from: arrayIterator.next()!))

            case Self.messageString:
                guard respArray.count == 3 else {
                    throw ValkeyClientError(.subscriptionError, message: "Received invalid message push notification")
                }
                let channel = try String(from: arrayIterator.next()!)
                self.value = .channel(channel)
                self.type = try TokenType.message(channel: channel, message: String(from: arrayIterator.next()!))

            case Self.psubscribeString:
                guard respArray.count == 3 else {
                    throw ValkeyClientError(.subscriptionError, message: "Received invalid psubscribe push notification")
                }
                self.value = .pattern(try String(from: arrayIterator.next()!))
                self.type = try TokenType.subscribe(subscriptionCount: Int(from: arrayIterator.next()!))

            case Self.punsubscribeString:
                guard respArray.count == 3 else {
                    throw ValkeyClientError(.subscriptionError, message: "Received invalid punsubscribe push notification")
                }
                self.value = .pattern(try String(from: arrayIterator.next()!))
                self.type = try TokenType.unsubscribe(subscriptionCount: Int(from: arrayIterator.next()!))

            case Self.pmessageString:
                guard respArray.count == 4 else {
                    throw ValkeyClientError(.subscriptionError, message: "Received invalid pmessage push notification")
                }
                self.value = .pattern(try String(from: arrayIterator.next()!))
                self.type = try TokenType.message(
                    channel: String(from: arrayIterator.next()!),
                    message: String(from: arrayIterator.next()!)
                )

            case Self.ssubscribeString:
                guard respArray.count == 3 else {
                    throw ValkeyClientError(.subscriptionError, message: "Received invalid ssubscribe push notification")
                }
                self.value = .shardChannel(try String(from: arrayIterator.next()!))
                self.type = try TokenType.subscribe(subscriptionCount: Int(from: arrayIterator.next()!))

            case Self.sunsubscribeString:
                guard respArray.count == 3 else {
                    throw ValkeyClientError(.subscriptionError, message: "Received invalid sunsubscribe push notification")
                }
                self.value = .shardChannel(try String(from: arrayIterator.next()!))
                self.type = try TokenType.unsubscribe(subscriptionCount: Int(from: arrayIterator.next()!))

            case Self.smessageString:
                guard respArray.count == 3 else {
                    throw ValkeyClientError(.subscriptionError, message: "Received invalid smessage push notification")
                }
                let channel = try String(from: arrayIterator.next()!)
                self.value = .shardChannel(channel)
                self.type = try TokenType.message(channel: channel, message: String(from: arrayIterator.next()!))

            default:
                throw ValkeyClientError(.subscriptionError, message: "Received unrecognised notification \(String(buffer: notification))")
            }
        case .simpleString,
            .bulkString,
            .verbatimString,
            .simpleError,
            .blobError,
            .number,
            .double,
            .boolean,
            .null,
            .bigNumber,
            .array,
            .map,
            .set,
            .attribute:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
}
