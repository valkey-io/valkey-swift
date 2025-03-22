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

@Test func testLMPOP() async throws {
    var logger = Logger(label: "Redis")
    logger.logLevel = .debug
    try await RedisClient.withConnection(.hostname("localhost", port: 6379), logger: logger) { connection, logger in
        let key = RedisKey(rawValue: UUID().uuidString)
        let key2 = RedisKey(rawValue: UUID().uuidString)
        _ = try await connection.lpush(key: key, element: "a")
        _ = try await connection.lpush(key: key2, element: "b")
        let rt1 = try await [RESP3Token](from: connection.lmpop(key: key, key2, where: .left))
        let keyReturned1 = try RedisKey(from: rt1[0])
        let values1 = try [String](from: rt1[1])
        #expect(keyReturned1 == key)
        #expect(values1.first == "a")
        let rt2 = try await [RESP3Token](from: connection.lmpop(key: key, key2, where: .left))
        let keyReturned2 = try RedisKey(from: rt2[0])
        let values2 = try [String](from: rt2[1])
        #expect(keyReturned2 == key2)
        #expect(values2.first == "b")
    }
}
