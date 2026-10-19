//
// This source file is part of the valkey-swift project
// Copyright (c) 2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
import Logging
import Synchronization
import Testing

@testable import Valkey

@Suite(
    "Sentinel Integration Tests",
    .serialized,
    .disabled(if: sentinelHostname == nil || sentinelPort == nil, "VALKEY_SENTINEL_HOSTNAME or VALKEY_SENTINEL_PORT environment variable is not set.")
)
struct SentinelIntegrationTests {
    @available(valkeySwift 1.0, *)
    func withValkeyClient(
        primaryName: String,
        configuration: ValkeyClientConfiguration = .init(),
        logger: Logger,
        operation: @escaping @Sendable (ValkeyClient) async throws -> Void
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            let client = ValkeyClient(
                primaryName: primaryName,
                sentinelNodeDiscovery: ValkeyStaticNodeDiscovery([.init(endpoint: sentinelHostname!, port: sentinelPort!)]),
                configuration: configuration,
                logger: logger
            )
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

    @Test
    @available(valkeySwift 1.0, *)
    func testSentinelGetPrimary() async throws {
        let logger = {
            var logger = Logger(label: "testSentinelGetPrimary")
            logger.logLevel = .trace
            return logger
        }()
        let sentinelClient = ValkeySentinelClient(
            primaryName: "testprimary",
            nodeDiscovery: ValkeyStaticNodeDiscovery([.init(endpoint: sentinelHostname!, port: sentinelPort!)]),
            configuration: .init(clientConfiguration: .init()),
            logger: logger
        )
        async let _ = sentinelClient.run()
        let nodes = try await sentinelClient.getNodes()
        #expect(nodes.primary == .hostname("127.0.0.1", port: 9000))
        #expect(nodes.replicas.contains(where: { $0 == .hostname("127.0.0.1", port: 9001) }))
        #expect(nodes.replicas.contains(where: { $0 == .hostname("127.0.0.1", port: 9002) }))
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testSentinelUnknownPrimary() async throws {
        let logger = {
            var logger = Logger(label: "testSentinelUnknownPrimary")
            logger.logLevel = .trace
            return logger
        }()
        let sentinelClient = ValkeySentinelClient(
            primaryName: "unknown-primary",
            nodeDiscovery: ValkeyStaticNodeDiscovery([.init(endpoint: sentinelHostname!, port: sentinelPort!)]),
            configuration: .init(clientConfiguration: .init()),
            logger: logger
        )
        async let _ = sentinelClient.run()
        await #expect(throws: ValkeySentinelError.sentinelUnknownPrimary) {
            _ = try await sentinelClient.getNodes()
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testClient() async throws {
        let logger = {
            var logger = Logger(label: "testClientWithSentinel")
            logger.logLevel = .trace
            return logger
        }()
        try await self.withValkeyClient(primaryName: "testprimary", logger: logger) { client in
            _ = try await self.withKey(client) { (key: ValkeyKey) in
                try await client.set(key, value: "testClient")
                let value = try await client.get(key).map { String($0) }
                #expect(value == "testClient")
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testClientUnknownPrimaryName() async throws {
        let logger = {
            var logger = Logger(label: "testClientWithSentinel")
            logger.logLevel = .trace
            return logger
        }()
        try await self.withValkeyClient(primaryName: "testUnknownPrimary", logger: logger) { client in
            var error = await #expect(throws: ValkeyClientError.self) {
                try await client.info()
            }
            #expect(error?.errorCode == .sentinelError)
            let sentinelError = try #require(error?.underlyingError as? ValkeySentinelError)
            #expect(sentinelError == .sentinelUnknownPrimary)
            error = await #expect(throws: ValkeyClientError.self) {
                try await client.info()
            }
            #expect(error?.errorCode == .sentinelError)
        }
    }
}

private let sentinelHostname: String? = ProcessInfo.processInfo.environment["VALKEY_SENTINEL_HOSTNAME"]
private let sentinelPort: Int? = ProcessInfo.processInfo.environment["VALKEY_SENTINEL_PORT"].flatMap { Int($0) }
