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

import Logging
import NIOCore
import NIOEmbedded
import Testing
import Valkey

/// Test commands process their response correctly.
///
/// Generally the commands being tested here are ones we have written custom responses for
struct CommandTests {
    struct StringCommands {
        @Test
        func lcs() async throws {
            let channel = NIOAsyncTestingChannel()
            let logger = Logger(label: "test")
            let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
            try await channel.processHello()

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
                    #expect(outbound == RESPToken(.command(["LCS", "key1", "key2"])).base)
                    try await channel.writeInbound(RESPToken(.bulkString("mytext")).base)
                    outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.command(["LCS", "key1", "key2", "LEN"])).base)
                    try await channel.writeInbound(RESPToken(.number(6)).base)
                    outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.command(["LCS", "key1", "key2", "IDX"])).base)
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

    struct ListCommands {
        @Test
        func lpop() async throws {
            let channel = NIOAsyncTestingChannel()
            let logger = Logger(label: "test")
            let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
            try await channel.processHello()

            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    var values = try await connection.lpop(key: "key1")
                    #expect(try values?.decode(as: [String].self) == ["one"])
                    values = try await connection.lpop(key: "key1", count: 3)
                    #expect(try values?.decode(as: [String].self) == ["two", "three", "four"])
                }
                group.addTask {
                    var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.command(["LPOP", "key1"])).base)
                    try await channel.writeInbound(RESPToken(.bulkString("one")).base)
                    outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.command(["LPOP", "key1", "3"])).base)
                    try await channel.writeInbound(RESPToken(.array([.bulkString("two"), .bulkString("three"), .bulkString("four")])).base)
                }
                try await group.waitForAll()
            }
        }

        @Test
        func lpos() async throws {
            let channel = NIOAsyncTestingChannel()
            let logger = Logger(label: "test")
            let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
            try await channel.processHello()

            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    var indices = try await connection.lpos(key: "key1", element: "c")
                    #expect(indices == [2])
                    indices = try await connection.lpos(key: "key1", element: "c", numMatches: 2)
                    #expect(indices == [2, 6])
                }
                group.addTask {
                    var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.command(["LPOS", "key1", "c"])).base)
                    try await channel.writeInbound(RESPToken(.number(2)).base)
                    outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.command(["LPOS", "key1", "c", "COUNT", "2"])).base)
                    try await channel.writeInbound(RESPToken(.array([.number(2), .number(6)])).base)
                }
                try await group.waitForAll()
            }
        }
    }

    struct SortedSetCommands {
        @Test
        func zpopmin() async throws {
            let channel = NIOAsyncTestingChannel()
            let logger = Logger(label: "test")
            let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
            try await channel.processHello()

            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    var result = try await connection.zpopmin(key: "key")
                    #expect(result[0].score == 1)
                    #expect(try result[0].value.decode(as: String.self) == "one")
                    result = try await connection.zpopmin(key: "key", count: 2)
                    #expect(result[0].score == 2)
                    #expect(try result[0].value.decode(as: String.self) == "two")
                    #expect(result[1].score == 3)
                    #expect(try result[1].value.decode(as: String.self) == "three")
                }
                group.addTask {
                    var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.command(["ZPOPMIN", "key"])).base)
                    try await channel.writeInbound(RESPToken(.array([.bulkString("one"), .double(1.0)])).base)
                    outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.command(["ZPOPMIN", "key", "2"])).base)
                    try await channel.writeInbound(
                        RESPToken(
                            .array([
                                .array([.bulkString("two"), .double(2.0)]),
                                .array([.bulkString("three"), .double(3.0)]),
                            ])
                        ).base
                    )
                }
                try await group.waitForAll()
            }

        }

        @Test
        func zmpop() async throws {
            let channel = NIOAsyncTestingChannel()
            let logger = Logger(label: "test")
            let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
            try await channel.processHello()

            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    var result = try await connection.zmpop(key: ["key", "key2"], where: .max)
                    #expect(result?.key == ValkeyKey(rawValue: "key"))
                    #expect(result?.values[0].score == 3)
                    #expect(try result?.values[0].value.decode(as: String.self) == "three")
                    result = try await connection.zmpop(key: ["key", "key2"], where: .max, count: 2)
                    #expect(result?.key == ValkeyKey(rawValue: "key2"))
                    #expect(result?.values[0].score == 5)
                    #expect(try result?.values[0].value.decode(as: String.self) == "five")
                    #expect(result?.values[1].score == 4)
                    #expect(try result?.values[1].value.decode(as: String.self) == "four")
                }
                group.addTask {
                    var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.command(["ZMPOP", "2", "key", "key2", "MAX"])).base)
                    try await channel.writeInbound(
                        RESPToken(
                            .array([
                                .bulkString("key"),
                                .array([
                                    .array([.bulkString("three"), .double(3.0)])
                                ]),
                            ])
                        ).base
                    )
                    outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.command(["ZMPOP", "2", "key", "key2", "MAX", "COUNT", "2"])).base)
                    try await channel.writeInbound(
                        RESPToken(
                            .array([
                                .bulkString("key2"),
                                .array([
                                    .array([.bulkString("five"), .double(5.0)]),
                                    .array([.bulkString("four"), .double(4.0)]),
                                ]),
                            ])
                        ).base
                    )
                }
                try await group.waitForAll()
            }

        }

        @Test
        func zrange() async throws {
            let channel = NIOAsyncTestingChannel()
            let logger = Logger(label: "test")
            let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
            try await channel.processHello()

            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    var result = try await connection.zrange(key: "key", start: "4", stop: "10", sortby: .byscore, withscores: true)
                        .decode(as: [SortedSetEntry].self)
                    #expect(result[0].score == 4)
                    #expect(try result[0].value.decode(as: String.self) == "four")
                    result = try await connection.zrange(key: "key", start: "2", stop: "3", sortby: .byscore, withscores: true).decode(
                        as: [SortedSetEntry].self
                    )
                    #expect(result[0].score == 2)
                    #expect(try result[0].value.decode(as: String.self) == "two")
                    #expect(result[1].score == 3)
                    #expect(try result[1].value.decode(as: String.self) == "three")
                }
                group.addTask {
                    var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.command(["ZRANGE", "key", "4", "10", "BYSCORE", "WITHSCORES"])).base)
                    try await channel.writeInbound(
                        RESPToken(
                            .array([
                                .array([.bulkString("four"), .double(4.0)])
                            ])
                        ).base
                    )
                    outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.command(["ZRANGE", "key", "2", "3", "BYSCORE", "WITHSCORES"])).base)
                    try await channel.writeInbound(
                        RESPToken(
                            .array([
                                .array([.bulkString("two"), .double(2.0)]),
                                .array([.bulkString("three"), .double(3.0)]),
                            ])
                        ).base
                    )

                }
                try await group.waitForAll()
            }

        }
    }
}
