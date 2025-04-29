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

@Suite
struct ValkeyClusterDescriptionTests {

    @Test
    func testClusterDescription() throws {
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
                slotRanges: [0...5],
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



}
