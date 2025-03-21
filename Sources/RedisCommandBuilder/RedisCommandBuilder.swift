import Foundation

extension App {
    func loadCommandsJSON() throws -> RedisCommands {
        let data = try Data(contentsOf: self.resourceFolder.appending(component: "commands.json"))
        return try JSONDecoder().decode(RedisCommands.self, from: data)
    }

    func loadRESP3Replies() throws -> RESPReplies {
        let data = try Data(contentsOf: self.resourceFolder.appending(component: "resp3_replies.json"))
        return try JSONDecoder().decode(RESPReplies.self, from: data)
    }
}

