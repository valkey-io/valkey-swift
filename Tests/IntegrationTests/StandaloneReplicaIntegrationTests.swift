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

@testable import Valkey

@Suite(
    "Standalone Replica Integration Tests",
    .serialized,
    .disabled(if: primaryHostname == nil || primaryPort == nil, "VALKEY_PRIMARY_HOSTNAME or VALKEY_PRIMARY_PORT environment variable is not set.")
)
struct StandaloneReplicaIntegrationTests {
    @available(valkeySwift 1.0, *)
    @Test func testReadonlySelection() async throws {
        let logger = {
            var logger = Logger(label: "Valkey")
            logger.logLevel = .debug
            return logger
        }()
        try await withValkeyClient(.hostname(primaryHostname!, port: primaryPort!), logger: logger) { client in
            try await withKey(client) { key in
                while true {
                    let finished = try await client.withConnection(readOnly: true) { connection in
                        // verify connection is readonly
                        guard await connection.configuration.readOnly else { return false }
                        _ = try await connection.get(key)
                        let error = await #expect(throws: ValkeyClientError.self) {
                            try await connection.set(key, value: "readonly")
                        }
                        #expect(error?.errorCode == .commandError)
                        let errorMessage = try #require(error?.message)
                        #expect(errorMessage.hasPrefix("READONLY") || errorMessage.hasPrefix("REDIRECT") == true)
                        return true
                    }
                    if finished {
                        break
                    }
                    try await Task.sleep(for: .milliseconds(100))
                }
            }
        }
    }

    @available(valkeySwift 1.0, *)
    @Test func testRoleRedirectFromReplica() async throws {
        struct UnexpectedRoleError: Error {}
        var logger = Logger(label: "ValkeyRoleRedirect")
        logger.logLevel = .debug
        // get replica address
        let replicaAddress = try await withValkeyClient(.hostname(primaryHostname!, port: primaryPort!), logger: logger) { client in
            let role = try await client.role()
            switch role {
            case .primary(let primary):
                let replica = try #require(primary.replicas.first)
                return ValkeyServerAddress.hostname(replica.ip, port: replica.port)
            default:
                throw UnexpectedRoleError()
            }
        }

        // connect to replica
        try await withValkeyClient(replicaAddress, logger: logger) { client in
            try await withKey(client) { key in
                // wait 100 milliseconds to ensure ROLE has returned replica status
                try await Task.sleep(for: .milliseconds(200))
                try await client.set(key, value: "redirect")
            }
        }
    }

    @available(valkeySwift 1.0, *)
    @Test func testRedirectErrorFromReplica() async throws {
        struct UnexpectedRoleError: Error {}
        let logger = {
            var logger = Logger(label: "Valkey")
            logger.logLevel = .debug
            return logger
        }()
        // get replica address
        try await withValkeyClient(.hostname(primaryHostname!, port: primaryPort!), logger: logger) { client in
            try await withKey(client) { key in
                let role = try await client.role()
                switch role {
                case .primary(let primary):
                    let replica = try #require(primary.replicas.first)
                    let replicaAddress = ValkeyServerAddress.hostname(replica.ip, port: replica.port)
                    // connect to replica
                    _ = try await withValkeyClient(
                        replicaAddress,
                        configuration: .init(connectToReplica: true),
                        logger: logger
                    ) { client in
                        try await client.set(key, value: "redirect")
                    }
                    let value = try await client.get(key).map { String($0) }
                    #expect(value == "redirect")

                default:
                    throw UnexpectedRoleError()
                }
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testSubscriptions() async throws {
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        var logger = Logger(label: "Subscriptions")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(primaryHostname!, port: primaryPort!), logger: logger) { client in
            // wait 100 milliseconds to ensure ROLE has returned status
            try await Task.sleep(for: .milliseconds(200))
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await client.withConnection { connection in
                        try await connection.subscribe(to: "testSubscriptions") { subscription in
                            cont.finish()
                            var iterator = subscription.makeAsyncIterator()
                            await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "hello" }
                            await #expect(throws: Never.self) { try await iterator.next().map { String($0.message) } == "goodbye" }
                        }
                        #expect(await connection.isSubscriptionsEmpty())
                    }
                }
                try await client.withConnection { connection in
                    await stream.first { _ in true }
                    try await connection.publish(channel: "testSubscriptions", message: "hello")
                    try await connection.publish(channel: "testSubscriptions", message: "goodbye")
                }
                try await group.waitForAll()
            }
        }
    }

    @available(valkeySwift 1.0, *)
    func withValkeyClient<Value>(
        _ address: ValkeyServerAddress,
        configuration: ValkeyClientConfiguration = .init(readOnlyCommandNodeSelection: .cycleReplicas),
        logger: Logger,
        operation: @escaping @Sendable (ValkeyClient) async throws -> Value
    ) async throws -> Value {
        try await withThrowingTaskGroup(of: Void.self) { group in
            let client = ValkeyClient(address, configuration: configuration, logger: logger)
            group.addTask {
                await client.run()
            }
            let value = try await operation(client)
            group.cancelAll()
            return value
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
