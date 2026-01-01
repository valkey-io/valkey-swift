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
    .disabled(if: firstReplicaHostname == nil, "VALKEY_REPLICA1_HOSTNAME environment variable is not set.")
)
struct StandaloneReplicaIntegrationTests {

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

private let firstReplicaHostname: String? = ProcessInfo.processInfo.environment["VALKEY_REPLICA1_HOSTNAME"]
private let firstReplicaPort: Int? = ProcessInfo.processInfo.environment["VALKEY_REPLICA1_PORT"].flatMap { Int($0) }
