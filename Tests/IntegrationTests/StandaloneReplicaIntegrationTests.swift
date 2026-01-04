//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
import Logging
import Testing
import Valkey

@Suite(
    "Standalone Replica Integration Tests",
    .serialized,
    .disabled(if: primaryHostname == nil || primaryPort == nil, "VALKEY_PRIMARY_HOSTNAME or VALKEY_PRIMARY_PORT environment variable is not set.")
)
struct StandaloneReplicaIntegrationTests {
    @available(valkeySwift 1.0, *)
    @Test func testReadonlySelection() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyClient(.hostname(primaryHostname!, port: primaryPort!), logger: logger) { client in
            try await withKey(client) { key in
                // wait 100 milliseconds to ensure ROLE has returned replicas
                try await Task.sleep(for: .milliseconds(100))
                try await client.withConnection(readOnly: true) { connection in
                    _ = try await connection.get(key)
                    await #expect(throws: ValkeyClientError(.commandError, message: "READONLY You can't write against a read only replica.")) {
                        try await connection.set(key, value: "readonly")
                    }
                }
            }
        }
    }

    @available(valkeySwift 1.0, *)
    func withValkeyClient(
        _ address: ValkeyServerAddress,
        configuration: ValkeyClientConfiguration = .init(readOnlyCommandNodeSelection: .cycleReplicas),
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

    @available(valkeySwift 1.0, *)
    func withKey<Value>(_ connection: some ValkeyClientProtocol, _ operation: (ValkeyKey) async throws -> Value) async throws -> Value {
        let key = ValkeyKey(UUID().uuidString)
        let value: Value
        do {
            value = try await operation(key)
        } catch {
            _ = try? await connection.del(keys: [key])
            throw error
        }
        _ = try await connection.del(keys: [key])
        return value
    }
}

private let primaryHostname: String? = ProcessInfo.processInfo.environment["VALKEY_PRIMARY_HOSTNAME"]
private let primaryPort: Int? = ProcessInfo.processInfo.environment["VALKEY_PRIMARY_PORT"].flatMap { Int($0) }
