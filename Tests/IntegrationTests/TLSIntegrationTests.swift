//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
import Logging
import NIOCore
import NIOSSL
import Testing
import Valkey

@testable import Valkey

@Suite(
    "TLS Integration Tests",
    .disabled(if: disableTLSTests != nil)
)
struct TLSIntegratedTests {
    let valkeyHostname = ProcessInfo.processInfo.environment["VALKEY_HOSTNAME"] ?? "localhost"

    @available(valkeySwift 1.0, *)
    func withKey<Value>(connection: some ValkeyClientProtocol, _ operation: (ValkeyKey) async throws -> Value) async throws -> Value {
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

    @Test
    @available(valkeySwift 1.0, *)
    func testSetGet() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .trace
        let tlsConfiguration = try Self.getTLSConfiguration()
        try await withValkeyClient(
            .hostname(valkeyHostname, port: 6380),
            configuration: .init(tls: .enable(tlsConfiguration, tlsServerName: "Server-only")),
            logger: logger
        ) { connection in
            try await withKey(connection: connection) { key in
                try await connection.set(key, value: "Hello")
                let response = try await connection.get(key).map { String(buffer: $0) }
                #expect(response == "Hello")
                let response2 = try await connection.get("sdf65fsdf").map { String(buffer: $0) }
                #expect(response2 == nil)
            }
        }
    }

    static let rootPath = #filePath
        .split(separator: "/", omittingEmptySubsequences: false)
        .dropLast(3)
        .joined(separator: "/")

    @available(valkeySwift 1.0, *)
    static func getTLSConfiguration() throws -> TLSConfiguration {
        do {
            let rootCertificate = try NIOSSLCertificate.fromPEMFile(Self.rootPath + "/valkey/certs/ca.crt")
            let certificate = try NIOSSLCertificate.fromPEMFile(Self.rootPath + "/valkey/certs/client.crt")
            let privateKey = try NIOSSLPrivateKey(file: Self.rootPath + "/valkey/certs/client.key", format: .pem)
            var tlsConfiguration = TLSConfiguration.makeClientConfiguration()
            tlsConfiguration.trustRoots = .certificates(rootCertificate)
            tlsConfiguration.certificateChain = certificate.map { .certificate($0) }
            tlsConfiguration.privateKey = .privateKey(privateKey)
            return tlsConfiguration
        } catch NIOSSLError.failedToLoadCertificate {
            fatalError("Run script ./dev/generate-test-certs.sh to generate test certificates and restart your valkey server.")
        } catch NIOSSLError.failedToLoadPrivateKey {
            fatalError("Run script ./dev/generate-test-certs.sh to generate test certificates and restart your valkey server.")
        }
    }
}

private let disableTLSTests: String? = ProcessInfo.processInfo.environment["DISABLE_TLS_TESTS"]
