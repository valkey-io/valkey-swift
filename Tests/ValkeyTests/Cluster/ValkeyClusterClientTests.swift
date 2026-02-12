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

actor Cluster {
    enum Role {
        case primary
        case replica
    }
    struct Address: Hashable, CustomStringConvertible {
        let host: String
        let port: Int

        var description: String { "\(host):\(port)" }
    }
    struct Shard {
        let hashKeyRanges: [ClosedRange<UInt16>]
        let primary: Address
        let replicas: [Address]

        var respValue: RESP3Value {
            let hashKeyArray: RESP3Value = .array(self.hashKeyRanges.flatMap { [.number(Int64($0.first!)), .number(Int64($0.last!))] })
            var nodes: [RESP3Value] = [
                .map([
                    .bulkString("id"): .bulkString(String(primary.hashValue)),
                    .bulkString("port"): .number(Int64(primary.port)),
                    .bulkString("ip"): .bulkString(primary.host),
                    .bulkString("endpoint"): .bulkString(primary.host),
                    .bulkString("role"): .bulkString("master"),
                    .bulkString("replication-offset"): .number(70000),
                    .bulkString("health"): .bulkString("online"),
                ])
            ]
            for replica in replicas {
                nodes.append(
                    .map([
                        .bulkString("id"): .bulkString(String(replica.hashValue)),
                        .bulkString("port"): .number(Int64(replica.port)),
                        .bulkString("ip"): .bulkString(replica.host),
                        .bulkString("endpoint"): .bulkString(replica.host),
                        .bulkString("role"): .bulkString("replica"),
                        .bulkString("replication-offset"): .number(70000),
                        .bulkString("health"): .bulkString("online"),
                    ])
                )
            }
            return .map([
                .bulkString("slots"): hashKeyArray,
                .bulkString("nodes"): .array(nodes),
            ])

        }
    }
    var shards: [Shard] {
        didSet {
            self.updateAddressMap()
        }
    }
    private(set) var addressMap: [Address: (role: Role, shardIndex: Int)]

    init(shards: [Shard]) async {
        self.addressMap = [:]
        self.shards = shards
        self.updateAddressMap()
    }

    func updateAddressMap() {
        self.addressMap = [:]
        for index in self.shards.indices {
            let shard = self.shards[index]
            self.addressMap[shard.primary] = (.primary, index)
            for replica in shard.replicas {
                self.addressMap[replica] = (.replica, index)
            }
        }
    }

    func getShard(_ hashSlot: HashSlot) -> (index: Int, shard: Shard)? {
        for index in shards.indices {
            for keyRange in self.shards[index].hashKeyRanges {
                if keyRange.contains(hashSlot.rawValue) {
                    return (index, self.shards[index])
                }
            }
        }
        return nil
    }

    func mock(logger: Logger) async -> MockServerConnections {
        let mockConnections = MockServerConnections(logger: logger)
        for address in self.addressMap {
            await mockConnections.addValkeyServer(.hostname(address.key.host, port: address.key.port)) { command in
                var iterator = command.makeIterator()
                switch iterator.next() {
                case "GET":
                    guard let key = iterator.next() else { return RESPToken(.bulkError("ERR invalid command")) }
                    guard let shard = await self.getShard(HashSlot(key: key.utf8)) else { return RESPToken(.null) }
                    if shard.index != address.value.shardIndex {
                        return RESPToken(.bulkError("MOVE \(shard.shard.primary)"))
                    }
                    if key.hasPrefix("address") {
                        return RESPToken(.bulkString(address.key.description))
                    }
                    return RESPToken(.null)
                case "SET":
                    guard let key = iterator.next() else { return RESPToken(.bulkError("ERR invalid command")) }
                    guard let _ = iterator.next() else { return RESPToken(.bulkError("ERR invalid command")) }
                    guard let shard = await self.getShard(HashSlot(key: key.utf8)) else { return RESPToken(.null) }
                    if shard.index != address.value.shardIndex || address.value.role == .replica {
                        return RESPToken(.bulkError("MOVE \(shard.shard.primary)"))
                    }
                    if key.hasPrefix("address") {
                        return RESPToken(.bulkString(address.key.description))
                    }
                    return RESPToken(.null)
                case "CLUSTER":
                    switch iterator.next() {
                    case "SHARDS":
                        return await RESPToken(
                            .array(self.shards.map { $0.respValue })
                        )
                    default:
                        return nil
                    }
                default:
                    return nil
                }
            }
        }
        return mockConnections
    }
}

@Suite("Test ValkeyClusterClient using mock cluster")
struct ValkeyClusterClientTests {
    @available(valkeySwift 1.0, *)
    func withValkeyClusterClient(
        _ address: (host: String, port: Int),
        mockConnections: MockServerConnections,
        configuration: ValkeyClientConfiguration = .init(readOnlyCommandNodeSelection: .cycleReplicas),
        logger: Logger,
        operation: @escaping @Sendable (ValkeyClusterClient) async throws -> Void
    ) async throws {
        let client = ValkeyClusterClient(
            clientConfiguration: configuration,
            nodeDiscovery: ValkeyStaticNodeDiscovery([.init(endpoint: address.host, port: address.port)]),
            eventLoopGroup: mockConnections.eventLoop,
            logger: logger,
            channelFactory: mockConnections.connectionManagerCustomHandler
        )

        return try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                await client.run()
            }
            group.addTask {
                try await operation(client)
            }
            try await group.next()
            group.cancelAll()
        }
    }

    @available(valkeySwift 1.0, *)
    @Test
    func testGetSet() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        let cluster = await Cluster(shards: [
            Cluster.Shard(
                hashKeyRanges: [0...5460],
                primary: .init(host: "127.0.0.1", port: 16000),
                replicas: [.init(host: "127.0.0.1", port: 16001)]
            ),
            Cluster.Shard(
                hashKeyRanges: [5461...10922],
                primary: .init(host: "127.0.0.1", port: 16002),
                replicas: [.init(host: "127.0.0.1", port: 16003)]
            ),
            Cluster.Shard(
                hashKeyRanges: [10923...16383],
                primary: .init(host: "127.0.0.1", port: 16004),
                replicas: [.init(host: "127.0.0.1", port: 16005)]
            ),
        ])
        let mockConnections = await cluster.mock(logger: logger)
        async let _ = mockConnections.run()
        try await withValkeyClusterClient((host: "127.0.0.1", port: 16000), mockConnections: mockConnections, logger: logger) { client in
            var value = try await client.get("address{1}")
            #expect(value.map { String($0) } == "127.0.0.1:16003")
            value = try await client.set("address{1}", value: "test")
            #expect(value.map { String($0) } == "127.0.0.1:16002")
            value = try await client.get("address{3}")
            #expect(value.map { String($0) } == "127.0.0.1:16001")
            value = try await client.set("address{3}", value: "test")
            #expect(value.map { String($0) } == "127.0.0.1:16000")
            value = try await client.get("address{4}")
            #expect(value.map { String($0) } == "127.0.0.1:16005")
            value = try await client.set("address{4}", value: "test")
            #expect(value.map { String($0) } == "127.0.0.1:16004")
        }
    }
}
