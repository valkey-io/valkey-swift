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

import Foundation
import Logging
import Testing
import XCTest

@testable import Valkey

@Suite(
    "Cluster Integration Tests",
    .serialized,
    .disabled(if: clusterFirstNodeHostname == nil, "VALKEY_NODE1_HOSTNAME environment variable is not set.")
)
struct ClusterIntegrationTests {
    @Test
    @available(valkeySwift 1.0, *)
    func testSetGet() async throws {
        var logger = Logger(label: "ValkeyCluster")
        logger.logLevel = .trace
        let firstNodeHostname = clusterFirstNodeHostname!
        let firstNodePort = clusterFirstNodePort ?? 6379
        try await Self.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort, tls: false)], logger: logger) { client in
            try await Self.withKey(connection: client) { key in
                try await client.set(key, value: "Hello")

                let response = try await client.get(key)
                #expect(response.map { String(buffer: $0) } == "Hello")
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testGetFromReplica() async throws {
        var logger = Logger(label: "ValkeyCluster")
        logger.logLevel = .trace
        let firstNodeHostname = clusterFirstNodeHostname!
        let firstNodePort = clusterFirstNodePort ?? 6379
        try await Self.withValkeyCluster(
            [(host: firstNodeHostname, port: firstNodePort, tls: false)],
            nodeClientConfiguration: .init(readOnlyReplicaSelection: .random),
            logger: logger
        ) { client in
            try await Self.withKey(connection: client) { key in
                try await client.set(key, value: "Hello")
                let hashSlot = HashSlot(key: key)
                let nodeClient = try client.stateLock.withLock { state in
                    if case .healthy(let context) = state.clusterState {
                        let shardID = try context.hashSlotShardMap.nodeIDs(for: [hashSlot])
                        if let pool = state.runningClients[shardID.replicas[0]]?.pool {
                            return pool
                        }
                    }
                    throw ValkeyClusterError.clusterIsMissingMovedErrorNode
                }
                _ = try await nodeClient.withConnection { connection in
                    // TODO: Currently we have to send a READONLY command to a connection before
                    // calling a command that is readonly on a replica, otherwise it'll redirect the user
                    // to the primary. This should be done automatically for the user
                    try await connection.readonly()
                    let response = try await connection.get(key)
                    #expect(response.map { String(buffer: $0) } == "Hello")
                }
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testWithConnection() async throws {
        var logger = Logger(label: "ValkeyCluster")
        logger.logLevel = .trace
        let firstNodeHostname = clusterFirstNodeHostname!
        let firstNodePort = clusterFirstNodePort ?? 6379
        try await Self.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort, tls: false)], logger: logger) { client in
            try await Self.withKey(connection: client) { key in
                try await client.withConnection(forKeys: [key]) { connection in
                    _ = try await connection.set(key, value: "Hello")
                    let response = try await connection.get(key)
                    #expect(response.map { String(buffer: $0) } == "Hello")
                }
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testFailover() async throws {
        var logger = Logger(label: "ValkeyCluster")
        logger.logLevel = .trace
        let firstNodeHostname = clusterFirstNodeHostname!
        let firstNodePort = clusterFirstNodePort ?? 6379
        try await Self.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort, tls: false)], logger: logger) { clusterClient in
            try await Self.withKey(connection: clusterClient) { key in
                try await clusterClient.set(key, value: "bar")
                let cluster = try await clusterClient.clusterShards()
                let shard = try #require(
                    cluster.shards.first { shard in
                        let hashSlot = HashSlot(key: key)
                        return shard.slots[0].lowerBound <= hashSlot && shard.slots[0].upperBound >= hashSlot
                    }
                )
                let replica = try #require(shard.nodes.first { $0.role == .replica })
                let port = try #require(replica.port)
                // connect to replica and call CLUSTER FAILOVER
                try await withValkeyClient(.hostname(replica.endpoint, port: port), logger: logger) { client in
                    try await client.clusterFailover()
                }
                try await clusterClient.set(key, value: "baz")
                let response = try await clusterClient.get(key)
                #expect(response.map { String(buffer: $0) } == "baz")
            }
        }
    }

    @available(valkeySwift 1.0, *)
    static func withKey<Value>(
        connection: some ValkeyClientProtocol,
        _ operation: (ValkeyKey) async throws -> Value
    ) async throws -> Value {
        let key = ValkeyKey(UUID().uuidString)
        let result: Result<Value, any Error>
        do {
            result = try await .success(operation(key))
        } catch {
            result = .failure(error)
        }
        try await connection.del(keys: [key])
        return try result.get()
    }

    @available(valkeySwift 1.0, *)
    static func withValkeyCluster<T>(
        _ nodeAddresses: [(host: String, port: Int, tls: Bool)],
        nodeClientConfiguration: ValkeyClientConfiguration = .init(),
        logger: Logger,
        _ body: (ValkeyClusterClient) async throws -> sending T
    ) async throws -> T {
        let client = ValkeyClusterClient(
            clientConfiguration: nodeClientConfiguration,
            nodeDiscovery: ValkeyStaticNodeDiscovery(nodeAddresses.map { .init(host: $0.host, port: $0.port, useTLS: $0.tls) }),
            logger: logger
        )

        let result = await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await client.run()
            }

            let result: Result<T, any Error>
            do {
                result = try await .success(body(client))
            } catch {
                result = .failure(error)
            }

            group.cancelAll()
            return result
        }

        return try result.get()
    }

    @available(valkeySwift 1.0, *)
    func withValkeyClient(
        _ address: ValkeyServerAddress,
        configuration: ValkeyClientConfiguration = .init(),
        logger: Logger,
        operation: @escaping @Sendable (ValkeyClient) async throws -> Void
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            let client = ValkeyClient(address, configuration: configuration, logger: logger)
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
}

private let clusterFirstNodeHostname: String? = ProcessInfo.processInfo.environment["VALKEY_NODE1_HOSTNAME"]
private let clusterFirstNodePort: Int? = ProcessInfo.processInfo.environment["VALKEY_NODE1_PORT"].flatMap { Int($0) }
