//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 Apple Inc. and the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of valkey-swift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Valkey
import Testing
import Logging
import Foundation

struct ClusterIntegrationTests {

    @Test(.disabled(if: ClusterIntegrationTests.isInCI))
    @available(valkeySwift 1.0, *)
    func testSetGet() async throws {
        var logger = Logger(label: "ValkeyCluster")
        logger.logLevel = .trace
        try await Self.withValkeyCluster([(host: "192.168.64.2", port: 36001, tls: false)]) { (client, logger) in
            try await Self.withKey(connection: client) { key in
                _ = try await client.set(key: key, value: "Hello")

                let response = try await client.get(key: key)
                #expect(try String(fromRESP: response!) == "Hello")
            }
        }
    }

    @available(valkeySwift 1.0, *)
    static func withKey<Value>(
        connection: some ValkeyConnectionProtocol,
        _ operation: (ValkeyKey) async throws -> Value
    ) async throws -> Value {
        let key = ValkeyKey(rawValue: UUID().uuidString)
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
    static var isInCI: Bool {
        ProcessInfo.processInfo.environment["CI"] == "true"
    }
}
