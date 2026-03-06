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
        let primaryAddress = try await sentinelClient.getPrimaryNode()
        #expect(primaryAddress == .hostname("127.0.0.1", port: 9000))
    }
}

private let sentinelHostname: String? = ProcessInfo.processInfo.environment["VALKEY_SENTINEL_HOSTNAME"]
private let sentinelPort: Int? = ProcessInfo.processInfo.environment["VALKEY_SENTINEL_PORT"].flatMap { Int($0) }
