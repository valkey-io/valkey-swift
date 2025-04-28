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

import Logging
import NIOCore
import NIOEmbedded
import Testing
import Valkey

struct CustomResponseTests {
    struct StringCommands {
        @Test
        func lcs() async throws {
            let channel = NIOAsyncTestingChannel()
            let logger = Logger(label: "test")
            let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(respVersion: .v2), logger: logger)

            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    var result = try await connection.lcs(key1: "key1", key2: "key2")
                    #expect(result == .subSequence("mytext"))
                    result = try await connection.lcs(key1: "key1", key2: "key2", len: true)
                    #expect(result == .subSequenceLength(6))
                    result = try await connection.lcs(key1: "key1", key2: "key2", idx: true)
                    switch result {
                    case .matches(let length, let matches):
                        #expect(length == 6)
                        #expect(matches[0].first == 4...7)
                        #expect(matches[0].second == 5...8)
                        #expect(matches[1].first == 2...3)
                        #expect(matches[1].second == 0...1)
                    default:
                        Issue.record("Expected `matches` case")
                    }
                }
                group.addTask {
                    var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.array([.bulkString("LCS"), .bulkString("key1"), .bulkString("key2")])).base)
                    try await channel.writeInbound(RESPToken(.bulkString("mytext")).base)
                    outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.array([.bulkString("LCS"), .bulkString("key1"), .bulkString("key2"), .bulkString("LEN")])).base)
                    try await channel.writeInbound(RESPToken(.number(6)).base)
                    outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.array([.bulkString("LCS"), .bulkString("key1"), .bulkString("key2"), .bulkString("IDX")])).base)
                    try await channel.writeInbound(
                        RESPToken(
                            .map([
                                .bulkString("matches"): .array([
                                    .array([
                                        .array([.number(4), .number(7)]),
                                        .array([.number(5), .number(8)]),
                                    ]),
                                    .array([
                                        .array([.number(2), .number(3)]),
                                        .array([.number(0), .number(1)]),
                                    ]),
                                ]),
                                .bulkString("len"): .number(6),
                            ])
                        ).base
                    )
                }
                try await group.waitForAll()
            }
        }
    }
}
