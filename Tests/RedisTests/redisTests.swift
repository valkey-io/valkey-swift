import Logging
import Testing

@testable import Redis

@Test func example() async throws {
    var logger = Logger(label: "Redis")
    logger.logLevel = .debug
    try await RedisClient.connect(.hostname("localhost", port: 6379), logger: logger) { connection, logger in
        let response = try await connection.send(.init("GET", arguments: ["ping"]))
        print(String(from: response) ?? "DIDNT CONVERT")
    }
}
