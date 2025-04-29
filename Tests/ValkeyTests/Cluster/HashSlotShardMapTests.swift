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
struct HashSlotShardMapTests {

    @Test
    func testShardMap() {
        var map = HashSlotShardMap()

        var shard1 = ValkeyClusterDescription.Shard(
            slots: [0...5, 100...1024],
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
        var shard2 = ValkeyClusterDescription.Shard(
            slots: [12...80],
            nodes: [
                .init(
                    id: "foo2",
                    port: 8,
                    tlsPort: 9,
                    ip: "127.0.0.1",
                    hostname: "mockHostname2",
                    endpoint: "mockEndpoint2",
                    role: .master,
                    replicationOffset: 23,
                    health: .online
                )
            ]
        )
        map.updateCluster([shard1, shard2])

        #expect(map[3] == shard1)
        #expect(map[6] == nil)
        #expect(map[150] == shard1)
        #expect(map[76] == shard2)

        shard1.slots = [16...16, 18...18]
        shard2.slots = [17...17]

        map.updateCluster([shard1, shard2])

        #expect(map[3] == nil)
        #expect(map[16] == shard1)
        #expect(map[17] == shard2)
        #expect(map[18] == shard1)
        #expect(map[150] == nil)
        #expect(map[76] == nil)
    }
}
