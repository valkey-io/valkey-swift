//
// This source file is part of the valkey-swift project
// Copyright (c) 2025-2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import NIOCore

@_documentation(visibility: internal)
public struct PubSubSubscriptionCounts: RESPTokenDecodable & Sendable {
    public let channels: [(name: String, numberOfSubscribers: Int)]

    public init(_ token: RESPToken) throws {
        switch token.value {
        case .array(let array):
            var iterator = array.makeIterator()
            var channels: [(name: String, numberOfSubscribers: Int)] = []
            channels.reserveCapacity(array.count / 2)
            while let nameToken = iterator.next() {
                guard let subscribersToken = iterator.next() else {
                    throw RESPDecodeError.invalidArraySize(array)
                }
                try channels.append((nameToken.decode(), numberOfSubscribers: subscribersToken.decode()))
            }
            self.channels = channels
        default:
            throw RESPDecodeError.tokenMismatch(expected: [.array], token: token)
        }
    }
}

extension PUBSUB.NUMSUB {
    public typealias Response = PubSubSubscriptionCounts
}

extension PUBSUB.SHARDNUMSUB {
    public typealias Response = PubSubSubscriptionCounts
}
