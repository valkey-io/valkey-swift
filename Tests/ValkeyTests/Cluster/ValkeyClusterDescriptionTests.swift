//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import Testing
import Valkey

@Suite("Tests for parsing ValkeyClusterDescription from different RESP formats")
struct ValkeyClusterDescriptionTests {

    @Test("Parse cluster description with array representation")
    func testClusterDescriptionFromArray() throws {
        let val = RESP3Value.array([
            .array([
                .bulkString("slots"),
                .array([
                    .number(0),
                    .number(5),
                ]),
                .bulkString("nodes"),
                .array([
                    .array([
                        .bulkString("id"),
                        .bulkString("foo"),
                        .bulkString("port"),
                        .number(5),
                        .bulkString("tls-port"),
                        .number(6),
                        .bulkString("ip"),
                        .bulkString("127.0.0.1"),
                        .bulkString("hostname"),
                        .bulkString("mockHostname"),
                        .bulkString("endpoint"),
                        .bulkString("mockEndpoint"),
                        .bulkString("role"),
                        .bulkString("master"),
                        .bulkString("replication-offset"),
                        .number(22),
                        .bulkString("health"),
                        .bulkString("online"),
                    ])
                ]),
            ])
        ])
        let token = RESPToken(val)
        let description = try ValkeyClusterDescription(fromRESP: token)

        #expect(
            description
                == ValkeyClusterDescription([
                    .init(
                        slots: [0...5],
                        nodes: [
                            .init(
                                id: "foo",
                                port: 5,
                                tlsPort: 6,
                                ip: "127.0.0.1",
                                hostname: "mockHostname",
                                endpoint: "mockEndpoint",
                                role: .primary,
                                replicationOffset: 22,
                                health: .online
                            )
                        ]
                    )
                ])
        )
    }

    @Test("Fail to parse cluster description with invalid health name")
    func testInvalidHealthName() throws {
        let val = RESP3Value.array([
            .array([
                .bulkString("slots"),
                .array([
                    .number(0),
                    .number(5),
                ]),
                .bulkString("nodes"),
                .array([
                    .array([
                        .bulkString("id"),
                        .bulkString("foo"),
                        .bulkString("port"),
                        .number(5),
                        .bulkString("ip"),
                        .bulkString("127.0.0.1"),
                        .bulkString("endpoint"),
                        .bulkString("mockEndpoint"),
                        .bulkString("role"),
                        .bulkString("master"),
                        .bulkString("replication-offset"),
                        .number(22),
                        .bulkString("health"),
                        .bulkString("invalid-health-state"),  // Invalid health value
                    ])
                ]),
            ])
        ])
        let token = RESPToken(val)

        #expect(throws: RESPDecodeError(.unexpectedToken, token: .init(.bulkString("invalid-health-state")), message: "Invalid Node Health String")) {
            _ = try ValkeyClusterDescription(fromRESP: token)
        }
    }

    @Test("Test error handling with invalid token types")
    func testSlotsAreNotAnArray() throws {
        // Non-array token for cluster description
        let singleValueToken = RESPToken(RESP3Value.bulkString("not-an-array"))
        #expect(throws: RESPDecodeError.tokenMismatch(expected: [.array], token: .init(.bulkString("not-an-array")))) {
            _ = try ValkeyClusterDescription(fromRESP: singleValueToken)
        }

        // Non-array token for slots
        let invalidSlotsToken = RESPToken(
            RESP3Value.array([
                .array([
                    .bulkString("slots"),
                    .bulkString("not-an-array"),  // Should be an array
                    .bulkString("nodes"),
                    .array([
                        .array([
                            .bulkString("id"),
                            .bulkString("node1"),
                            .bulkString("port"),
                            .number(6379),
                            .bulkString("ip"),
                            .bulkString("192.168.1.100"),
                            .bulkString("endpoint"),
                            .bulkString("node.example.com"),
                            .bulkString("role"),
                            .bulkString("master"),
                            .bulkString("replication-offset"),
                            .number(100),
                            .bulkString("health"),
                            .bulkString("online"),
                        ])
                    ]),
                ])
            ])
        )

        #expect(throws: RESPDecodeError.tokenMismatch(expected: [.array], token: .init(.bulkString("not-an-array")))) {
            try ValkeyClusterDescription(fromRESP: invalidSlotsToken)
        }

        // Non-array token for nodes
        let invalidNodesToken = RESPToken(
            RESP3Value.array([
                .array([
                    .bulkString("slots"),
                    .array([.number(0), .number(100)]),
                    .bulkString("nodes"),
                    .bulkString("not-an-array"),  // Should be an array
                ])
            ])
        )

        #expect(throws: RESPDecodeError.tokenMismatch(expected: [.array], token: .init(.bulkString("not-an-array")))) {
            _ = try ValkeyClusterDescription(fromRESP: invalidNodesToken)
        }
    }

    @Test("Test node role is invalid value")
    func testNodeInvalidRole() throws {
        // Node with both invalid role and invalid health
        let valWithMultipleErrors = RESP3Value.array([
            .array([
                .bulkString("slots"),
                .array([.number(0), .number(5)]),
                .bulkString("nodes"),
                .array([
                    .array([
                        .bulkString("id"),
                        .bulkString("foo"),
                        .bulkString("port"),
                        .number(5),
                        .bulkString("ip"),
                        .bulkString("127.0.0.1"),
                        .bulkString("endpoint"),
                        .bulkString("mockEndpoint"),
                        .bulkString("role"),
                        .bulkString("invalid-role"),  // Invalid role
                        .bulkString("replication-offset"),
                        .number(22),
                        .bulkString("health"),
                        .bulkString("invalid-health"),  // Invalid health
                    ])
                ]),
            ])
        ])
        let token = RESPToken(valWithMultipleErrors)

        // The error we expect to see first is the invalid role
        #expect(throws: RESPDecodeError(.unexpectedToken, token: .init(.bulkString("invalid-role")), message: "Invalid Role String")) {
            _ = try ValkeyClusterDescription(fromRESP: token)
        }
    }

    @Test("Parse cluster description with map representation instead of array")
    func testClusterDescriptionFromMap() throws {
        // Creating a map representation with the same data as testClusterDescriptionFromArray
        let val = RESP3Value.array([
            .map([
                .bulkString("slots"): .array([
                    .number(0),
                    .number(5),
                ]),
                .bulkString("nodes"): .array([
                    .map([
                        .bulkString("id"): .bulkString("foo"),
                        .bulkString("port"): .number(5),
                        .bulkString("tls-port"): .number(6),
                        .bulkString("ip"): .bulkString("127.0.0.1"),
                        .bulkString("hostname"): .bulkString("mockHostname"),
                        .bulkString("endpoint"): .bulkString("mockEndpoint"),
                        .bulkString("role"): .bulkString("master"),
                        .bulkString("replication-offset"): .number(22),
                        .bulkString("health"): .bulkString("online"),
                    ])
                ]),
            ])
        ])

        let token = RESPToken(val)
        let description = try ValkeyClusterDescription(fromRESP: token)

        #expect(
            description
                == ValkeyClusterDescription([
                    .init(
                        slots: [0...5],
                        nodes: [
                            .init(
                                id: "foo",
                                port: 5,
                                tlsPort: 6,
                                ip: "127.0.0.1",
                                hostname: "mockHostname",
                                endpoint: "mockEndpoint",
                                role: .primary,
                                replicationOffset: 22,
                                health: .online
                            )
                        ]
                    )
                ])
        )
    }

    @Test("Parse cluster description with a mix of array and map representations")
    func testClusterDescriptionFromMixedArrayAndMap() throws {
        // First shard uses array format, second shard uses map format
        let val = RESP3Value.array([
            // First shard - array representation
            .array([
                .bulkString("slots"),
                .array([
                    .number(0),
                    .number(5),
                ]),
                .bulkString("nodes"),
                .array([
                    .array([
                        .bulkString("id"),
                        .bulkString("node1"),
                        .bulkString("port"),
                        .number(6379),
                        .bulkString("ip"),
                        .bulkString("192.168.1.100"),
                        .bulkString("endpoint"),
                        .bulkString("node1.example.com"),
                        .bulkString("role"),
                        .bulkString("master"),
                        .bulkString("replication-offset"),
                        .number(100),
                        .bulkString("health"),
                        .bulkString("online"),
                    ])
                ]),
            ]),
            // Second shard - map representation
            .map([
                .bulkString("slots"): .array([
                    .number(6),
                    .number(10),
                ]),
                .bulkString("nodes"): .array([
                    .map([
                        .bulkString("id"): .bulkString("node2"),
                        .bulkString("port"): .number(6380),
                        .bulkString("ip"): .bulkString("192.168.1.101"),
                        .bulkString("endpoint"): .bulkString("node2.example.com"),
                        .bulkString("role"): .bulkString("master"),
                        .bulkString("replication-offset"): .number(200),
                        .bulkString("health"): .bulkString("online"),
                    ])
                ]),
            ]),
        ])

        let token = RESPToken(val)
        let description = try ValkeyClusterDescription(fromRESP: token)

        #expect(
            description
                == ValkeyClusterDescription([
                    .init(
                        slots: [0...5],
                        nodes: [
                            .init(
                                id: "node1",
                                port: 6379,
                                tlsPort: nil,
                                ip: "192.168.1.100",
                                hostname: nil,
                                endpoint: "node1.example.com",
                                role: .primary,
                                replicationOffset: 100,
                                health: .online
                            )
                        ]
                    ),
                    .init(
                        slots: [6...10],
                        nodes: [
                            .init(
                                id: "node2",
                                port: 6380,
                                tlsPort: nil,
                                ip: "192.168.1.101",
                                hostname: nil,
                                endpoint: "node2.example.com",
                                role: .primary,
                                replicationOffset: 200,
                                health: .online
                            )
                        ]
                    ),
                ])
        )
    }
}
