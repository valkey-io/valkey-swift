import Foundation

@main
struct App {
    static func main() async throws {
        let app = App()
        try await app.run()
    }

    func run() async throws {
        let resourceFolder = Bundle.module.resourceURL!
        let commands = try load(fileURL: resourceFolder.appending(path: "commands.json"), as: ValkeyCommands.self)
        let resp3Replies = try load(fileURL: resourceFolder.appending(path: "resp3_replies.json"), as: RESPReplies.self)
        try writeRedisCommands(toFolder: "Sources/Valkey/Commands/", commands: commands, replies: resp3Replies)
    }

    func writeRedisCommands(toFolder: String, commands: ValkeyCommands, replies: RESPReplies) throws {
        // get list of groups
        var groups: Set<String> = .init()
        for command in commands.commands.values {
            groups.insert(command.group)
        }
        for group in groups {
            let commands = commands.commands.filter { $0.value.group == group }
            let output = renderRedisCommands(commands, replies: replies)
            let filename = "\(toFolder)\(group.swiftTypename)Commands.swift"
            try output.write(toFile: filename, atomically: true, encoding: .utf8)
        }
    }

    func load<Value: Decodable>(fileURL: URL, as: Value.Type = Value.self) throws -> Value {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(Value.self, from: data)
    }
}
