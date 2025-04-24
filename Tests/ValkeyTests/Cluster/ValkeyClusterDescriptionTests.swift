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
                .simpleString(.init(string: "slots")),
                .array([
                    .number(0),
                    .number(5),
                ]),
                .simpleString(.init(string: "nodes")),
                .array([
                    .array([
                        .simpleString(.init(string: "id")),
                        .simpleString(.init(string: "foo")),
                        .simpleString(.init(string: "port")),
                        .number(5),
                        .simpleString(.init(string: "tls-port")),
                        .number(6),
                        .simpleString(.init(string: "ip")),
                        .simpleString(.init(string: "127.0.0.1")),
                        .simpleString(.init(string: "hostname")),
                        .simpleString(.init(string: "mockHostname")),
                        .simpleString(.init(string: "endpoint")),
                        .simpleString(.init(string: "mockEndpoint")),
                        .simpleString(.init(string: "role")),
                        .simpleString(.init(string: "master")),
                        .simpleString(.init(string: "replication-offset")),
                        .number(22),
                        .simpleString(.init(string: "health")),
                        .simpleString(.init(string: "online")),
                    ])
                ]),
            ]),
        ])

        let token = RESPToken(val)

        let description = try ValkeyClusterDescription(respToken: token)

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
