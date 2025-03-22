import Foundation
import Mustache

@main
struct App {
    let resourceFolder: URL

    init() {
        self.resourceFolder = Bundle.module.resourceURL!
    }

    static func main() async throws {
        let app = App()
        try await app.run()
    }

    func run() async throws {
        let commands = try loadCommandsJSON()
        let resp3Replies = try loadRESP3Replies()
        let output = renderRedisCommands(commands, replies: resp3Replies)
        try output.write(toFile: "Sources/Redis/RedisConnection_commands.swift", atomically: true, encoding: .utf8)
    }

    func loadCommandsJSON() throws -> RedisCommands {
        let data = try Data(contentsOf: self.resourceFolder.appending(component: "commands.json"))
        return try JSONDecoder().decode(RedisCommands.self, from: data)
    }

    func loadRESP3Replies() throws -> RESPReplies {
        let data = try Data(contentsOf: self.resourceFolder.appending(component: "resp3_replies.json"))
        return try JSONDecoder().decode(RESPReplies.self, from: data)
    }
}
