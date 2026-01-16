//
// This source file is part of the valkey-swift project
// Copyright (c) 2025-2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore

@available(valkeySwift 1.0, *)
struct PushToken: RESPTokenDecodable {
    static let subscribeString = ByteBuffer(string: "subscribe")
    static let unsubscribeString = ByteBuffer(string: "unsubscribe")
    static let messageString = ByteBuffer(string: "message")
    static let psubscribeString = ByteBuffer(string: "psubscribe")
    static let punsubscribeString = ByteBuffer(string: "punsubscribe")
    static let pmessageString = ByteBuffer(string: "pmessage")
    static let ssubscribeString = ByteBuffer(string: "ssubscribe")
    static let sunsubscribeString = ByteBuffer(string: "sunsubscribe")
    static let smessageString = ByteBuffer(string: "smessage")
    static let invalidateString = ByteBuffer(string: "invalidate")

    enum TokenType: CustomStringConvertible {
        case subscribe(subscriptionCount: Int)
        case unsubscribe(subscriptionCount: Int)
        case message(channel: String, message: ByteBuffer)
        case invalidate(keys: [ValkeyKey])

        var description: String {
            switch self {
            case .subscribe: "subscribe"
            case .unsubscribe: "unsubscribe"
            case .message: "message"
            case .invalidate: "invalidate"
            }
        }
    }
    let value: ValkeySubscriptionFilter
    let type: TokenType

    init(_ token: RESPToken) throws(RESPDecodeError) {
        switch token.value {
        case .push(let respArray):
            var arrayIterator = respArray.makeIterator()
            guard let first = arrayIterator.next() else {
                throw RESPDecodeError.invalidArraySize(token, minExpectedSize: 1)
            }
            guard case .bulkString(let notification) = first.value else {
                throw RESPDecodeError.tokenMismatch(expected: [.bulkString], token: first)
            }
            switch notification {
            case Self.subscribeString:
                guard respArray.count == 3 else {
                    throw RESPDecodeError.invalidArraySize(token, expectedSize: 3)
                }
                self.value = .channel(try String(arrayIterator.next()!))
                self.type = try TokenType.subscribe(subscriptionCount: Int(arrayIterator.next()!))

            case Self.unsubscribeString:
                guard respArray.count == 3 else {
                    throw RESPDecodeError.invalidArraySize(token, expectedSize: 3)
                }
                self.value = .channel(try String(arrayIterator.next()!))
                self.type = try TokenType.unsubscribe(subscriptionCount: Int(arrayIterator.next()!))

            case Self.messageString:
                guard respArray.count == 3 else {
                    throw RESPDecodeError.invalidArraySize(token, expectedSize: 3)
                }
                let channel = try String(arrayIterator.next()!)
                self.value = .channel(channel)
                self.type = try TokenType.message(channel: channel, message: ByteBuffer(arrayIterator.next()!))

            case Self.psubscribeString:
                guard respArray.count == 3 else {
                    throw RESPDecodeError.invalidArraySize(token, expectedSize: 3)
                }
                self.value = .pattern(try String(arrayIterator.next()!))
                self.type = try TokenType.subscribe(subscriptionCount: Int(arrayIterator.next()!))

            case Self.punsubscribeString:
                guard respArray.count == 3 else {
                    throw RESPDecodeError.invalidArraySize(token, expectedSize: 3)
                }
                self.value = .pattern(try String(arrayIterator.next()!))
                self.type = try TokenType.unsubscribe(subscriptionCount: Int(arrayIterator.next()!))

            case Self.pmessageString:
                guard respArray.count == 4 else {
                    throw RESPDecodeError.invalidArraySize(token, expectedSize: 4)
                }
                self.value = .pattern(try String(arrayIterator.next()!))
                self.type = try TokenType.message(
                    channel: String(arrayIterator.next()!),
                    message: ByteBuffer(arrayIterator.next()!)
                )

            case Self.ssubscribeString:
                guard respArray.count == 3 else {
                    throw RESPDecodeError.invalidArraySize(respArray, expectedSize: 3)
                }
                self.value = .shardChannel(try String(arrayIterator.next()!))
                self.type = try TokenType.subscribe(subscriptionCount: Int(arrayIterator.next()!))

            case Self.sunsubscribeString:
                guard respArray.count == 3 else {
                    throw RESPDecodeError.invalidArraySize(respArray, expectedSize: 3)
                }
                self.value = .shardChannel(try String(arrayIterator.next()!))
                self.type = try TokenType.unsubscribe(subscriptionCount: Int(arrayIterator.next()!))

            case Self.smessageString:
                guard respArray.count == 3 else {
                    throw RESPDecodeError.invalidArraySize(respArray, expectedSize: 3)
                }
                let channel = try String(arrayIterator.next()!)
                self.value = .shardChannel(channel)
                self.type = try TokenType.message(channel: channel, message: ByteBuffer(arrayIterator.next()!))

            case Self.invalidateString:
                guard respArray.count == 2 else {
                    throw RESPDecodeError.invalidArraySize(respArray, expectedSize: 2)
                }
                self.value = .channel(ValkeySubscriptions.invalidateChannel)
                self.type = try TokenType.invalidate(keys: [ValkeyKey](arrayIterator.next()!))
            default:
                throw RESPDecodeError(.unexpectedToken, token: first, message: "Unexpected Push notification \(String(buffer: notification))")
            }
        case .simpleString,
            .bulkString,
            .verbatimString,
            .simpleError,
            .bulkError,
            .number,
            .double,
            .boolean,
            .null,
            .bigNumber,
            .array,
            .map,
            .set,
            .attribute:
            throw RESPDecodeError.tokenMismatch(expected: [.push], token: token)
        }
    }
}
