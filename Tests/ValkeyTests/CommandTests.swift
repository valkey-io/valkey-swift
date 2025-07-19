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

/// Test commands render correctly and process their response correctly.
///
/// Generally the commands being tested here are ones we have written custom responses for
struct CommandTests {
    struct ServerCommands {
        /// Test non-optional tokens render correctly
        @Test
        @available(valkeySwift 1.0, *)
        func replicaof() async throws {
            let channel = NIOAsyncTestingChannel()
            let logger = Logger(label: "test")
            let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
            try await channel.processHello()

            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await connection.replicaof(args: .hostPort(.init(host: "127.0.0.1", port: 18000)))
                    try await connection.replicaof(args: .noOne)
                }
                group.addTask {
                    var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.command(["REPLICAOF", "127.0.0.1", "18000"])).base)
                    try await channel.writeInbound(RESPToken(.simpleString("Ok")).base)

                    outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.command(["REPLICAOF", "NO", "ONE"])).base)
                    try await channel.writeInbound(RESPToken(.simpleString("Ok")).base)
                }
                try await group.waitForAll()
            }
        }
    }

    struct SetCommands {
        @Test
        @available(valkeySwift 1.0, *)
        func spop() async throws {
            let channel = NIOAsyncTestingChannel()
            let logger = Logger(label: "test")
            let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
            try await channel.processHello()

            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    var result = try #require(try await connection.spop("key1"))
                    #expect(try result.decode(as: [String].self) == ["mytext"])
                    result = try #require(try await connection.spop("key2", count: 2))
                    #expect(try result.decode(as: [String].self) == ["mytext1", "mytext2"])
                    let nilResult = try await connection.spop("key3")
                    #expect(nilResult == nil)
                }
                group.addTask {
                    var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.command(["SPOP", "key1"])).base)
                    try await channel.writeInbound(RESPToken(.bulkString("mytext")).base)

                    outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(String(buffer: outbound) == String(buffer: RESPToken(.command(["SPOP", "key2", "2"])).base))
                    try await channel.writeInbound(RESPToken(.array([.bulkString("mytext1"), .bulkString("mytext2")])).base)

                    outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.command(["SPOP", "key3"])).base)
                    try await channel.writeInbound(RESPToken(.null).base)
                }
                try await group.waitForAll()
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func sscan() async throws {
            let channel = NIOAsyncTestingChannel()
            let logger = Logger(label: "test")
            let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
            try await channel.processHello()

            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    let result = try await connection.sscan("key1", cursor: 0, pattern: "test*", count: 2)
                    #expect(result.cursor == 8)
                    #expect(try result.elements.decode(as: [String].self) == ["entry1", "entry2"])
                }
                group.addTask {
                    let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.command(["SSCAN", "key1", "0", "MATCH", "test*", "COUNT", "2"])).base)
                    try await channel.writeInbound(
                        RESPToken(
                            .array([
                                .bulkString("8"),
                                .array([
                                    .bulkString("entry1"),
                                    .bulkString("entry2"),
                                ]),
                            ])
                        ).base
                    )
                }
                try await group.waitForAll()
            }
        }
    }

    struct StringCommands {
        @Test
        @available(valkeySwift 1.0, *)
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
        @available(valkeySwift 1.0, *)
        func lpop() async throws {
            let channel = NIOAsyncTestingChannel()
            let logger = Logger(label: "test")
            let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
            try await channel.processHello()

            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    var values = try await connection.lpop("key1")
                    #expect(try values?.decode(as: [String].self) == ["one"])
                    values = try await connection.lpop("key1", count: 3)
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
        @available(valkeySwift 1.0, *)
        func lpos() async throws {
            let channel = NIOAsyncTestingChannel()
            let logger = Logger(label: "test")
            let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
            try await channel.processHello()

            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    var indices = try await connection.lpos("key1", element: "c")
                    #expect(indices == [2])
                    indices = try await connection.lpos("key1", element: "c", numMatches: 2)
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

        @Test
        @available(valkeySwift 1.0, *)
        func lmpop() async throws {
            let channel = NIOAsyncTestingChannel()
            let logger = Logger(label: "test")
            let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
            try await channel.processHello()

            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    var values = try await connection.lmpop(keys: ["key1", "key2"], where: .right)
                    #expect(values?.key == "key1")
                    try #expect(values?.values.decode(as: [String].self) == ["a"])
                    values = try await connection.lmpop(keys: ["key1", "key2"], where: .left, count: 2)
                    #expect(values?.key == "key2")
                    try #expect(values?.values.decode(as: [String].self) == ["c", "b"])
                }
                group.addTask {
                    var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.command(["LMPOP", "2", "key1", "key2", "RIGHT"])).base)
                    try await channel.writeInbound(
                        RESPToken(
                            .array([
                                .bulkString("key1"),
                                .array([
                                    .bulkString("a")
                                ]),
                            ])
                        ).base
                    )
                    outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.command(["LMPOP", "2", "key1", "key2", "LEFT", "COUNT", "2"])).base)
                    try await channel.writeInbound(
                        RESPToken(
                            .array([
                                .bulkString("key2"),
                                .array([
                                    .bulkString("c"),
                                    .bulkString("b"),
                                ]),
                            ])
                        ).base
                    )
                }
                try await group.waitForAll()
            }
        }
    }

    struct SortedSetCommands {
        @Test
        @available(valkeySwift 1.0, *)
        func zpopmin() async throws {
            let channel = NIOAsyncTestingChannel()
            let logger = Logger(label: "test")
            let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
            try await channel.processHello()

            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    var result = try await connection.zpopmin("key")
                    #expect(result[0].score == 1)
                    #expect(String(buffer: result[0].value) == "one")
                    result = try await connection.zpopmin("key", count: 2)
                    #expect(result[0].score == 2)
                    #expect(String(buffer: result[0].value) == "two")
                    #expect(result[1].score == 3)
                    #expect(String(buffer: result[1].value) == "three")
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
        @available(valkeySwift 1.0, *)
        func zmpop() async throws {
            let channel = NIOAsyncTestingChannel()
            let logger = Logger(label: "test")
            let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
            try await channel.processHello()

            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    var result = try await connection.zmpop(keys: ["key", "key2"], where: .max)
                    #expect(result?.key == "key")
                    #expect(result?.values[0].score == 3)
                    #expect((result?.values[0].value).map { String(buffer: $0) } == "three")
                    result = try await connection.zmpop(keys: ["key", "key2"], where: .max, count: 2)
                    #expect(result?.key == ValkeyKey("key2"))
                    #expect(result?.values[0].score == 5)
                    #expect((result?.values[0].value).map { String(buffer: $0) } == "five")
                    #expect(result?.values[1].score == 4)
                    #expect((result?.values[1].value).map { String(buffer: $0) } == "four")
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
        @available(valkeySwift 1.0, *)
        func zrange() async throws {
            let channel = NIOAsyncTestingChannel()
            let logger = Logger(label: "test")
            let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
            try await channel.processHello()

            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    var result = try await connection.zrange("key", start: "4", stop: "10", sortby: .byscore, withscores: true)
                        .decode(as: [SortedSetEntry].self)
                    #expect(result[0].score == 4)
                    #expect(String(buffer: result[0].value) == "four")
                    result = try await connection.zrange("key", start: "2", stop: "3", sortby: .byscore, withscores: true).decode(
                        as: [SortedSetEntry].self
                    )
                    #expect(result[0].score == 2)
                    #expect(String(buffer: result[0].value) == "two")
                    #expect(result[1].score == 3)
                    #expect(String(buffer: result[1].value) == "three")
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

        /// Test generated commands render optional tokens in blocks correctly
        @Test
        @available(valkeySwift 1.0, *)
        func zrandmember() async throws {
            let channel = NIOAsyncTestingChannel()
            let logger = Logger(label: "test")
            let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
            try await channel.processHello()

            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    _ = try await connection.zrandmember("test", options: .init(count: 0, withscores: true))
                    _ = try await connection.zrandmember("test", options: .init(count: 0, withscores: false))
                }
                group.addTask {
                    var outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.command(["ZRANDMEMBER", "test", "0", "WITHSCORES"])).base)
                    try await channel.writeInbound(RESPToken(.array([])).base)

                    outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.command(["ZRANDMEMBER", "test", "0"])).base)
                    try await channel.writeInbound(RESPToken(.array([])).base)
                }
                try await group.waitForAll()
            }
        }
    }

    struct StreamCommands {
        @Test
        @available(valkeySwift 1.0, *)
        func xread() async throws {
            let channel = NIOAsyncTestingChannel()
            let logger = Logger(label: "test")
            let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
            try await channel.processHello()

            async let asyncResult = connection.xread(count: 2, streams: .init(keys: ["key1", "key2"], ids: ["0-0", "0-0"]))

            let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            #expect(outbound == RESPToken(.command(["XREAD", "COUNT", "2", "STREAMS", "key1", "key2", "0-0", "0-0"])).base)

            try await channel.writeInbound(
                RESPToken(
                    .map([
                        .bulkString("key1"): .array([
                            .array([
                                .bulkString("event1"),
                                .array([
                                    .bulkString("field1"),
                                    .bulkString("value1"),
                                ]),
                            ])
                        ]),
                        .bulkString("key2"): .array([
                            .array([
                                .bulkString("event2"),
                                .array([
                                    .bulkString("field2"),
                                    .bulkString("value2"),
                                ]),
                            ]),
                            .array([
                                .bulkString("event3"),
                                .array([
                                    .bulkString("field3"),
                                    .bulkString("value3"),
                                    .bulkString("field4"),
                                    .bulkString("value4"),
                                ]),
                            ]),
                        ]),
                    ])
                ).base
            )
            let result = try #require(try await asyncResult)
            #expect(result.streams.count == 2)
            let stream1 = try #require(result.streams.first { $0.key == "key1" })
            let stream2 = try #require(result.streams.first { $0.key == "key2" })
            #expect(stream1.key == "key1")
            #expect(stream1.messages[0].id == "event1")
            #expect(stream1.messages[0][field: "field1"].map { String(buffer: $0) } == "value1")
            #expect(stream2.key == "key2")
            #expect(stream2.messages[0].id == "event2")
            #expect(stream2.messages[0][field: "field2"].map { String(buffer: $0) } == "value2")
            #expect(stream2.messages[1].id == "event3")
            #expect(stream2.messages[1][field: "field3"].map { String(buffer: $0) } == "value3")
            #expect(stream2.messages[1][field: "field4"].map { String(buffer: $0) } == "value4")
        }

        @Test
        @available(valkeySwift 1.0, *)
        func xreadgroup() async throws {
            let channel = NIOAsyncTestingChannel()
            let logger = Logger(label: "test")
            let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
            try await channel.processHello()

            async let asyncResult = connection.xreadgroup(
                groupBlock: .init(group: "MyGroup", consumer: "MyConsumer"),
                count: 2,
                streams: .init(keys: ["key1"], ids: [">"])
            )

            let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            #expect(outbound == RESPToken(.command(["XREADGROUP", "GROUP", "MyGroup", "MyConsumer", "COUNT", "2", "STREAMS", "key1", ">"])).base)

            try await channel.writeInbound(
                RESPToken(
                    .map([
                        .bulkString("key1"): .array([
                            .array([
                                .bulkString("event1"),
                                .array([
                                    .bulkString("field1"),
                                    .bulkString("value1"),
                                ]),
                            ]),
                            .array([
                                .bulkString("event2"),
                                .null,
                            ]),
                        ])
                    ])
                ).base
            )
            let result = try #require(try await asyncResult)
            #expect(result.streams.count == 1)
            let stream1 = try #require(result.streams.first { $0.key == "key1" })
            #expect(stream1.key == "key1")
            #expect(stream1.messages[0].id == "event1")
            #expect(stream1.messages[0].fields?[0].key == "field1")
            #expect(stream1.messages[0].fields.map { String(buffer: $0[0].value) } == "value1")
            #expect(stream1.messages[1].id == "event2")
            #expect(stream1.messages[1].fields == nil)
        }

        @Test
        @available(valkeySwift 1.0, *)
        func xautoclaim() async throws {
            let channel = NIOAsyncTestingChannel()
            let logger = Logger(label: "test")
            let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
            try await channel.processHello()

            async let asyncResult = connection.xautoclaim("key1", group: "MyGroup", consumer: "consumer1", minIdleTime: "0", start: "0")

            let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            #expect(outbound == RESPToken(.command(["XAUTOCLAIM", "key1", "MyGroup", "consumer1", "0", "0"])).base)

            try await channel.writeInbound(
                RESPToken(
                    .array([
                        .bulkString("0-0"),
                        .array([
                            .array([
                                .bulkString("1749460498430-0"),
                                .array([
                                    .bulkString("f2"),
                                    .bulkString("v2"),
                                ]),
                            ])
                        ]),
                        .array([
                            .bulkString("1749460498428-0")
                        ]),
                    ])
                ).base
            )
            let result = try await asyncResult
            #expect(result.streamID == "0-0")
            #expect(result.messages.count == 1)
            #expect(result.messages[0].id == "1749460498430-0")
            #expect(result.deletedMessages.count == 1)
            #expect(result.deletedMessages[0] == "1749460498428-0")
        }

        @Test
        @available(valkeySwift 1.0, *)
        func xclaim() async throws {
            let channel = NIOAsyncTestingChannel()
            let logger = Logger(label: "test")
            let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
            try await channel.processHello()

            async let asyncResult = connection.xclaim("key1", group: "MyGroup", consumer: "consumer1", minIdleTime: "0", ids: ["1749463853292-0"])

            let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            #expect(outbound == RESPToken(.command(["XCLAIM", "key1", "MyGroup", "consumer1", "0", "1749463853292-0"])).base)

            try await channel.writeInbound(
                RESPToken(
                    .array([
                        .array([
                            .bulkString("1749464199407-0"),
                            .array([
                                .bulkString("f"),
                                .bulkString("v"),
                            ]),
                        ]),
                        .array([
                            .bulkString("1749464199408-0"),
                            .array([
                                .bulkString("f2"),
                                .bulkString("v2"),
                            ]),
                        ]),
                    ])
                ).base
            )
            let result = try await asyncResult
            switch result {
            case .messages(let messages):
                #expect(messages.count == 2)
                #expect(messages[0].id == "1749464199407-0")
                #expect(messages[0].fields.count == 1)
                #expect(messages[0].fields[0].key == "f")
                #expect(String(buffer: messages[0].fields[0].value) == "v")
                #expect(messages[1].id == "1749464199408-0")
                #expect(messages[1].fields.count == 1)
                #expect(messages[1].fields[0].key == "f2")
                #expect(String(buffer: messages[1].fields[0].value) == "v2")
            default:
                Issue.record("Expected `messages` case")
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func xpending() async throws {
            let channel = NIOAsyncTestingChannel()
            let logger = Logger(label: "test")
            let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
            try await channel.processHello()

            async let asyncResult = connection.xpending("key", group: "MyGroup")

            let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            #expect(outbound == RESPToken(.command(["XPENDING", "key", "MyGroup"])).base)

            try await channel.writeInbound(
                RESPToken(
                    .array([
                        .number(3),
                        .bulkString("1749462751004-0"),
                        .bulkString("1749462751005-0"),
                        .array([
                            .array([
                                .bulkString("consumer1"),
                                .bulkString("1"),
                            ]),
                            .array([
                                .bulkString("consumer2"),
                                .bulkString("2"),
                            ]),
                        ]),
                    ])
                ).base
            )
            let result = try await asyncResult
            switch result {
            case .standard(let standard):
                #expect(standard.pendingMessageCount == 3)
                #expect(standard.minimumID == "1749462751004-0")
                #expect(standard.maximumID == "1749462751005-0")
                #expect(standard.consumers.count == 2)
                #expect(standard.consumers[0].consumer == "consumer1")
                #expect(standard.consumers[0].count == "1")
                #expect(standard.consumers[1].consumer == "consumer2")
                #expect(standard.consumers[1].count == "2")
            case .extended:
                Issue.record("Expected `standard` case")

            }
        }
    }

    struct GeoCommands {
        @Test
        @available(valkeySwift 1.0, *)
        func geopos() async throws {
            let channel = NIOAsyncTestingChannel()
            let logger = Logger(label: "test")
            let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
            try await channel.processHello()

            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    let values = try await connection.geopos("key1", members: ["Edinburgh", "Glasgow", "Dundee"])
                    #expect(values.count == 3)
                    let edinburgh = try #require(values[0])
                    #expect(values[1] == nil)
                    let dundee = try #require(values[2])
                    #expect(edinburgh.longitude == 1)
                    #expect(edinburgh.latitude == 2)
                    #expect(dundee.longitude == 3)
                    #expect(dundee.latitude == 4)
                }
                group.addTask {
                    let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.command(["GEOPOS", "key1", "Edinburgh", "Glasgow", "Dundee"])).base)
                    try await channel.writeInbound(
                        RESPToken(
                            .array([
                                .array([.bulkString("1.0"), .bulkString("2.0")]),
                                .null,
                                .array([.bulkString("3.0"), .bulkString("4.0")]),
                            ])
                        ).base
                    )
                }
                try await group.waitForAll()
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func geodist() async throws {
            let channel = NIOAsyncTestingChannel()
            let logger = Logger(label: "test")
            let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
            try await channel.processHello()

            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    let distance = try await connection.geodist("key1", member1: "Edinburgh", member2: "Glasgow")
                    #expect(distance == 42)
                }
                group.addTask {
                    let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound == RESPToken(.command(["GEODIST", "key1", "Edinburgh", "Glasgow"])).base)
                    try await channel.writeInbound(
                        RESPToken(.bulkString("42.0")).base
                    )
                }
                try await group.waitForAll()
            }
        }
    }
}
