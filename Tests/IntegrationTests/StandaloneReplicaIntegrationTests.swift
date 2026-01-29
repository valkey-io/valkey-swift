//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
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
                        guard case .hostname(_, let port) = connection.address.value, port != primaryPort else {
                            return false
                        }
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
        let logger = {
            var logger = Logger(label: "testRoleRedirectFromReplica")
            logger.logLevel = .trace
            return logger
        }()
        try await withValkeyClient(.hostname(primaryHostname!, port: primaryPort!), logger: logger) { client in
            // get replica address
            let replicaAddress = try #require(try await getReplicaAddresses(client).first)
            // connect to replica
            try await withValkeyClient(replicaAddress, logger: logger) { client in
                try await withKey(client) { key in
                    // wait 200 milliseconds to ensure ROLE has returned replica status
                    try await Task.sleep(for: .milliseconds(200))
                    try await client.set(key, value: "redirect")
                }
            }
        }
    }

    @available(valkeySwift 1.0, *)
    @Test func testRedirectErrorFromReplica() async throws {
        let logger = {
            var logger = Logger(label: "testRedirectErrorFromReplica")
            logger.logLevel = .trace
            return logger
        }()
        try await withValkeyClient(.hostname(primaryHostname!, port: primaryPort!), logger: logger) { client in
            // only run this test on valkey
            guard try await client.hello(arguments: .init(protover: 3)).decodeValues("server") == "valkey" else { return }
            try await withKey(client) { key in
                // get replica address
                let replicaAddress = try #require(try await getReplicaAddresses(client).first)
                // connect to replica. We set the value `connectToReplica` to true so we are not immediately
                // redirected to the primary by the role command
                _ = try await withValkeyClient(
                    replicaAddress,
                    configuration: .init(connectingToReplica: true),
                    logger: logger
                ) { client in
                    // we called a non-readonly command. This should work because we will receive a REDIRECT error
                    try await client.set(key, value: "redirect")
                }
                let value = try await client.get(key).map { String($0) }
                #expect(value == "redirect")
            }
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testFailover() async throws {
        let logger = {
            var logger = Logger(label: "testFailover")
            logger.logLevel = .trace
            return logger
        }()
        try await withValkeyClient(.hostname(primaryHostname!, port: primaryPort!), logger: logger) { client in
            // only run this test on valkey
            guard try await client.hello(arguments: .init(protover: 3)).decodeValues("server") == "valkey" else { return }
            try await withKey(client) { key in
                _ = try await withFailover(client) {
                    // we called a non-readonly command. This should work because we will receive a REDIRECT error
                    try await client.set(key, value: "redirect")
                }
                let value = try await client.get(key).map { String($0) }
                #expect(value == "redirect")
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
    func withFailover<Value>(_ client: ValkeyClient, operation: () async throws -> Value) async throws -> Value {
        // get primary address
        let (host, port) = client.stateMachine.withLock {
            guard case .running(let nodes) = $0.state else { fatalError("Expected a running primary node") }
            guard case .hostname(let host, let port) = nodes.primary.value else { fatalError("Expected a hostname") }
            return (host, port)
        }
        // extract replica address
        let replicaAddresses = try await getReplicaAddresses(client)
        let replicaAddress = try #require(replicaAddresses.first)
        guard case .hostname(let replicaHost, let replicaPort) = replicaAddress.value else { fatalError("Expected a hostname") }

        try await client.failover(target: .init(host: replicaHost, port: replicaPort))
        let result: Result<Value, Error>
        do {
            let value = try await operation()
            result = .success(value)
        } catch {
            result = .failure(error)
        }
        // revert to original setup. Run a failover and then call replicaof
        try await withValkeyClient(replicaAddress, logger: client.logger) { replicaClient in
            try await replicaClient.failover(target: .init(host: host, port: port))
        }
        for replica in replicaAddresses {
            guard replica != replicaAddress else { continue }
            try await withValkeyClient(replica, logger: client.logger) { replicaClient in
                _ = try await replicaClient.replicaof(args: .hostPort(.init(host: host, port: port)))
            }

        }
        return try result.get()
    }

    @available(valkeySwift 1.0, *)
    func getReplicaAddresses(_ client: ValkeyClient) async throws -> [ValkeyServerAddress] {
        struct UnexpectedRoleError: Error {}
        var logger = Logger(label: "GetReplicaAddress")
        logger.logLevel = .debug
        // get replica address
        let role = try await client.role()
        switch role {
        case .primary(let primary):
            return primary.replicas.map { ValkeyServerAddress.hostname($0.ip, port: $0.port) }
        default:
            throw UnexpectedRoleError()
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
