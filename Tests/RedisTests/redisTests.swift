import Foundation
import Logging
import RESP3
import Testing

@testable import Redis

struct GeneratedCommands {
    func withKey<Value>(connection: RedisConnection, _ operation: (RedisKey) async throws -> Value) async throws -> Value {
        let key = RedisKey(rawValue: UUID().uuidString)
        let value: Value
        do {
            value = try await operation(key)
        } catch {
            _ = try? await connection.send("DEL", key)
            throw error
        }
        _ = try await connection.send("DEL", key)
        return value
    }

    @Test
    func testSetGet() async throws {
        var logger = Logger(label: "Redis")
        logger.logLevel = .debug
        try await RedisClient.withConnection(.hostname("localhost", port: 6379), logger: logger) { connection, logger in
            try await withKey(connection: connection) { key in
                _ = try await connection.set(key: key, value: "Hello")
                let response = try await connection.get(key: key).converting(to: String.self)
                #expect(response == "Hello")
            }
        }
    }

    @Test
    func testPipelinedSetGet() async throws {
        var logger = Logger(label: "Redis")
        logger.logLevel = .debug
        try await RedisClient.withConnection(.hostname("localhost", port: 6379), logger: logger) { connection, logger in
            try await withKey(connection: connection) { key in
                let responses = try await connection.pipeline(
                    [
                        .set(key: key, value: "Pipelined Hello"),
                        .get(key: key),
                    ]
                )
                let value = try responses[1].converting(to: String.self)
                #expect(value == "Pipelined Hello")
            }
        }
    }

    @Test
    func testSort() async throws {
        var logger = Logger(label: "Redis")
        logger.logLevel = .debug
        try await RedisClient.withConnection(.hostname("localhost", port: 6379), logger: logger) { connection, logger in
            try await withKey(connection: connection) { key in
                _ = try await connection.lpush(key: key, element: "a")
                _ = try await connection.lpush(key: key, element: "c")
                _ = try await connection.lpush(key: key, element: "b")
                let list = try await connection.sort(key: key, sorting: true).converting(to: [String].self)
                #expect(list == ["a", "b", "c"])
            }
        }
    }

    @Test("Array with count using LMPOP")
    func testArrayWithCount() async throws {
        var logger = Logger(label: "Redis")
        logger.logLevel = .debug
        try await RedisClient.withConnection(.hostname("localhost", port: 6379), logger: logger) { connection, logger in
            try await withKey(connection: connection) { key in
                try await withKey(connection: connection) { key2 in
                    _ = try await connection.lpush(key: key, element: "a")
                    _ = try await connection.lpush(key: key2, element: "b")
                    let rt1 = try await connection.lmpop(key: key, key2, where: .left).converting(to: [RESP3Token].self)
                    let keyReturned1 = try RedisKey(from: rt1[0])
                    let values1 = try [String](from: rt1[1])
                    #expect(keyReturned1 == key)
                    #expect(values1.first == "a")
                    let rt2 = try await connection.lmpop(key: key, key2, where: .left).converting(to: [RESP3Token].self)
                    let keyReturned2 = try RedisKey(from: rt2[0])
                    let values2 = try [String](from: rt2[1])
                    #expect(keyReturned2 == key2)
                    #expect(values2.first == "b")
                }
            }
        }
    }
}
