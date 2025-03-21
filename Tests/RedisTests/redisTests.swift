import Foundation
import Logging
import Testing

@testable import Redis

@Test func example() async throws {
    var logger = Logger(label: "Redis")
    logger.logLevel = .debug
    try await RedisClient.connect(.hostname("localhost", port: 6379), logger: logger) { connection, logger in
        let key = RedisKey(rawValue: UUID().uuidString)
        _ = try await connection.setex(key: key, seconds: 50, value: "Hello")
        let response = try await connection.get(key: key)
        #expect(String(from: response) == "Hello")
    }
}
