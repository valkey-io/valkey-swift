import Foundation

@main
struct App {
    static func main() async throws {
        let app = App()
        try await app.run()
    }

    func run() async throws {
        let outputFile = "Sources/RedisCommands/redis_commands.swift"
        let resourceFolder = Bundle.module.resourceURL!
        let commands = try load(fileURL: resourceFolder.appending(path: "commands.json"), as: RedisCommands.self)
        let resp3Replies = try load(fileURL: resourceFolder.appending(path: "resp3_replies.json"), as: RESPReplies.self)
        let output = renderRedisCommands(commands, replies: resp3Replies)
        try output.write(toFile: outputFile, atomically: true, encoding: .utf8)
    }

    func load<Value: Decodable>(fileURL: URL, as: Value.Type = Value.self) throws -> Value {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(Value.self, from: data)
    }
}
