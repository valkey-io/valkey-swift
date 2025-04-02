//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey open source project
//
// Copyright (c) 2025 the swift-valkey project authors
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
import Valkey

@testable import Valkey

struct GeneratedCommands {
    let valkeyHostname = ProcessInfo.processInfo.environment["VALKEY_HOSTNAME"] ?? "localhost"
    func withKey<Value>(connection: ValkeyConnection, _ operation: (RESPKey) async throws -> Value) async throws -> Value {
        let key = RESPKey(rawValue: UUID().uuidString)
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
    func testValkeyCommand() async throws {
        struct GET: RESPCommand {
            typealias Response = String?

            var key: RESPKey

            init(key: RESPKey) {
                self.key = key
            }

            func encode(into commandEncoder: inout RESPCommandEncoder) {
                commandEncoder.encodeArray("GET", key)
            }
        }
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
            try await withKey(connection: connection) { key in
                _ = try await connection.set(key: key, value: "Hello")
                let response = try await connection.send(command: GET(key: key))
                #expect(response == "Hello")
            }
        }
    }

    @Test
    func testSetGet() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
            try await withKey(connection: connection) { key in
                _ = try await connection.set(key: key, value: "Hello")
                let response = try await connection.get(key: key)
                #expect(response == "Hello")
            }
        }
    }

    @Test
    func testUnixTime() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
            try await withKey(connection: connection) { key in
                _ = try await connection.set(key: key, value: "Hello", expiration: .unixTimeMilliseconds(.now + 1))
                let response = try await connection.get(key: key)
                #expect(response == "Hello")
                try await Task.sleep(for: .seconds(2))
                let response2 = try await connection.get(key: key)
                #expect(response2 == nil)
            }
        }
    }

    @Test
    func testPipelinedSetGet() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
            try await withKey(connection: connection) { key in
                let responses = try await connection.pipeline(
                    SET(key: key, value: "Pipelined Hello"),
                    GET(key: key)
                )
                #expect(responses.1 == "Pipelined Hello")
            }
        }
    }

    @Test
    func testSingleElementArray() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
            try await withKey(connection: connection) { key in
                _ = try await connection.rpush(key: key, element: ["Hello"])
                _ = try await connection.rpush(key: key, element: ["Good", "Bye"])
                let values: [String] = try await connection.lrange(key: key, start: 0, stop: -1).converting()
                #expect(values == ["Hello", "Good", "Bye"])
            }
        }
    }

    @Test
    func testCommandWithMoreThan9Strings() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
            try await withKey(connection: connection) { key in
                let count = try await connection.rpush(key: key, element: ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"])
                #expect(count == 10)
                let values: [String] = try await connection.lrange(key: key, start: 0, stop: -1).converting()
                #expect(values == ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"])
            }
        }
    }

    @Test
    func testSort() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
            try await withKey(connection: connection) { key in
                _ = try await connection.lpush(key: key, element: ["a"])
                _ = try await connection.lpush(key: key, element: ["c"])
                _ = try await connection.lpush(key: key, element: ["b"])
                let list = try await connection.sort(key: key, sorting: true).converting(to: [String].self)
                #expect(list == ["a", "b", "c"])
            }
        }
    }

    @Test("Array with count using LMPOP")
    func testArrayWithCount() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await ValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
            try await withKey(connection: connection) { key in
                try await withKey(connection: connection) { key2 in
                    _ = try await connection.lpush(key: key, element: ["a"])
                    _ = try await connection.lpush(key: key2, element: ["b"])
                    let rt1: [RESPToken] = try await connection.lmpop(key: [key, key2], where: .left)!
                    let keyReturned1 = try RESPKey(from: rt1[0])
                    let values1 = try [String](from: rt1[1])
                    #expect(keyReturned1 == key)
                    #expect(values1.first == "a")
                    let rt2: [RESPToken] = try await connection.lmpop(key: [key, key2], where: .left)!
                    let keyReturned2 = try RESPKey(from: rt2[0])
                    let values2 = try [String](from: rt2[1])
                    #expect(keyReturned2 == key2)
                    #expect(values2.first == "b")
                }
            }
        }
    }

    /*
    @Test
    func testSubscriptions() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            var logger = Logger(label: "Valkey")
            logger.logLevel = .debug
            group.addTask {
                try await ValkeyClient(.hostname("localhost", port: 6379), logger: logger).withConnection(logger: logger) { connection in
                    _ = try await connection.subscribe(channel: "subscribe")
                    for try await message in connection.subscriptions {
                        try print(message.converting(to: [String].self))
                        break
                    }
                }
            }
            group.addTask {
                try await ValkeyClient(.hostname("localhost", port: 6379), logger: logger).withConnection(logger: logger) { connection in
                    while true {
                        let subscribers = try await connection.pubsubNumsub(channel: "subscribe")
                        if try subscribers[1].converting(to: Int.self) > 0 { break }
                        try await Task.sleep(for: .microseconds(50))
                    }
                    _ = try await connection.publish(channel: "subscribe", message: "hello")
                }
            }
            try await group.waitForAll()
        }
    }*/
}
