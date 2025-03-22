import Foundation
import Logging
import Testing

@testable import Redis

@Test func example() async throws {
    var logger = Logger(label: "Redis")
    logger.logLevel = .debug
    try await RedisClient.withConnection(.hostname("localhost", port: 6379), logger: logger) { connection, logger in
        let key = RedisKey(rawValue: UUID().uuidString)
        _ = try await connection.setex(key: key, seconds: 50, value: "Hello3")
        let response = try await connection.get(key: key)
        #expect(try String(from: response) == "Hello3")
        let response2 = try await connection.get(key: .init(rawValue: "sdf"))
        let string = try String?(from: response2)
        print(string)
    }
}
