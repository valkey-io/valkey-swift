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
        let mustacheLibrary = try await MustacheLibrary(directory: resourceFolder.path())
        let commands = try loadCommandsJSON()
        let context = createMustacheContext(from: commands)
        guard let output = mustacheLibrary.render(context, withTemplate: "file") else { preconditionFailure("Could not find mustache template") }
        try output.write(toFile: "Sources/Redis/RedisConnection_commands.swift", atomically: true, encoding: .utf8)
    }
}
