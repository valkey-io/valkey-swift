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
        let output = renderRedisCommands(commands)
        try output.write(toFile: "Sources/Redis/RedisConnection_commands2.swift", atomically: true, encoding: .utf8)
    }
}
