//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey project
//
// Copyright (c) 2025 the swift-valkey authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See swift-valkey/CONTRIBUTORS.txt for the list of swift-valkey authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

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
            ]),
        ])
        let token = RESPToken(val)
        let description = try ValkeyClusterDescription(fromRESP: token)

        #expect(description == ValkeyClusterDescription([
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
                        role: .master,
                        replicationOffset: 22,
                        health: .online
                    )
                ]
            )
        ]))
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
                        .bulkString("invalid-health-state"), // Invalid health value
                    ])
                ]),
            ]),
        ])
        let token = RESPToken(val)

        #expect(throws: ValkeyClusterParseError(reason: .invalidNodeHealth, token: token)) {
            _ = try ValkeyClusterDescription(fromRESP: token)
        }
    }

    @Test("Test error handling with invalid token types")
    func testSlotsAreNotAnArray() throws {
        // Non-array token for cluster description
        let singleValueToken = RESPToken(RESP3Value.bulkString("not-an-array"))
        #expect(throws: ValkeyClusterParseError.self) {
            _ = try ValkeyClusterDescription(fromRESP: singleValueToken)
        }
        
        // Non-array token for slots
        let invalidSlotsToken = RESPToken(RESP3Value.array([
            .array([
                .bulkString("slots"),
                .bulkString("not-an-array"), // Should be an array
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
                        .bulkString("online")
                    ])
                ])
            ])
        ]))
        
        #expect(throws: ValkeyClusterParseError(reason: .slotsTokenIsNotAnArray, token: invalidSlotsToken)) {
            try ValkeyClusterDescription(fromRESP: invalidSlotsToken)
        }
        
        // Non-array token for nodes
        let invalidNodesToken = RESPToken(RESP3Value.array([
            .array([
                .bulkString("slots"),
                .array([.number(0), .number(100)]),
                .bulkString("nodes"),
                .bulkString("not-an-array") // Should be an array
            ])
        ]))
        
        #expect(throws: ValkeyClusterParseError(reason: .nodesTokenIsNotAnArray, token: invalidNodesToken)) {
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
                        .bulkString("invalid-role"), // Invalid role
                        .bulkString("replication-offset"),
                        .number(22),
                        .bulkString("health"),
                        .bulkString("invalid-health"), // Invalid health
                    ])
                ])
            ])
        ])
        let token = RESPToken(valWithMultipleErrors)
        
        // The error we expect to see first is the invalid role
        #expect(throws: ValkeyClusterParseError(reason: .invalidNodeRole, token: token)) {
            _ = try ValkeyClusterDescription(fromRESP: token)
        }
    }
}
