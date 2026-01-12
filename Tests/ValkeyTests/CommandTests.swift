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
import ValkeySearch

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

    struct ClusterCommands {
        @Test
        @available(valkeySwift 1.0, *)
        func clusterNodes() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["CLUSTER", "NODES"]),
                    response: .bulkString(
                        """
                        0b44e8f9af2a4b354b68eabc24330efbddba47aa 127.0.0.1:36004@46004 slave 5eab28fc81814e8b2210500fb650ffe622382bd8 0 1767807820519 3 connected
                        0577d8ed1e6b36796b6ce0b24aeef44de185ca68 127.0.0.1:36002@46002 myself,master - 0 0 2 connected 5461-10922
                        02d3f849999f98d7e1c498d64992de4e03f703de 127.0.0.1:36006@46006 slave 0577d8ed1e6b36796b6ce0b24aeef44de185ca68 0 1767807820000 2 connected
                        5eab28fc81814e8b2210500fb650ffe622382bd8 127.0.0.1:36003@46003 master - 0 1767807821640 3 connected 10923-16383
                        bdeb2fc40e0e4f934cf26fd601aa8c97720893f3 127.0.0.1:36001@46001 master - 0 1767807821539 1 connected 0-5460
                        14a77ccb848767e4da31ef85a0e1c62ac1ad018a 127.0.0.1:36005@46005 slave bdeb2fc40e0e4f934cf26fd601aa8c97720893f3 0 1767807820620 1 connected
                        """
                    )
                )
            ) { connection in
                let clusterNodes = try await connection.clusterNodes()
                for clusterNode in clusterNodes.nodes {
                    #expect(!clusterNode.nodeId.isEmpty)
                    #expect(!clusterNode.endpoint.isEmpty)
                    #expect(!clusterNode.flags.isEmpty)
                    if clusterNode.flags.contains(ValkeyClusterNode.Flag.replica) {
                        #expect(clusterNode.primaryId != nil && !clusterNode.primaryId!.isEmpty)
                    } else {
                        #expect(clusterNode.primaryId == nil)
                    }
                    #expect(clusterNode.pingSent >= 0)
                    #expect(clusterNode.pingSent >= 0)
                    #expect(clusterNode.pongReceived >= 0)
                    #expect(!clusterNode.linkState.isEmpty)
                }
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func clusterReplicas() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["CLUSTER", "REPLICAS", "leader-node-id"]),
                    response: .array([
                        .bulkString("replica-node-id1 127.0.0.1:36001@46001 slave leader-node-id 0 1767807820519 3 connected"),
                        .bulkString("replica-node-id2 127.0.0.1:36002@46002 slave leader-node-id 0 1767807820519 3 connected"),
                    ])
                )
            ) { connection in
                let clusterReplicas = try await connection.clusterReplicas(nodeId: "leader-node-id")
                for clusterReplica in clusterReplicas.nodes {
                    #expect(!clusterReplica.nodeId.isEmpty)
                    #expect(!clusterReplica.endpoint.isEmpty)
                    #expect(!clusterReplica.flags.isEmpty)
                    #expect(clusterReplica.primaryId != nil && clusterReplica.primaryId == "leader-node-id")
                    #expect(clusterReplica.pingSent >= 0)
                    #expect(clusterReplica.pingSent >= 0)
                    #expect(clusterReplica.pongReceived >= 0)
                    #expect(!clusterReplica.linkState.isEmpty)
                }
            }
        }
    }

    struct GenericCommands {
        @Test
        @available(valkeySwift 1.0, *)
        func waitAOF() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["WAITAOF", "1", "2", "15000"]),
                    response: .array([
                        .number(1),
                        .number(2),
                    ])
                )
            ) { connection in
                let result = try await connection.waitaof(numlocal: 1, numreplicas: 2, timeout: 15000)
                #expect(result.localSynced == true)
                #expect(result.numberOfReplicasSynced == 2)
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
                    stats.runningScript.command.map { String($0) } == [
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
        func commandGetkeysandflags() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["COMMAND", "GETKEYSANDFLAGS", "LMOVE", "mylist1", "mylist2", "left", "left"]),
                    response: .array([
                        .array([.bulkString("mylist1"), .array([.bulkString("RW"), .bulkString("access"), .bulkString("delete")])]),
                        .array([.bulkString("mylist2"), .array([.bulkString("RW"), .bulkString("insert")])]),
                    ])
                )
            ) { connection in
                let keys = try await connection.commandGetkeysandflags(command: "LMOVE", args: ["mylist1", "mylist2", "left", "left"])
                #expect(keys.count == 2)
                #expect(keys[0].key == "mylist1")
                #expect(keys[0].flags == [.rw, .access, .delete])
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func moduleList() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["MODULE", "LIST"]),
                    response: .array([
                        .map([
                            .bulkString("name"): .bulkString("json"),
                            .bulkString("ver"): .number(10002),
                            .bulkString("path"): .bulkString("/usr/lib/valkey/libjson.so"),
                            .bulkString("args"): .array([]),
                        ]),
                        .map([
                            .bulkString("name"): .bulkString("ldap"),
                            .bulkString("ver"): .number(16_777_471),
                            .bulkString("path"): .bulkString("/usr/lib/valkey/libvalkey_ldap.so"),
                            .bulkString("args"): .array([]),
                        ]),
                    ])
                )
            ) { connection in
                let modules = try await connection.moduleList()
                #expect(modules.count == 2)
                #expect(modules[0].name == "json")
                #expect(modules[0].version == 10002)
                #expect(modules[0].path == "/usr/lib/valkey/libjson.so")
                #expect(modules[0].args == [])
                #expect(modules[1].name == "ldap")
                #expect(modules[1].version == 16_777_471)
                #expect(modules[1].path == "/usr/lib/valkey/libvalkey_ldap.so")
                #expect(modules[1].args == [])
            }
        }

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

        @Test
        @available(valkeySwift 1.0, *)
        func time() async throws {
            try await testCommandEncodesDecodes(
                (request: .command(["TIME"]), response: .array([.number(1_714_701_491), .number(723379)])),
            ) { connection in
                let time = try await connection.time()
                #expect(time.seconds == 1_714_701_491)
                #expect(time.microSeconds == 723379)
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
                #expect(value.map { String($0.value) } == "test")
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
                #expect(String(result[0].value) == "one")
                result = try await connection.zpopmin("key", count: 2)
                #expect(result[0].score == 2)
                #expect(String(result[0].value) == "two")
                #expect(result[1].score == 3)
                #expect(String(result[1].value) == "three")
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
                #expect((result?.values[0].value).map { String($0) } == "three")
                result = try await connection.zmpop(keys: ["key", "key2"], where: .max, count: 2)
                #expect(result?.key == ValkeyKey("key2"))
                #expect(result?.values[0].score == 5)
                #expect((result?.values[0].value).map { String($0) } == "five")
                #expect(result?.values[1].score == 4)
                #expect((result?.values[1].value).map { String($0) } == "four")
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
                #expect(String(result[0].value) == "four")
                result = try await connection.zrange("key", start: "2", stop: "3", sortby: .byscore, withscores: true).decode(
                    as: [SortedSetEntry].self
                )
                #expect(result[0].score == 2)
                #expect(String(result[0].value) == "two")
                #expect(result[1].score == 3)
                #expect(String(result[1].value) == "three")
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
                #expect(String(membersAndScores[0].value) == "value1")
                #expect(membersAndScores[1].score == 10)
                #expect(String(membersAndScores[1].value) == "value2")
                result = try await connection.zscan("test", cursor: 23, noscores: true)
                #expect(result.cursor == 25)
                let members = try result.members.withoutScores()
                #expect(members.count == 2)
                #expect(String(members[0]) == "value3")
                #expect(String(members[1]) == "value4")
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
                #expect(stream1.messages[0][field: "field1"].map { String($0) } == "value1")
                #expect(stream2.key == "key2")
                #expect(stream2.messages[0].id == "event2")
                #expect(stream2.messages[0][field: "field2"].map { String($0) } == "value2")
                #expect(stream2.messages[1].id == "event3")
                #expect(stream2.messages[1][field: "field3"].map { String($0) } == "value3")
                #expect(stream2.messages[1][field: "field4"].map { String($0) } == "value4")
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
                #expect(stream1.messages[0].fields.map { String($0[0].value) } == "value1")
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
                    #expect(String(messages[0].fields[0].value) == "v")
                    #expect(messages[1].id == "1749464199408-0")
                    #expect(messages[1].fields.count == 1)
                    #expect(messages[1].fields[0].key == "f2")
                    #expect(String(messages[1].fields[0].value) == "v2")
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

        @Test
        @available(valkeySwift 1.0, *)
        func xinfoConsumers() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["XINFO", "CONSUMERS", "key", "MyGroup"]),
                    response: .array([
                        .array([
                            .bulkString("name"),
                            .bulkString("Alice"),
                            .bulkString("pending"),
                            .number(1),
                            .bulkString("idle"),
                            .number(9_104_628),
                            .bulkString("inactive"),
                            .number(18_104_698),
                        ]),
                        .array([
                            .bulkString("name"),
                            .bulkString("Bob"),
                            .bulkString("pending"),
                            .number(1),
                            .bulkString("idle"),
                            .number(83_841_983),
                            .bulkString("inactive"),
                            .number(993_841_998),
                        ]),
                    ])
                )
            ) { connection in
                let result = try await connection.xinfoConsumers("key", group: "MyGroup")
                #expect(result.count == 2)
                #expect(result[0].name == "Alice")
                #expect(result[0].pending == 1)
                #expect(result[0].idle == 9_104_628)
                #expect(result[0].inactive == 18_104_698)
                #expect(result[1].name == "Bob")
                #expect(result[1].pending == 1)
                #expect(result[1].idle == 83_841_983)
                #expect(result[1].inactive == 993_841_998)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func xinfoGroups() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["XINFO", "GROUPS", "key"]),
                    response: .array([
                        .array([
                            .bulkString("name"),
                            .bulkString("myGroup"),
                            .bulkString("consumers"),
                            .number(1),
                            .bulkString("pending"),
                            .number(2),
                            .bulkString("last-delivered-id"),
                            .bulkString("1638126030001-0"),
                            .bulkString("entries-read"),
                            .number(1),
                            .bulkString("lag"),
                            .number(1),
                        ]),
                        .array([
                            .bulkString("name"),
                            .bulkString("myOtherGroup"),
                            .bulkString("consumers"),
                            .number(1),
                            .bulkString("pending"),
                            .number(0),
                            .bulkString("last-delivered-id"),
                            .bulkString("1638126028070-0"),
                            .bulkString("entries-read"),
                            .number(2),
                        ]),
                    ])
                )
            ) { connection in
                let result = try await connection.xinfoGroups("key")
                #expect(result.count == 2)
                #expect(result[0].name == "myGroup")
                #expect(result[0].consumers == 1)
                #expect(result[0].pending == 2)
                #expect(result[0].lastDeliveredId == "1638126030001-0")
                #expect(result[0].entriesRead == 1)
                #expect(result[0].lag == 1)
                #expect(result[1].name == "myOtherGroup")
                #expect(result[1].consumers == 1)
                #expect(result[1].pending == 0)
                #expect(result[1].lastDeliveredId == "1638126028070-0")
                #expect(result[1].entriesRead == 2)
                #expect(result[1].lag == nil)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func xinfoStream() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["XINFO", "STREAM", "key"]),
                    response: .map([
                        .bulkString("length"): .number(2),
                        .bulkString("radix-tree-keys"): .number(2),
                        .bulkString("radix-tree-nodes"): .number(3),
                        .bulkString("last-generated-id"): .bulkString("1768072864629-0"),
                        .bulkString("max-deleted-entry-id"): .bulkString("0-0"),
                        .bulkString("entries-added"): .number(2),
                        .bulkString("groups"): .number(1),
                        .bulkString("first-entry"): .array([
                            .bulkString("1768072864629-0"),
                            .array([
                                .bulkString("key"),
                                .bulkString("field"),
                            ]),
                        ]),
                        .bulkString("last-entry"): .array([
                            .bulkString("1768072864630-0"),
                            .array([
                                .bulkString("key2"),
                                .bulkString("field2"),
                            ]),
                        ]),
                    ])
                )
            ) { connection in
                let result = try await connection.xinfoStream("key")
                #expect(result.length == 2)
                #expect(result.numberOfRadixTreeKeys == 2)
                #expect(result.numberOfRadixTreeNodes == 3)
                #expect(result.lastGeneratedID == "1768072864629-0")
                #expect(result.maxDeletedEntryID == "0-0")
                #expect(result.entriesAdded == 2)
                #expect(result.firstEntry?.id == "1768072864629-0")
                #expect(result.lastEntry?.id == "1768072864630-0")
            }
        }
    }

    struct GeoCommands {

        private var geoSearchResponse: RESP3Value = .array([
            .array([
                .bulkString("Edinburgh"), .bulkString("38.9"), .bulkString("3665074419141107"),
                .array([.bulkString("31.23"), .bulkString("56.20")]),
            ]),
            .array([
                .bulkString("Glasgow"), .bulkString("71.2"), .bulkString("3676829890883619"),
                .array([.bulkString("35.74"), .bulkString("44.87")]),
            ]),
            .array([
                .bulkString("Dundee"), .bulkString("128.5"), .bulkString("3676829890801228"),
                .array([.bulkString("33.62"), .bulkString("48.10")]),
            ]),
        ])

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

        @Test
        @available(valkeySwift 1.0, *)
        func geoSearch() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["GEOSEARCH", "Scotland", "BYRADIUS", "500.0", "km", "WITHCOORD", "WITHDIST", "WITHHASH"]),
                    response: geoSearchResponse
                ),
            ) { connection in
                let entries = try await connection.geosearch(
                    "Scotland",
                    by: .circle(.init(radius: 500.0, unit: .km)),
                    withcoord: true,
                    withdist: true,
                    withhash: true
                )
                try verifyGeoSearchEntries(
                    entries,
                    options: [.withHash, .withDist, .withCoord]
                )
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func geoRadius() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["GEORADIUS", "Scotland", "30.0", "50.0", "500.0", "km", "WITHCOORD", "WITHDIST", "WITHHASH"]),
                    response: geoSearchResponse
                ),
            ) { connection in
                let entries = try await connection.georadius(
                    "Scotland",
                    longitude: 30.0,
                    latitude: 50.0,
                    radius: 500.0,
                    unit: GEORADIUS.Unit.km,
                    withcoord: true,
                    withdist: true,
                    withhash: true
                )
                try verifyGeoSearchEntries(
                    entries,
                    options: [.withHash, .withDist, .withCoord]
                )
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func geoRadiusByMember() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["GEORADIUSBYMEMBER", "Scotland", "Edinburgh", "500.0", "km", "WITHCOORD", "WITHDIST", "WITHHASH"]),
                    response: geoSearchResponse
                ),
            ) { connection in
                let entries = try await connection.georadiusbymember(
                    "Scotland",
                    member: "Edinburgh",
                    radius: 500.0,
                    unit: GEORADIUSBYMEMBER.Unit.km,
                    withcoord: true,
                    withdist: true,
                    withhash: true
                )
                try verifyGeoSearchEntries(
                    entries,
                    options: [.withHash, .withDist, .withCoord]
                )
            }
        }

        private func verifyGeoSearchEntries(_ entries: GeoSearchEntries, options: [GeoSearchEntries.Option]) throws {
            for entry in try entries.decode(options: [
                .withHash, .withDist, .withCoord,
            ]) {
                #expect(!entry.member.isEmpty)
                #expect(entry.distance != nil && entry.distance! >= 0)
                #expect(entry.hash != nil && entry.hash! > 0)
                #expect(entry.coordinates != nil)
                #expect(entry.coordinates!.latitude > 0)
                #expect(entry.coordinates!.longitude > 0)
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
                #expect(String(membersAndScores[0].field) == "field1")
                #expect(String(membersAndScores[0].value) == "value1")
                #expect(String(membersAndScores[1].field) == "field2")
                #expect(String(membersAndScores[1].value) == "value2")
                result = try await connection.hscan("test", cursor: 23, novalues: true)
                #expect(result.cursor == 25)
                let members = try result.members.withoutValues()
                #expect(members.count == 2)
                #expect(String(members[0]) == "field3")
                #expect(String(members[1]) == "field4")
            }
        }
    }

    struct SearchCommands {
        @Test
        @available(valkeySwift 1.0, *)
        func ftSearch() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["FT.SEARCH", "idx:myIndex", "@title:Hello World"]),
                    response: .array([
                        .number(2),
                        .bulkString("doc:1"),
                        .array([
                            .bulkString("title"),
                            .bulkString("Hello World"),
                            .bulkString("body"),
                            .bulkString("This is a test document"),
                        ]),
                        .bulkString("doc:2"),
                        .array([
                            .bulkString("title"),
                            .bulkString("Hello Again"),
                            .bulkString("body"),
                            .bulkString("Another world example"),
                        ]),
                    ])
                )
            ) { connection in
                let result = try await connection.ftSearch(index: "idx:myIndex", query: "@title:Hello World")
                guard case .array(let array1) = result.value else {
                    Issue.record("Expected array response")
                    return
                }
                let items = Array(array1)
                #expect(items.count == 5)
                guard case .number(let count) = items[0].value else {
                    Issue.record("Expected number")
                    return
                }
                #expect(count == 2)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftSearch_nocontent() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.SEARCH",
                        "idx:myIndex",
                        "@title:Hello",
                        "NOCONTENT",
                    ]),
                    response: .array([
                        .number(2),
                        .bulkString("doc:1"),
                        .bulkString("doc:2"),
                    ])
                )
            ) { connection in
                let result = try await connection.ftSearch(
                    index: "idx:myIndex",
                    query: "@title:Hello",
                    nocontent: true
                )

                guard case .array(let arr1) = result.value else {
                    Issue.record("Expected array response")
                    return
                }

                let items = Array(arr1)
                #expect(items.count == 3)

                guard case .number(let total) = items[0].value else {
                    Issue.record("Expected first element to be number")
                    return
                }
                #expect(total == 2)

                guard case .bulkString = items[1].value else {
                    Issue.record("Expected second element to be bulk string (doc id)")
                    return
                }
                guard case .bulkString = items[2].value else {
                    Issue.record("Expected third element to be bulk string (doc id)")
                    return
                }
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftSearch_limit() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.SEARCH",
                        "idx:myIndex",
                        "@title:Hello",
                        "LIMIT", "10", "20",
                    ]),
                    response: .array([
                        .number(0)
                    ])
                )
            ) { connection in
                let result = try await connection.ftSearch(
                    index: "idx:myIndex",
                    query: "@title:Hello",
                    limit: .init(offset: 10, count: 20)
                )

                guard case .array(let arr1) = result.value else {
                    Issue.record("Expected array response")
                    return
                }

                let items = Array(arr1)
                #expect(items.count == 1)

                guard case .number(let total) = items[0].value else {
                    Issue.record("Expected first element to be number")
                    return
                }
                #expect(total == 0)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftSearch_timeout() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.SEARCH",
                        "idx:myIndex",
                        "@title:Hello",
                        "TIMEOUT", "100",
                    ]),
                    response: .array([
                        .number(0)
                    ])
                )
            ) { connection in
                let result = try await connection.ftSearch(
                    index: "idx:myIndex",
                    query: "@title:Hello",
                    timeout: .init(timeoutMs: 100)
                )

                guard case .array(let arr1) = result.value else {
                    Issue.record("Expected array response")
                    return
                }

                let items = Array(arr1)
                #expect(items.count == 1)

                guard case .number(let total) = items[0].value else {
                    Issue.record("Expected first element to be number")
                    return
                }
                #expect(total == 0)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftSearch_paramsAndLocalOnly() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.SEARCH",
                        "idx:myIndex",
                        "@title:$t @tag:{$tag}",
                        "PARAMS", "4",
                        "t", "Hello",
                        "tag", "world",
                        "LOCALONLY",
                    ]),
                    response: .array([
                        .number(0)
                    ])
                )
            ) { connection in
                let result = try await connection.ftSearch(
                    index: "idx:myIndex",
                    query: "@title:$t @tag:{$tag}",
                    params: .init(
                        count: 4,
                        pairs: ["t", "Hello", "tag", "world"]
                    ),
                    localonly: true
                )

                guard case .array(let arr1) = result.value else {
                    Issue.record("Expected array response")
                    return
                }

                let items = Array(arr1)
                #expect(items.count == 1)

                guard case .number(let total) = items[0].value else {
                    Issue.record("Expected first element to be number")
                    return
                }
                #expect(total == 0)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftSearch_returnFields() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.SEARCH",
                        "idx:myIndex",
                        "@title:Hello",
                        "RETURN", "2",
                        "title", "body",
                    ]),
                    response: .array([
                        .number(1),
                        .bulkString("doc:1"),
                        .array([
                            .bulkString("title"),
                            .bulkString("Hello"),
                            .bulkString("body"),
                            .bulkString("World"),
                        ]),
                    ])
                )
            ) { connection in
                let result = try await connection.ftSearch(
                    index: "idx:myIndex",
                    query: "@title:Hello",
                    returnFields: .init(
                        count: 2,
                        fields: ["title", "body"]
                    )
                )

                guard case .array(let arr1) = result.value else {
                    Issue.record("Expected array response")
                    return
                }

                let items = Array(arr1)
                #expect(items.count == 3)

                guard case .number(let total) = items[0].value else {
                    Issue.record("Expected first element to be number")
                    return
                }
                #expect(total == 1)

                guard case .bulkString = items[1].value else {
                    Issue.record("Expected second element to be bulk string (doc id)")
                    return
                }

                guard case .array(let fields1) = items[2].value else {
                    Issue.record("Expected third element to be array of fields")
                    return
                }

                let fields = Array(fields1)
                #expect(fields.count == 4)

                // We only assert the shape here, not the exact ByteBuffer contents.
                guard case .bulkString = fields[0].value,
                    case .bulkString = fields[1].value,
                    case .bulkString = fields[2].value,
                    case .bulkString = fields[3].value
                else {
                    Issue.record("Expected alternating field/value bulk strings")
                    return
                }
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftSearch_nocontentLimitDialect() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.SEARCH",
                        "idx:myIndex",
                        "@title:Hello",
                        "NOCONTENT",
                        "LIMIT", "0", "5",
                        "DIALECT", "2",
                    ]),
                    response: .array([
                        .number(0)
                    ])
                )
            ) { connection in
                let result = try await connection.ftSearch(
                    index: "idx:myIndex",
                    query: "@title:Hello",
                    nocontent: true,
                    limit: .init(offset: 0, count: 5),
                    dialect: .init(dialect: 2)
                )

                guard case .array(let arr1) = result.value else {
                    Issue.record("Expected array")
                    return
                }

                let items = Array(arr1)
                #expect(items.count == 1)

                guard case .number(let total) = items[0].value else {
                    Issue.record("Expected first element to be number")
                    return
                }
                #expect(total == 0)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftAggregate() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["FT.AGGREGATE", "idx:testIndex", "*"]),
                    response: .array([
                        .number(100),
                        .array([
                            .bulkString("field1"),
                            .bulkString("value1"),
                        ]),
                    ])
                )
            ) { connection in
                let result = try await connection.ftAggregate(
                    index: "idx:testIndex",
                    query: "*"
                )

                guard case .array(let outer) = result.value else {
                    Issue.record("Expected array response from FT.AGGREGATE")
                    return
                }

                let rows = Array(outer)
                #expect(rows.count == 2)

                guard case .number(let total) = rows[0].value else {
                    Issue.record("Expected first element to be total row count")
                    return
                }
                #expect(total == 100)

                guard case .array(let row1) = rows[1].value else {
                    Issue.record("Expected first row as array")
                    return
                }

                let fields = Array(row1)
                #expect(fields.count == 2)

                guard case .bulkString(let fieldName) = fields[0].value,
                    case .bulkString(let fieldValue) = fields[1].value
                else {
                    Issue.record("Expected field/value pair in first row")
                    return
                }

                #expect(String(buffer: fieldName) == "field1")
                #expect(String(buffer: fieldValue) == "value1")
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftAggregate_verbatim() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["FT.AGGREGATE", "idx:testIndex", "hello", "VERBATIM"]),
                    response: .array([.number(0)])
                )
            ) { connection in
                let result = try await connection.ftAggregate(
                    index: "idx:testIndex",
                    query: "hello",
                    verbatim: true
                )

                guard case .array(let arr) = result.value else {
                    Issue.record("Expected array")
                    return
                }
                let items = Array(arr)
                #expect(items.count == 1)
                guard case .number(let n) = items[0].value else {
                    Issue.record("Expected number")
                    return
                }
                #expect(n == 0)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftAggregate_load_withAlias() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.AGGREGATE", "idx:testIndex", "*",
                        "LOAD", "1",
                        "@title", "AS", "title",
                    ]),
                    response: .array([.number(0)])
                )
            ) { connection in
                let result = try await connection.ftAggregate(
                    index: "idx:testIndex",
                    query: "*",
                    load: .init(
                        nargs: 1,
                        items: [
                            .init(identifier: "@title", alias: .init(property: "title"))
                        ]
                    )
                )

                guard case .array(let arr) = result.value else {
                    Issue.record("Expected array")
                    return
                }
                let items = Array(arr)
                #expect(items.count == 1)
                guard case .number(let n) = items[0].value else {
                    Issue.record("Expected number")
                    return
                }
                #expect(n == 0)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftAggregate_load_multipleItems_mixedAlias() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.AGGREGATE", "idx:testIndex", "*",
                        "LOAD", "2",
                        "@title", "AS", "title",
                        "@body",
                    ]),
                    response: .array([.number(0)])
                )
            ) { connection in
                let result = try await connection.ftAggregate(
                    index: "idx:testIndex",
                    query: "*",
                    load: .init(
                        nargs: 2,
                        items: [
                            .init(identifier: "@title", alias: .init(property: "title")),
                            .init(identifier: "@body"),
                        ]
                    )
                )

                guard case .array(let arr) = result.value else {
                    Issue.record("Expected array")
                    return
                }
                let items = Array(arr)
                #expect(items.count == 1)
                guard case .number(let n) = items[0].value else {
                    Issue.record("Expected number")
                    return
                }
                #expect(n == 0)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftAggregate_timeout() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.AGGREGATE", "idx:testIndex", "*",
                        "TIMEOUT", "100",
                    ]),
                    response: .array([.number(0)])
                )
            ) { connection in
                let result = try await connection.ftAggregate(
                    index: "idx:testIndex",
                    query: "*",
                    timeout: .init(milliseconds: 100)
                )

                guard case .array(let arr) = result.value else {
                    Issue.record("Expected array")
                    return
                }
                let items = Array(arr)
                #expect(items.count == 1)
                guard case .number(let n) = items[0].value else {
                    Issue.record("Expected number")
                    return
                }
                #expect(n == 0)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftAggregate_params() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.AGGREGATE", "idx:testIndex", "@loc:[$lon $lat 10 km]",
                        "PARAMS", "4",
                        "lon", "29.69465",
                        "lat", "34.95126",
                    ]),
                    response: .array([.number(0)])
                )
            ) { connection in
                let result = try await connection.ftAggregate(
                    index: "idx:testIndex",
                    query: "@loc:[$lon $lat 10 km]",
                    params: .init(nargs: 4, parameters: [.init(name: "lon", value: "29.69465"), .init(name: "lat", value: "34.95126")])
                )

                guard case .array(let arr) = result.value else {
                    Issue.record("Expected array")
                    return
                }
                let items = Array(arr)
                #expect(items.count == 1)
                guard case .number(let n) = items[0].value else {
                    Issue.record("Expected number")
                    return
                }
                #expect(n == 0)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftAggregate_dialect() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.AGGREGATE", "idx:testIndex", "*",
                        "DIALECT", "2",
                    ]),
                    response: .array([.number(0)])
                )
            ) { connection in
                let result = try await connection.ftAggregate(
                    index: "idx:testIndex",
                    query: "*",
                    dialect: .init(dialectVersion: 2)
                )

                guard case .array(let arr) = result.value else {
                    Issue.record("Expected array")
                    return
                }
                let items = Array(arr)
                #expect(items.count == 1)
                guard case .number(let n) = items[0].value else {
                    Issue.record("Expected number")
                    return
                }
                #expect(n == 0)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftAggregate_scorer_addscores() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.AGGREGATE", "idx:testIndex", "hello",
                        "SCORER", "BM25",
                        "ADDSCORES",
                    ]),
                    response: .array([.number(0)])
                )
            ) { connection in
                let result = try await connection.ftAggregate(
                    index: "idx:testIndex",
                    query: "hello",
                    scorer: .init(scorer: "BM25"),
                    addscores: true
                )

                guard case .array(let arr) = result.value else {
                    Issue.record("Expected array")
                    return
                }
                let items = Array(arr)
                #expect(items.count == 1)
                guard case .number(let n) = items[0].value else {
                    Issue.record("Expected number")
                    return
                }
                #expect(n == 0)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftAggregate_sortby_withcount() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.AGGREGATE", "idx:testIndex", "hello",
                        "SORTBY", "4", "@foo", "ASC", "@bar", "DESC",
                        "WITHCOUNT",
                    ]),
                    response: .array([.number(0)])
                )
            ) { connection in
                let result = try await connection.ftAggregate(
                    index: "idx:testIndex",
                    query: "hello",
                    sortby: .init(
                        nargs: 4,
                        sortParams: ["@foo", "ASC", "@bar", "DESC"],
                        withcount: true
                    )
                )

                guard case .array(let arr) = result.value else {
                    Issue.record("Expected array")
                    return
                }
                let items = Array(arr)
                #expect(items.count == 1)
                guard case .number(let n) = items[0].value else {
                    Issue.record("Expected number")
                    return
                }
                #expect(n == 0)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftAggregate_sortby_max() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.AGGREGATE", "idx:testIndex", "hello",
                        "SORTBY", "2", "@foo", "DESC",
                        "MAX", "100",
                    ]),
                    response: .array([.number(0)])
                )
            ) { connection in
                let result = try await connection.ftAggregate(
                    index: "idx:testIndex",
                    query: "hello",
                    sortby: .init(
                        nargs: 2,
                        sortParams: ["@foo", "DESC"],
                        max: .init(num: 100)
                    )
                )

                guard case .array(let arr) = result.value else {
                    Issue.record("Expected array")
                    return
                }
                let items = Array(arr)
                #expect(items.count == 1)
                guard case .number(let n) = items[0].value else {
                    Issue.record("Expected number")
                    return
                }
                #expect(n == 0)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftAggregate_apply_multiple() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.AGGREGATE", "idx:testIndex", "*",
                        "APPLY", "sqrt(@foo)", "AS", "foo_sqrt",
                        "APPLY", "(@bar*2)", "AS", "bar2",
                    ]),
                    response: .array([.number(0)])
                )
            ) { connection in
                let result = try await connection.ftAggregate(
                    index: "idx:testIndex",
                    query: "*",
                    applys: [
                        .init(expr: "sqrt(@foo)", name: "foo_sqrt"),
                        .init(expr: "(@bar*2)", name: "bar2"),
                    ]
                )

                guard case .array(let arr) = result.value else {
                    Issue.record("Expected array")
                    return
                }
                let items = Array(arr)
                #expect(items.count == 1)
                guard case .number(let n) = items[0].value else {
                    Issue.record("Expected number")
                    return
                }
                #expect(n == 0)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftAggregate_limit() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.AGGREGATE", "idx:testIndex", "*",
                        "LIMIT", "10", "20",
                    ]),
                    response: .array([.number(0)])
                )
            ) { connection in
                let result = try await connection.ftAggregate(
                    index: "idx:testIndex",
                    query: "*",
                    limit: .init(offset: 10, num: 20)
                )

                guard case .array(let arr) = result.value else {
                    Issue.record("Expected array")
                    return
                }
                let items = Array(arr)
                #expect(items.count == 1)
                guard case .number(let n) = items[0].value else {
                    Issue.record("Expected number")
                    return
                }
                #expect(n == 0)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftAggregate_filter_multiple() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.AGGREGATE", "idx:testIndex", "*",
                        "FILTER", "@foo > 10",
                        "FILTER", "@bar < 20",
                    ]),
                    response: .array([.number(0)])
                )
            ) { connection in
                let result = try await connection.ftAggregate(
                    index: "idx:testIndex",
                    query: "*",
                    filters: [
                        .init(expr: "@foo > 10"),
                        .init(expr: "@bar < 20"),
                    ]
                )

                guard case .array(let arr) = result.value else {
                    Issue.record("Expected array")
                    return
                }
                let items = Array(arr)
                #expect(items.count == 1)
                guard case .number(let n) = items[0].value else {
                    Issue.record("Expected number")
                    return
                }
                #expect(n == 0)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftAggregate_withcursor_count_maxidle() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.AGGREGATE", "idx:testIndex", "*",
                        "WITHCURSOR",
                        "COUNT", "500",
                        "MAXIDLE", "10000",
                    ]),
                    response: .array([.number(0)])
                )
            ) { connection in
                let result = try await connection.ftAggregate(
                    index: "idx:testIndex",
                    query: "*",
                    withcursor: .init(
                        count: .init(readSize: 500),
                        maxidle: .init(idleTime: 10000)
                    )
                )

                guard case .array(let arr) = result.value else {
                    Issue.record("Expected array")
                    return
                }
                let items = Array(arr)
                #expect(items.count == 1)
                guard case .number(let n) = items[0].value else {
                    Issue.record("Expected number")
                    return
                }
                #expect(n == 0)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftAggregate_groupby_reduce_sum_as() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.AGGREGATE", "idx:testIndex", "*",
                        "GROUPBY", "1", "@category",
                        "REDUCE", "SUM", "1", "@price", "AS", "total_revenue",
                    ]),
                    response: .array([.number(0)])
                )
            ) { connection in
                let result = try await connection.ftAggregate(
                    index: "idx:testIndex",
                    query: "*",
                    groupbys: [
                        .init(
                            nargs: 1,
                            groupFields: ["@category"],
                        )
                    ],
                    reduces: [
                        .init(
                            function: .sum,
                            nargs: 1,
                            identifiers: ["@price"],
                            alias: .init(identifier: "total_revenue")

                        )
                    ]
                )

                guard case .array(let arr) = result.value else {
                    Issue.record("Expected array")
                    return
                }
                let items = Array(arr)
                #expect(items.count == 1)
                guard case .number(let n) = items[0].value else {
                    Issue.record("Expected number")
                    return
                }
                #expect(n == 0)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftAggregate_groupby_countDistinct() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.AGGREGATE", "idx:testIndex", "*",
                        "GROUPBY", "2", "@category", "@brand",
                        "REDUCE", "COUNT_DISTINCT", "1", "@user", "AS", "uniq_users",
                    ]),
                    response: .array([.number(0)])
                )
            ) { connection in
                let result = try await connection.ftAggregate(
                    index: "idx:testIndex",
                    query: "*",
                    groupbys: [
                        .init(
                            nargs: 2,
                            groupFields: ["@category", "@brand"],
                        )
                    ],
                    reduces: [
                        .init(
                            function: .countDistinct,
                            nargs: 1,
                            identifiers: ["@user"],
                            alias: .init(identifier: "uniq_users")

                        )
                    ]
                )

                guard case .array(let arr) = result.value else {
                    Issue.record("Expected array")
                    return
                }
                let items = Array(arr)
                #expect(items.count == 1)
                guard case .number(let n) = items[0].value else {
                    Issue.record("Expected number")
                    return
                }
                #expect(n == 0)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftCreate_onJson_withTextAlias() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.CREATE",
                        "idx:testIndex",
                        "ON", "JSON",
                        "PREFIX", "1", "item:",
                        "SCHEMA",
                        "$.name", "AS", "name", "TEXT",
                    ]),
                    response: .simpleString("OK")
                )
            ) { connection in
                try await connection.ftCreate(
                    indexName: "idx:testIndex",
                    on: .init(type: .json),
                    prefix: .init(count: 1, prefixes: ["item:"]),
                    schema: .init(fields: [
                        .init(fieldIdentifier: "$.name", alias: .init(fieldIdentifier: "name"), fieldType: .text)
                    ])
                )
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftCreate_noOn_noPrefix_numeric() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.CREATE",
                        "idx:noOn",
                        "SCHEMA",
                        "age", "NUMERIC",
                    ]),
                    response: .simpleString("OK")
                )
            ) { connection in
                try await connection.ftCreate(
                    indexName: "idx:noOn",
                    on: nil,
                    prefix: nil,
                    schema: .init(fields: [
                        .init(
                            fieldIdentifier: "age",
                            alias: nil,
                            fieldType: .numeric
                        )
                    ])
                )
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftCreate_tag_separatorOnly() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.CREATE",
                        "idx:tagSepOnly",
                        "SCHEMA",
                        "category", "TAG", "SEPARATOR", "|",
                    ]),
                    response: .simpleString("OK")
                )
            ) { connection in
                try await connection.ftCreate(
                    indexName: "idx:tagSepOnly",
                    on: nil,
                    prefix: nil,
                    schema: .init(fields: [
                        .init(
                            fieldIdentifier: "category",
                            alias: nil,
                            fieldType: .tag(
                                .init(
                                    separator: .init(sep: "|"),
                                    casesensitive: false
                                )
                            )
                        )
                    ])
                )
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftCreate_tag_caseSensitiveOnly() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.CREATE",
                        "idx:tagCaseOnly",
                        "SCHEMA",
                        "category", "TAG", "CASESENSITIVE",
                    ]),
                    response: .simpleString("OK")
                )
            ) { connection in
                try await connection.ftCreate(
                    indexName: "idx:tagCaseOnly",
                    on: nil,
                    prefix: nil,
                    schema: .init(fields: [
                        .init(
                            fieldIdentifier: "category",
                            alias: nil,
                            fieldType: .tag(
                                .init(
                                    separator: nil,
                                    casesensitive: true
                                )
                            )
                        )
                    ])
                )
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftCreate_onHASH_simpleText() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.CREATE",
                        "idx:hashIndex",
                        "ON", "HASH",
                        "SCHEMA",
                        "name", "TEXT",
                    ]),
                    response: .simpleString("OK")
                )
            ) { connection in
                try await connection.ftCreate(
                    indexName: "idx:hashIndex",
                    on: .init(type: .hash),
                    prefix: nil,
                    schema: .init(fields: [
                        .init(
                            fieldIdentifier: "name",
                            alias: nil,
                            fieldType: .text
                        )
                    ])
                )
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftCreate_onHASH_tagDefaultSeparator() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.CREATE",
                        "idx:tagIndex",
                        "ON", "HASH",
                        "SCHEMA",
                        "category", "TAG",
                    ]),
                    response: .simpleString("OK")
                )
            ) { connection in
                try await connection.ftCreate(
                    indexName: "idx:tagIndex",
                    on: .init(type: .hash),
                    prefix: nil,
                    schema: .init(fields: [
                        .init(
                            fieldIdentifier: "category",
                            alias: nil,
                            fieldType: .tag(
                                .init(
                                    separator: nil,
                                    casesensitive: false
                                )
                            )
                        )
                    ])
                )
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftCreate_onHASH_tagWithSeparatorAndCaseSensitive() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.CREATE",
                        "idx:tagIndex2",
                        "ON", "HASH",
                        "SCHEMA",
                        "category", "TAG", "SEPARATOR", "|", "CASESENSITIVE",
                    ]),
                    response: .simpleString("OK")
                )
            ) { connection in
                try await connection.ftCreate(
                    indexName: "idx:tagIndex2",
                    on: .init(type: .hash),
                    prefix: nil,
                    schema: .init(fields: [
                        .init(
                            fieldIdentifier: "category",
                            alias: nil,
                            fieldType: .tag(
                                .init(
                                    separator: .init(sep: "|"),
                                    casesensitive: true
                                )
                            )
                        )
                    ])
                )
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftCreate_onHASH_multiplePrefixes() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.CREATE",
                        "idx:multiPrefix",
                        "ON", "HASH",
                        "PREFIX", "2", "item:", "product:",
                        "SCHEMA",
                        "name", "TEXT",
                    ]),
                    response: .simpleString("OK")
                )
            ) { connection in
                try await connection.ftCreate(
                    indexName: "idx:multiPrefix",
                    on: .init(type: .hash),
                    prefix: .init(count: 2, prefixes: ["item:", "product:"]),
                    schema: .init(fields: [
                        .init(
                            fieldIdentifier: "name",
                            alias: nil,
                            fieldType: .text
                        )
                    ])
                )
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftCreate_onHASH_multipleFields() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.CREATE",
                        "idx:multiField",
                        "ON", "HASH",
                        "SCHEMA",
                        "name", "TEXT",
                        "age", "NUMERIC",
                    ]),
                    response: .simpleString("OK")
                )
            ) { connection in
                try await connection.ftCreate(
                    indexName: "idx:multiField",
                    on: .init(type: .hash),
                    prefix: nil,
                    schema: .init(fields: [
                        .init(
                            fieldIdentifier: "name",
                            alias: nil,
                            fieldType: .text
                        ),
                        .init(
                            fieldIdentifier: "age",
                            alias: nil,
                            fieldType: .numeric
                        ),
                    ])
                )
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftCreate_mixedFields_allTypes() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.CREATE",
                        "idx:mixed",
                        "ON", "HASH",
                        "PREFIX", "2", "item:", "product:",
                        "SCHEMA",
                        "name", "TEXT",
                        "price", "NUMERIC",
                        "category", "TAG", "SEPARATOR", "|",
                        "embedding", "VECTOR", "FLAT", "4",
                        "TYPE", "FLOAT32",
                        "DIM", "128",
                        "DISTANCE_METRIC", "L2",
                        "BLOCK_SIZE", "1024",
                    ]),
                    response: .simpleString("OK")
                )
            ) { connection in
                try await connection.ftCreate(
                    indexName: "idx:mixed",
                    on: .init(type: .hash),
                    prefix: .init(count: 2, prefixes: ["item:", "product:"]),
                    schema: .init(fields: [
                        .init(
                            fieldIdentifier: "name",
                            alias: nil,
                            fieldType: .text
                        ),
                        .init(
                            fieldIdentifier: "price",
                            alias: nil,
                            fieldType: .numeric
                        ),
                        .init(
                            fieldIdentifier: "category",
                            alias: nil,
                            fieldType: .tag(
                                .init(
                                    separator: .init(sep: "|"),
                                    casesensitive: false
                                )
                            )
                        ),
                        .init(
                            fieldIdentifier: "embedding",
                            alias: nil,
                            fieldType: .vector(
                                .init(
                                    algorithm: .flat,
                                    attrCount: 4,
                                    vectorParams: .init(
                                        type: .init(),
                                        dim: .init(value: 128),
                                        distanceMetric: .init(metric: .l2),
                                        m: nil,
                                        efConstruction: nil,
                                        blockSize: .init(value: 1024)
                                    )
                                )
                            )
                        ),
                    ])
                )
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftCreate_vectorHNSW() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.CREATE",
                        "my_index_name",
                        "SCHEMA",
                        "my_hash_field_key",
                        "VECTOR",
                        "HNSW",
                        "10",
                        "TYPE", "FLOAT32",
                        "DIM", "20",
                        "DISTANCE_METRIC", "COSINE",
                        "M", "4",
                        "EF_CONSTRUCTION", "100",
                    ]),
                    response: .simpleString("OK")
                )
            ) { connection in
                try await connection.ftCreate(
                    indexName: "my_index_name",
                    on: nil,
                    prefix: nil,
                    schema: .init(fields: [
                        .init(
                            fieldIdentifier: "my_hash_field_key",
                            alias: nil,
                            fieldType: .vector(
                                .init(
                                    algorithm: .hnsw,
                                    attrCount: 10,
                                    vectorParams: .init(
                                        type: .init(),
                                        dim: .init(value: 20),
                                        distanceMetric: .init(metric: .cosine),
                                        m: .init(value: 4),
                                        efConstruction: .init(value: 100)
                                    )
                                )
                            )
                        )
                    ])
                )
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftCreate_vectorFLAT() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.CREATE",
                        "my_flat_index",
                        "SCHEMA",
                        "embedding",
                        "VECTOR",
                        "FLAT",
                        "4",
                        "TYPE", "FLOAT32",
                        "DIM", "128",
                        "DISTANCE_METRIC", "L2",
                        "BLOCK_SIZE", "1024",
                    ]),
                    response: .simpleString("OK")
                )
            ) { connection in
                try await connection.ftCreate(
                    indexName: "my_flat_index",
                    on: nil,
                    prefix: nil,
                    schema: .init(fields: [
                        .init(
                            fieldIdentifier: "embedding",
                            alias: nil,
                            fieldType: .vector(
                                .init(
                                    algorithm: .flat,
                                    attrCount: 4,
                                    vectorParams: .init(
                                        type: .init(),
                                        dim: .init(value: 128),
                                        distanceMetric: .init(metric: .l2),
                                        blockSize: .init(value: 1024)
                                    )
                                )
                            )
                        )
                    ])
                )
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftCreate_vectorFlat_ipMetric() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command([
                        "FT.CREATE",
                        "idx:flatIP",
                        "SCHEMA",
                        "embedding",
                        "VECTOR",
                        "FLAT",
                        "8",
                        "TYPE", "FLOAT32",
                        "DIM", "64",
                        "DISTANCE_METRIC", "IP",
                    ]),
                    response: .simpleString("OK")
                )
            ) { connection in
                try await connection.ftCreate(
                    indexName: "idx:flatIP",
                    on: nil,
                    prefix: nil,
                    schema: .init(fields: [
                        .init(
                            fieldIdentifier: "embedding",
                            alias: nil,
                            fieldType: .vector(
                                .init(
                                    algorithm: .flat,
                                    attrCount: 8,
                                    vectorParams: .init(
                                        type: .init(),
                                        dim: .init(value: 64),
                                        distanceMetric: .init(metric: .ip),
                                        m: nil,
                                        efConstruction: nil,
                                        blockSize: nil
                                    )
                                )
                            )
                        )
                    ])
                )
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftDropindex() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["FT.DROPINDEX", "idx:myIndex"]),
                    response: .simpleString("OK")
                )
            ) { connection in
                try await connection.ftDropindex("idx:myIndex")
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftInfo() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["FT.INFO", "idx:myIndex"]),
                    response: .array([
                        .bulkString("index_name"),
                        .bulkString("myIndex"),
                        .bulkString("num_docs"),
                        .number(100),
                        .bulkString("num_terms"),
                        .number(500),
                    ])
                ),
                (
                    request: .command(["FT.INFO", "idx:myIndex", "LOCAL"]),
                    response: .array([
                        .bulkString("index_name"),
                        .bulkString("myIndex"),
                        .bulkString("num_docs"),
                        .number(50),
                    ])
                ),
                (
                    request: .command(["FT.INFO", "idx:myIndex", "GLOBAL"]),
                    response: .array([
                        .bulkString("index_name"),
                        .bulkString("idx:myIndex"),
                        .bulkString("num_docs"),
                        .number(200),
                    ])
                )
            ) { connection in
                _ = try await connection.ftInfo("idx:myIndex")
                _ = try await connection.ftInfo("idx:myIndex", scope: .local)
                _ = try await connection.ftInfo("idx:myIndex", scope: .global)
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftList() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["FT._LIST"]),
                    response: .array([
                        .bulkString("idx:index1"),
                        .bulkString("idx:index2"),
                        .bulkString("idx:myIndex"),
                    ])
                )
            ) { connection in
                _ = try await connection.ftList()
            }
        }

        @Test
        @available(valkeySwift 1.0, *)
        func ftDebug() async throws {
            try await testCommandEncodesDecodes(
                (
                    request: .command(["FT._DEBUG"]),
                    response: .array([
                        .bulkString("debug_info"),
                        .bulkString("some debug data"),
                    ])
                )
            ) { connection in
                _ = try await connection.ftDebug()
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
                #expect(
                    outbound == RESPToken(request).base,
                    "\(RESPToken(validated: outbound).value.descriptionWith(redact: false))",
                    sourceLocation: sourceLocation
                )
                try await channel.writeInbound(RESPToken(response).base)
            }
        }
        try await group.waitForAll()
    }
}
