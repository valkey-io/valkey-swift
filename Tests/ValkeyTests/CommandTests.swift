//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import Logging
import NIOCore
import NIOEmbedded
import Testing
import Valkey

/// Test commands render correctly and process their response correctly.
///
/// Generally the commands being tested here are ones we have written custom responses for
struct CommandTests {
    struct ConnectionCommands {
        @Test
        @available(valkeySwift 1.0, *)
        func clientTracking() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["CLIENT", "TRACKING", "OFF"]),
                    response: .simpleString("OK")
                ),
                (
                    request: .command(["CLIENT", "TRACKING", "ON", "REDIRECT", "25", "PREFIX", "test"]),
                    response: .simpleString("OK")
                ),
                (
                    request: .command(["CLIENT", "TRACKING", "ON", "REDIRECT", "25", "PREFIX", "test", "PREFIX", "this"]),
                    response: .simpleString("OK")
                )
            ) { connection in
                try await connection.clientTracking(status: .off)
                try await connection.clientTracking(status: .on, clientId: 25, prefixes: ["test"])
                try await connection.clientTracking(status: .on, clientId: 25, prefixes: ["test", "this"])
            }
        }
    }

    struct ScriptCommands {
        @Test
        @available(valkeySwift 1.0, *)
        func functionList() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["FUNCTION", "LIST", "LIBRARYNAME", "_valkey_swift_tests", "WITHCODE"]),
                    response: .map([
                        .bulkString("library_name"): .bulkString("_valkey_swift_tests"),
                        .bulkString("engine"): .bulkString("LUA"),
                        .bulkString("functions"): .array([
                            .map([
                                .bulkString("name"): .bulkString("valkey_swift_test_get"),
                                .bulkString("description"): .null,
                                .bulkString("flags"): .set([]),
                            ]),
                            .map([
                                .bulkString("name"): .bulkString("valkey_swift_test_set"),
                                .bulkString("description"): .null,
                                .bulkString("flags"): .set([]),
                            ]),
                        ]),
                        .bulkString("library_code"): .bulkString(
                            """
                            #!lua name=_valkey_swift_tests
                            local function test_get(keys, args)
                                return redis.call("GET", keys[1])
                            end
                            local function test_set(keys, args)
                                return redis.call("SET", keys[1], args[1])
                            end
                            server.register_function('valkey_swift_test_set', test_set)
                            server.register_function('valkey_swift_test_get', test_get)")
                            """
                        ),
                    ])
                )
            ) { connection in
                let list = try await connection.functionList(libraryNamePattern: "_valkey_swift_tests", withcode: true)
                let library = try #require(list.first)
                #expect(library.libraryName == "_valkey_swift_tests")
                #expect(library.engine == "LUA")
                #expect(library.libraryCode?.hasPrefix("#!lua name=_valkey_swift_tests") == true)
                #expect(library.functions.count == 2)
                #expect(library.functions.contains { $0.name == "valkey_swift_test_set" })
                #expect(library.functions.contains { $0.name == "valkey_swift_test_get" })
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func functionStats() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["FUNCTION", "STATS"]),
                    response: .map([
                        .bulkString("running_script"): .map([
                            .bulkString("name"): .bulkString("valkey_swift_infinite_loop"),
                            .bulkString("command"): .array([
                                .bulkString("FCALL"),
                                .bulkString("valkey_swift_infinite_loop"),
                                .bulkString("2"),
                                .bulkString("30549BCC-6128-4C57-ACE4-ED7AC3ACFE3A"),
                                .bulkString("13299520-9AF5-4FFE-83C2-38C8F801EDAD"),
                            ]),
                            .bulkString("duration_ms"): .number(5053),
                        ]),
                        .bulkString("engines"): .map([
                            .bulkString("LUA"): .map([
                                .bulkString("libraries_count"): .number(3),
                                .bulkString("functions_count"): .number(8),
                            ])
                        ]),
                    ])
                )
            ) { connection in
                let stats = try await connection.functionStats()
                #expect(stats.runningScript.name == "valkey_swift_infinite_loop")
                #expect(
                    stats.runningScript.command.map { String(buffer: $0) } == [
                        "FCALL",
                        "valkey_swift_infinite_loop",
                        "2",
                        "30549BCC-6128-4C57-ACE4-ED7AC3ACFE3A",
                        "13299520-9AF5-4FFE-83C2-38C8F801EDAD",
                    ]
                )
                #expect(stats.runningScript.durationInMilliseconds == 5053)
                let lua = try #require(stats.engines["LUA"])
                #expect(lua.functionCount == 8)
                #expect(lua.libraryCount == 3)
            }
        }
    }

    struct ServerCommands {
        @Test
        @available(valkeySwift 1.0, *)
        func role() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["ROLE"]),
                    response: .array([
                        .bulkString("master"),
                        .number(10),
                        .array([
                            .array([
                                .bulkString("127.0.0.1"),
                                .bulkString("9001"),
                                .bulkString("1"),
                            ]),
                            .array([
                                .bulkString("127.0.0.1"),
                                .bulkString("9002"),
                                .bulkString("6"),
                            ]),
                        ]),
                    ])
                ),
                (
                    request: .command(["ROLE"]),
                    response: .array([
                        .bulkString("slave"),
                        .bulkString("127.0.0.1"),
                        .number(9000),
                        .bulkString("connected"),
                        .number(6),
                    ])
                )
            ) { connection in
                var role = try await connection.role()
                guard case .primary(let primary) = role else {
                    Issue.record()
                    return
                }
                #expect(primary.replicationOffset == 10)
                #expect(primary.replicas.count == 2)
                #expect(primary.replicas[0].ip == "127.0.0.1")
                #expect(primary.replicas[0].port == 9001)
                #expect(primary.replicas[0].replicationOffset == 1)
                #expect(primary.replicas[1].ip == "127.0.0.1")
                #expect(primary.replicas[1].port == 9002)
                #expect(primary.replicas[1].replicationOffset == 6)

                role = try await connection.role()
                guard case .replica(let replica) = role else {
                    Issue.record()
                    return
                }
                #expect(replica.primaryIP == "127.0.0.1")
                #expect(replica.primaryPort == 9000)
                #expect(replica.state == .connected)
                #expect(replica.replicationOffset == 6)
            }
        }
        /// Test non-optional tokens render correctly
        @Test
        @available(valkeySwift 1.0, *)
        func replicaof() async throws {
            try await testCommandEncodesDecodes(
                (request: .command(["REPLICAOF", "127.0.0.1", "18000"]), response: .simpleString("Ok")),
                (request: .command(["REPLICAOF", "NO", "ONE"]), response: .simpleString("Ok"))
            ) { connection in
                try await connection.replicaof(args: .hostPort(.init(host: "127.0.0.1", port: 18000)))
                try await connection.replicaof(args: .noOne)
            }
        }
    }

    struct SetCommands {
        @Test
        @available(valkeySwift 1.0, *)
        func spop() async throws {
            try await testCommandEncodesDecodes(
                (request: .command(["SPOP", "key1"]), response: .bulkString("mytext")),
                (request: .command(["SPOP", "key2", "2"]), response: .array([.bulkString("mytext1"), .bulkString("mytext2")])),
                (request: .command(["SPOP", "key3"]), response: .null)
            ) { connection in
                var result = try #require(try await connection.spop("key1"))
                #expect(try result.decode(as: [String].self) == ["mytext"])
                result = try #require(try await connection.spop("key2", count: 2))
                #expect(try result.decode(as: [String].self) == ["mytext1", "mytext2"])
                let nilResult = try await connection.spop("key3")
                #expect(nilResult == nil)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func sscan() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["SSCAN", "key1", "0", "MATCH", "test*", "COUNT", "2"]),
                    response: .array([
                        .bulkString("8"),
                        .array([
                            .bulkString("entry1"),
                            .bulkString("entry2"),
                        ]),
                    ])
                ),
            ) { connection in
                let result = try await connection.sscan("key1", cursor: 0, pattern: "test*", count: 2)
                #expect(result.cursor == 8)
                #expect(try result.elements.decode(as: [String].self) == ["entry1", "entry2"])
            }
        }
    }

    struct StringCommands {
        @Test
        @available(valkeySwift 1.0, *)
        func lcs() async throws {
            try await testCommandEncodesDecodes(
                (request: .command(["LCS", "key1", "key2"]), response: .bulkString("mytext")),
                (request: .command(["LCS", "key1", "key2", "LEN"]), response: .number(6)),
                (
                    request: .command(["LCS", "key1", "key2", "IDX"]),
                    response: .map([
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
                )
            ) { connection in
                var result = try await connection.lcs(key1: "key1", key2: "key2")
                #expect(try result.longestMatch() == "mytext")
                result = try await connection.lcs(key1: "key1", key2: "key2", len: true)
                #expect(try result.longestMatchLength() == 6)
                result = try await connection.lcs(key1: "key1", key2: "key2", idx: true)
                let matches = try result.matches()
                #expect(matches.length == 6)
                #expect(matches.matches[0].first == 4...7)
                #expect(matches.matches[0].second == 5...8)
                #expect(matches.matches[1].first == 2...3)
                #expect(matches.matches[1].second == 0...1)
            }
        }
    }

    struct ListCommands {
        @Test
        @available(valkeySwift 1.0, *)
        func lpop() async throws {
            try await testCommandEncodesDecodes(
                (request: .command(["LPOP", "key1"]), response: .bulkString("one")),
                (request: .command(["LPOP", "key1", "3"]), response: .array([.bulkString("two"), .bulkString("three"), .bulkString("four")]))
            ) { connection in
                var values = try await connection.lpop("key1")
                #expect(try values?.decode(as: [String].self) == ["one"])
                values = try await connection.lpop("key1", count: 3)
                #expect(try values?.decode(as: [String].self) == ["two", "three", "four"])
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func blpop() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["BLPOP", "key1", "key2", "30.0"]),
                    response: .array([
                        .bulkString("key2"),
                        .bulkString("test"),
                    ]),
                )
            ) { connection in
                let value = try await connection.blpop(keys: ["key1", "key2"], timeout: 30)
                #expect(value?.key == "key2")
                #expect(value?.value == ByteBuffer(string: "test"))
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func lpos() async throws {
            try await testCommandEncodesDecodes(
                (request: .command(["LPOS", "key1", "c"]), response: .number(2)),
                (request: .command(["LPOS", "key1", "c", "COUNT", "2"]), response: .array([.number(2), .number(6)]))
            ) { connection in
                var indices = try await connection.lpos("key1", element: "c")
                #expect(indices == [2])
                indices = try await connection.lpos("key1", element: "c", numMatches: 2)
                #expect(indices == [2, 6])
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func lmpop() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["LMPOP", "2", "key1", "key2", "RIGHT"]),
                    response: .array([
                        .bulkString("key1"),
                        .array([
                            .bulkString("a")
                        ]),
                    ])
                ),
                (
                    request: .command(["LMPOP", "2", "key1", "key2", "LEFT", "COUNT", "2"]),
                    response: .array([
                        .bulkString("key2"),
                        .array([
                            .bulkString("c"),
                            .bulkString("b"),
                        ]),
                    ])
                )
            ) { connection in
                var values = try await connection.lmpop(keys: ["key1", "key2"], where: .right)
                #expect(values?.key == "key1")
                try #expect(values?.values.decode(as: [String].self) == ["a"])
                values = try await connection.lmpop(keys: ["key1", "key2"], where: .left, count: 2)
                #expect(values?.key == "key2")
                try #expect(values?.values.decode(as: [String].self) == ["c", "b"])
            }
        }
    }

    struct SortedSetCommands {
        @Test
        @available(valkeySwift 1.0, *)
        func zpopmin() async throws {
            try await testCommandEncodesDecodes(
                (request: .command(["ZPOPMIN", "key"]), response: .array([.bulkString("one"), .double(1.0)])),
                (
                    request: .command(["ZPOPMIN", "key", "2"]),
                    response: .array([
                        .array([.bulkString("two"), .double(2.0)]),
                        .array([.bulkString("three"), .double(3.0)]),
                    ])
                )
            ) { connection in
                var result = try await connection.zpopmin("key")
                #expect(result[0].score == 1)
                #expect(String(buffer: result[0].value) == "one")
                result = try await connection.zpopmin("key", count: 2)
                #expect(result[0].score == 2)
                #expect(String(buffer: result[0].value) == "two")
                #expect(result[1].score == 3)
                #expect(String(buffer: result[1].value) == "three")
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func zmpop() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["ZMPOP", "2", "key", "key2", "MAX"]),
                    response: .array([
                        .bulkString("key"),
                        .array([
                            .array([.bulkString("three"), .double(3.0)])
                        ]),
                    ])
                ),
                (
                    request: .command(["ZMPOP", "2", "key", "key2", "MAX", "COUNT", "2"]),
                    response: .array([
                        .bulkString("key2"),
                        .array([
                            .array([.bulkString("five"), .double(5.0)]),
                            .array([.bulkString("four"), .double(4.0)]),
                        ]),
                    ])
                )
            ) { connection in
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
        }

        @Test
        @available(valkeySwift 1.0, *)
        func zrange() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["ZRANGE", "key", "4", "10", "BYSCORE", "WITHSCORES"]),
                    response: .array([
                        .array([.bulkString("four"), .double(4.0)])
                    ])
                ),
                (
                    request: .command(["ZRANGE", "key", "2", "3", "BYSCORE", "WITHSCORES"]),
                    response: .array([
                        .array([.bulkString("two"), .double(2.0)]),
                        .array([.bulkString("three"), .double(3.0)]),
                    ])
                )
            ) { connection in
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
        }

        @Test
        @available(valkeySwift 1.0, *)
        func zrandmember() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["ZRANDMEMBER", "test", "0", "WITHSCORES"]),
                    response: .array([])
                ),
                (
                    request: .command(["ZRANDMEMBER", "test", "0"]),
                    response: .array([])
                )
            ) { connection in
                _ = try await connection.zrandmember("test", options: .init(count: 0, withscores: true))
                _ = try await connection.zrandmember("test", options: .init(count: 0, withscores: false))
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func zscan() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["ZSCAN", "test", "0", "MATCH", "values*"]),
                    response: .array([
                        .bulkString("23"),
                        .array([
                            .bulkString("value1"),
                            .bulkString("5"),
                            .bulkString("value2"),
                            .bulkString("10"),
                        ]),
                    ])
                ),
                (
                    request: .command(["ZSCAN", "test", "23", "NOSCORES"]),
                    response: .array([
                        .bulkString("25"),
                        .array([
                            .bulkString("value3"),
                            .bulkString("value4"),
                        ]),
                    ])
                )
            ) { connection in
                var result = try await connection.zscan("test", cursor: 0, pattern: "values*")
                #expect(result.cursor == 23)
                let membersAndScores = try result.members.withScores()
                #expect(membersAndScores.count == 2)
                #expect(membersAndScores[0].score == 5)
                #expect(membersAndScores[0].value == ByteBuffer(string: "value1"))
                #expect(membersAndScores[1].score == 10)
                #expect(membersAndScores[1].value == ByteBuffer(string: "value2"))
                result = try await connection.zscan("test", cursor: 23, noscores: true)
                #expect(result.cursor == 25)
                let members = try result.members.withoutScores()
                #expect(members.count == 2)
                #expect(members[0] == ByteBuffer(string: "value3"))
                #expect(members[1] == ByteBuffer(string: "value4"))
            }
        }
    }

    struct StreamCommands {
        @Test
        @available(valkeySwift 1.0, *)
        func xread() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["XREAD", "COUNT", "2", "STREAMS", "key1", "key2", "0-0", "0-0"]),
                    response: .map([
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
                )
            ) { connection in
                let result = try await connection.xread(count: 2, streams: .init(keys: ["key1", "key2"], ids: ["0-0", "0-0"]))
                #expect(result?.streams.count == 2)
                let stream1 = try #require(result?.streams.first { $0.key == "key1" })
                let stream2 = try #require(result?.streams.first { $0.key == "key2" })
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
        }

        @Test
        @available(valkeySwift 1.0, *)
        func xreadgroup() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["XREADGROUP", "GROUP", "MyGroup", "MyConsumer", "COUNT", "2", "STREAMS", "key1", ">"]),
                    response: .map([
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
                )
            ) { connection in
                let result = try await connection.xreadgroup(
                    groupBlock: .init(group: "MyGroup", consumer: "MyConsumer"),
                    count: 2,
                    streams: .init(keys: ["key1"], ids: [">"])
                )
                #expect(result?.streams.count == 1)
                let stream1 = try #require(result?.streams.first { $0.key == "key1" })
                #expect(stream1.key == "key1")
                #expect(stream1.messages[0].id == "event1")
                #expect(stream1.messages[0].fields?[0].key == "field1")
                #expect(stream1.messages[0].fields.map { String(buffer: $0[0].value) } == "value1")
                #expect(stream1.messages[1].id == "event2")
                #expect(stream1.messages[1].fields == nil)

            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func xautoclaim() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["XAUTOCLAIM", "key1", "MyGroup", "consumer1", "0", "0"]),
                    response: .array([
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
                )
            ) { connection in
                let result = try await connection.xautoclaim("key1", group: "MyGroup", consumer: "consumer1", minIdleTime: "0", start: "0")
                #expect(result.streamID == "0-0")
                #expect(result.messages.count == 1)
                #expect(result.messages[0].id == "1749460498430-0")
                #expect(result.deletedMessages.count == 1)
                #expect(result.deletedMessages[0] == "1749460498428-0")
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func xclaim() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["XCLAIM", "key1", "MyGroup", "consumer1", "0", "1749463853292-0"]),
                    response: .array([
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
                )
            ) { connection in
                let result = try await connection.xclaim("key1", group: "MyGroup", consumer: "consumer1", minIdleTime: "0", ids: ["1749463853292-0"])
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
        }

        @Test
        @available(valkeySwift 1.0, *)
        func xpending() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["XPENDING", "key", "MyGroup"]),
                    response: .array([
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
                )
            ) { connection in
                let result = try await connection.xpending("key", group: "MyGroup")
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
    }

    struct GeoCommands {
        @Test
        @available(valkeySwift 1.0, *)
        func geopos() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["GEOPOS", "key1", "Edinburgh", "Glasgow", "Dundee"]),
                    response: .array([
                        .array([.bulkString("1.0"), .bulkString("2.0")]),
                        .null,
                        .array([.bulkString("3.0"), .bulkString("4.0")]),
                    ])
                )
            ) { connection in
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
        }

        @Test
        @available(valkeySwift 1.0, *)
        func geodist() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["GEODIST", "key1", "Edinburgh", "Glasgow"]),
                    response: .bulkString("42.0")
                )
            ) { connection in
                let distance = try await connection.geodist("key1", member1: "Edinburgh", member2: "Glasgow")
                #expect(distance == 42)
            }
        }
    }

    struct HashCommands {
        @Test
        @available(valkeySwift 1.0, *)
        func hscan() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["HSCAN", "test", "0", "MATCH", "values*"]),
                    response: .array([
                        .bulkString("23"),
                        .array([
                            .bulkString("field1"),
                            .bulkString("value1"),
                            .bulkString("field2"),
                            .bulkString("value2"),
                        ]),
                    ])
                ),
                (
                    request: .command(["HSCAN", "test", "23", "NOVALUES"]),
                    response: .array([
                        .bulkString("25"),
                        .array([
                            .bulkString("field3"),
                            .bulkString("field4"),
                        ]),
                    ])
                )
            ) { connection in
                var result = try await connection.hscan("test", cursor: 0, pattern: "values*")
                #expect(result.cursor == 23)
                let membersAndScores = try result.members.withValues()
                #expect(membersAndScores.count == 2)
                #expect(membersAndScores[0].field == ByteBuffer(string: "field1"))
                #expect(membersAndScores[0].value == ByteBuffer(string: "value1"))
                #expect(membersAndScores[1].field == ByteBuffer(string: "field2"))
                #expect(membersAndScores[1].value == ByteBuffer(string: "value2"))
                result = try await connection.hscan("test", cursor: 23, novalues: true)
                #expect(result.cursor == 25)
                let members = try result.members.withoutValues()
                #expect(members.count == 2)
                #expect(members[0] == ByteBuffer(string: "field3"))
                #expect(members[1] == ByteBuffer(string: "field4"))
            }
        }
    }
}

@available(valkeySwift 1.0, *)
func testCommandEncodesDecodes(
    _ respValues: (request: RESP3Value, response: RESP3Value)...,
    sourceLocation: SourceLocation = #_sourceLocation,
    operation: @escaping @Sendable (ValkeyConnection) async throws -> Void
) async throws {
    let channel = NIOAsyncTestingChannel()
    let logger = Logger(label: "test")
    let connection = try await ValkeyConnection.setupChannelAndConnect(channel, configuration: .init(), logger: logger)
    try await channel.processHello()

    try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask {
            try await operation(connection)
        }
        group.addTask {
            for (request, response) in respValues {
                let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(outbound == RESPToken(request).base, sourceLocation: sourceLocation)
                try await channel.writeInbound(RESPToken(response).base)
            }
        }
        try await group.waitForAll()
    }
}
