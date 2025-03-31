//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-redis open source project
//
// Copyright (c) 2025 Apple Inc. and the swift-redis project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-redis project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import Logging
import Redis
import RedisCommands
import Testing

@testable import Redis

struct GeneratedCommands {
    let redisHostname = ProcessInfo.processInfo.environment["REDIS_HOSTNAME"] ?? "localhost"
    func withKey<Value>(connection: RedisConnection, _ operation: (RedisKey) async throws -> Value) async throws -> Value {
        let key = RedisKey(rawValue: UUID().uuidString)
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
    func testRedisCommand() async throws {
        struct GET: RedisCommand {
            typealias Response = String?

            var key: RedisKey

            init(key: RedisKey) {
                self.key = key
            }

            func encode(into commandEncoder: inout RedisCommandEncoder) {
                commandEncoder.encodeRESPArray("GET", key)
            }
        }
        var logger = Logger(label: "Redis")
        logger.logLevel = .debug
        try await RedisClient(.hostname(redisHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
            try await withKey(connection: connection) { key in
                _ = try await connection.set(key: key, value: "Hello")
                let response = try await connection.send(command: GET(key: key))
                #expect(response == "Hello")
            }
        }
    }

    @Test
    func testSetGet() async throws {
        var logger = Logger(label: "Redis")
        logger.logLevel = .debug
        try await RedisClient(.hostname(redisHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
            try await withKey(connection: connection) { key in
                _ = try await connection.set(key: key, value: "Hello")
                let response = try await connection.get(key: key)
                #expect(response == "Hello")
            }
        }
    }

    @Test
    func testUnixTime() async throws {
        var logger = Logger(label: "Redis")
        logger.logLevel = .debug
        try await RedisClient(.hostname(redisHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
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
        var logger = Logger(label: "Redis")
        logger.logLevel = .debug
        try await RedisClient(.hostname(redisHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
            try await withKey(connection: connection) { key in
                let responses = try await connection.pipeline(
                    SET(key: key, value: "Pipelined Hello"),
                    GET(key: key)
                )
                let value = try responses[1].converting(to: String.self)
                #expect(value == "Pipelined Hello")
            }
        }
    }

    @Test
    func testSingleElementArray() async throws {
        var logger = Logger(label: "Redis")
        logger.logLevel = .debug
        try await RedisClient(.hostname(redisHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
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
        var logger = Logger(label: "Redis")
        logger.logLevel = .debug
        try await RedisClient(.hostname(redisHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
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
        var logger = Logger(label: "Redis")
        logger.logLevel = .debug
        try await RedisClient(.hostname(redisHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
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
        var logger = Logger(label: "Redis")
        logger.logLevel = .debug
        try await RedisClient(.hostname(redisHostname, port: 6379), logger: logger).withConnection(logger: logger) { connection in
            try await withKey(connection: connection) { key in
                try await withKey(connection: connection) { key2 in
                    _ = try await connection.lpush(key: key, element: ["a"])
                    _ = try await connection.lpush(key: key2, element: ["b"])
                    let rt1: [RESPToken] = try await connection.lmpop(key: [key, key2], where: .left)!
                    let keyReturned1 = try RedisKey(from: rt1[0])
                    let values1 = try [String](from: rt1[1])
                    #expect(keyReturned1 == key)
                    #expect(values1.first == "a")
                    let rt2: [RESPToken] = try await connection.lmpop(key: [key, key2], where: .left)!
                    let keyReturned2 = try RedisKey(from: rt2[0])
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
            var logger = Logger(label: "Redis")
            logger.logLevel = .debug
            group.addTask {
                try await RedisClient(.hostname("localhost", port: 6379), logger: logger).withConnection(logger: logger) { connection in
                    _ = try await connection.subscribe(channel: "subscribe")
                    for try await message in connection.subscriptions {
                        try print(message.converting(to: [String].self))
                        break
                    }
                }
            }
            group.addTask {
                try await RedisClient(.hostname("localhost", port: 6379), logger: logger).withConnection(logger: logger) { connection in
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
