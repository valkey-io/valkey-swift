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
        sentinelNodeDiscovery: some ValkeyNodeDiscovery = ValkeyStaticNodeDiscovery([.init(endpoint: sentinelHostname!, port: sentinelPort!)]),
        configuration: ValkeyClientConfiguration = .init(),
        logger: Logger,
        operation: @escaping @Sendable (ValkeyClient) async throws -> Void
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            let client = ValkeyClient(
                primaryName: primaryName,
                sentinelNodeDiscovery: sentinelNodeDiscovery,
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
        let ports: Set<Int> = .init(
            ([nodes.primary] + nodes.replicas).map {
                switch $0.value {
                case .hostname(_, let port): port
                default: fatalError()
                }
            }
        )
        #expect(ports == [9000, 9001, 9002])
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
        try await self.withValkeyClient(
            primaryName: "testprimary",
            logger: logger
        ) { client in
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
        try await self.withValkeyClient(
            primaryName: "testUnknownPrimary",
            configuration: .init(connectionPool: .init(circuitBreakerTripAfter: .seconds(1))),
            logger: logger
        ) { client in
            let error = await #expect(throws: ValkeyClientError.self) {
                try await client.info()
            }
            #expect(error?.errorCode == .connectionCreationCircuitBreakerTripped)
            // TODO: pass underlying error back to client
            /*let sentinelError = try #require(error?.underlyingError as? ValkeySentinelError)
            #expect(sentinelError == .sentinelUnknownPrimary)*/
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testClientUnknownSentinel() async throws {
        let logger = {
            var logger = Logger(label: "testClientWithSentinel")
            logger.logLevel = .trace
            return logger
        }()
        try await self.withValkeyClient(
            primaryName: "testUnknownPrimary",
            sentinelNodeDiscovery: ValkeyStaticNodeDiscovery([.init(endpoint: "127.0.0.1", port: 16383)]),
            configuration: .init(connectionPool: .init(circuitBreakerTripAfter: .seconds(1))),
            logger: logger
        ) { client in
            let error = await #expect(throws: ValkeyClientError.self) {
                try await client.info()
            }
            #expect(error?.errorCode == .connectionCreationCircuitBreakerTripped)
            // TODO: pass underlying error back to client
            /*let sentinelClientError = try #require(error?.underlyingError as? ValkeyClientError)
            #expect(sentinelClientError.errorCode == .sentinelError)
            let sentinelError = try #require(sentinelClientError.underlyingError as? ValkeySentinelError)
            #expect(sentinelError == .sentinelNoConsensusReached)*/
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testClientSentinelFailover() async throws {
        let logger = {
            var logger = Logger(label: "testClientWithSentinel")
            logger.logLevel = .trace
            return logger
        }()
        try await self.withValkeyClient(primaryName: "testprimary", configuration: .init(enableClientCapaRedirect: false), logger: logger) { client in
            _ = try await self.withKey(client) { (key: ValkeyKey) in
                try await client.set(key, value: "testClientSentinelFailover")
                let sentinelClient = ValkeyClient(.hostname(sentinelHostname!, port: sentinelPort!), logger: logger)
                async let _ = sentinelClient.run()
                let addr = try await sentinelClient.sentinelGetPrimaryAddrByName(primaryName: "testprimary").decodeElements(as: (String, Int).self)
                try await sentinelClient.sentinelFailover(primaryName: "testprimary", coordinated: true)
                while true {
                    let newAddr = try await sentinelClient.sentinelGetPrimaryAddrByName(primaryName: "testprimary").decodeElements(
                        as: (String, Int).self
                    )
                    if newAddr != addr {
                        break
                    }
                    try await Task.sleep(for: .seconds(1))
                }
                try await client.set(key, value: "testClientSentinelFailover2")
                let value = try await client.get(key).map { String($0) }
                #expect(value == "testClientSentinelFailover2")
            }
        }
    }
}

private let sentinelHostname: String? = ProcessInfo.processInfo.environment["VALKEY_SENTINEL_HOSTNAME"]
private let sentinelPort: Int? = ProcessInfo.processInfo.environment["VALKEY_SENTINEL_PORT"].flatMap { Int($0) }
