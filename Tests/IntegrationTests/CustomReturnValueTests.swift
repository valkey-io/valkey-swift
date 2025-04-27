//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey open source project
//
// Copyright (c) 2025 Apple Inc. and the swift-valkey project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-valkey project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import Logging
import Testing

@testable import Valkey

struct CustomReturnValueTests {
    let valkeyHostname = ProcessInfo.processInfo.environment["VALKEY_HOSTNAME"] ?? "localhost"
    func withKey<Value>(connection: ValkeyConnection, _ operation: (ValkeyKey) async throws -> Value) async throws -> Value {
        let key = ValkeyKey(rawValue: UUID().uuidString)
        let value: Value
        do {
            value = try await operation(key)
        } catch {
            _ = try? await connection.del(key: [key])
            throw error
        }
        _ = try await connection.del(key: [key])
        return value
    }

    @Test
    func testLPOP() async throws {
        var logger = Logger(label: "LPOP")
        logger.logLevel = .debug
        try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
            try await withKey(connection: connection) { key in
                let count = try await connection.rpush(key: key, element: ["one", "two", "three", "four", "five"])
                #expect(count == 5)
                var values = try await connection.lpop(key: key)
                #expect(values == ["one"])
                values = try await connection.lpop(key: key, count: 3)
                #expect(values == ["two", "three", "four"])
            }
        }
    }

    @Test
    func testRPOP() async throws {
        var logger = Logger(label: "RPOP")
        logger.logLevel = .debug
        try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
            try await withKey(connection: connection) { key in
                let count = try await connection.lpush(key: key, element: ["one", "two", "three", "four", "five"])
                #expect(count == 5)
                var values = try await connection.rpop(key: key)
                #expect(values == ["one"])
                values = try await connection.rpop(key: key, count: 3)
                #expect(values == ["two", "three", "four"])
            }
        }
    }

    @Test
    func testLPOS() async throws {
        var logger = Logger(label: "LPOS")
        logger.logLevel = .debug
        try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
            try await withKey(connection: connection) { key in
                let count = try await connection.rpush(key: key, element: ["a", "b", "c", "1", "2", "3", "c", "c"])
                #expect(count == 8)
                var indices = try await connection.lpos(key: key, element: "c")
                #expect(indices == [2])
                indices = try await connection.lpos(key: key, element: "c", numMatches: 2)
                #expect(indices == [2, 6])
            }
        }
    }
}
