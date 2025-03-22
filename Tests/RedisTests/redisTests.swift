import Foundation
import Logging
import RESP3
import Testing

@testable import Redis

@Test func testSetGet() async throws {
    var logger = Logger(label: "Redis")
    logger.logLevel = .debug
    try await RedisClient.withConnection(.hostname("localhost", port: 6379), logger: logger) { connection, logger in
        let key = RedisKey(rawValue: UUID().uuidString)
        _ = try await connection.set(key: key, value: "Hello")
        let response = try await connection.get(key: key)
        #expect(try String(from: response) == "Hello")
    }
}

@Test func testSort() async throws {
    var logger = Logger(label: "Redis")
    logger.logLevel = .debug
    try await RedisClient.withConnection(.hostname("localhost", port: 6379), logger: logger) { connection, logger in
        let key = RedisKey(rawValue: UUID().uuidString)
        _ = try await connection.lpush(key: key, element: "a")
        _ = try await connection.lpush(key: key, element: "c")
        _ = try await connection.lpush(key: key, element: "b")
        let list = try await connection.sort(key: key, sorting: true)
        let array = try [String](from: list)
        #expect(array == ["a", "b", "c"])
    }
}
