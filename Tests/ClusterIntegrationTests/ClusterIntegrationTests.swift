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
import Valkey

struct ClusterIntegrationTests {

    @Test(.disabled(if: ClusterIntegrationTests.firstNodeHostname == nil, "VALKEY_NODE1_HOSTNAME environment variable is not set."))
    @available(valkeySwift 1.0, *)
    func testSetGet() async throws {
        var logger = Logger(label: "ValkeyCluster")
        logger.logLevel = .trace
        let firstNodeHostname = ClusterIntegrationTests.firstNodeHostname!
        let firstNodePort = ClusterIntegrationTests.firstNodePort ?? 6379
        try await Self.withValkeyCluster([(host: firstNodeHostname, port: firstNodePort, tls: false)]) { (client, logger) in
            try await Self.withKey(connection: client) { key in
                _ = try await client.set(key, value: "Hello")

                let response = try await client.get(key)
                #expect(response.map { String(buffer: $0) } == "Hello")
            }
        }
    }

    @available(valkeySwift 1.0, *)
    static func withKey<Value>(
        connection: some ValkeyConnectionProtocol,
        _ operation: (ValkeyKey) async throws -> Value
    ) async throws -> Value {
        let key = ValkeyKey(UUID().uuidString)
        let result: Result<Value, any Error>
        do {
            result = try await .success(operation(key))
        } catch {
            result = .failure(error)
        }
        _ = try await connection.del(key: [key])
        return try result.get()
    }

    @available(valkeySwift 1.0, *)
    static func withValkeyCluster<T>(
        _ nodeAddresses: [(host: String, port: Int, tls: Bool)],
        nodeClientConfiguration: ValkeyClientConfiguration = .init(),
        _ body: (ValkeyClusterClient, Logger) async throws -> sending T
    ) async throws -> T {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
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
                result = try await .success(body(client, logger))
            } catch {
                result = .failure(error)
            }

            group.cancelAll()
            return result
        }

        return try result.get()
    }

}

extension ClusterIntegrationTests {
    static var firstNodeHostname: String? {
        ProcessInfo.processInfo.environment["VALKEY_NODE1_HOSTNAME"]
    }

    static var firstNodePort: Int? {
        ProcessInfo.processInfo.environment["VALKEY_NODE1_PORT"].flatMap { Int($0) }
    }
}
