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
    "Sentinel Integration Tests",
    .serialized,
    .disabled(if: sentinelHostname == nil || sentinelPort == nil, "VALKEY_SENTINEL_HOSTNAME or VALKEY_SENTINEL_PORT environment variable is not set.")
)
struct SentinelIntegrationTests {
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
            var logger = Logger(label: "testSentinelGetPrimary")
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
}

private let sentinelHostname: String? = ProcessInfo.processInfo.environment["VALKEY_SENTINEL_HOSTNAME"]
private let sentinelPort: Int? = ProcessInfo.processInfo.environment["VALKEY_SENTINEL_PORT"].flatMap { Int($0) }
