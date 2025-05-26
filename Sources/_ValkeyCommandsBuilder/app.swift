//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey open source project
//
// Copyright (c) 2025 Apple Inc. and the swift-valkey project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-valkey project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation

@main
struct App {
    static func main() async throws {
        let app = App()
        try await app.run()
    }

    func run() async throws {
        let resourceFolder = Bundle.module.resourceURL!
        let commands = try load(fileURL: resourceFolder.appending(path: "valkey-commands.json"), as: ValkeyCommands.self)
        try writeValkeyCommands(toFolder: "Sources/Valkey/Commands/", commands: commands, module: false)
        let bloomCommands = try load(fileURL: resourceFolder.appending(path: "valkey-bloom-commands.json"), as: ValkeyCommands.self)
        try writeValkeyCommands(toFolder: "Sources/ValkeyBloom/", commands: bloomCommands, module: true)
        let jsonCommands = try load(fileURL: resourceFolder.appending(path: "valkey-json-commands.json"), as: ValkeyCommands.self)
        try writeValkeyCommands(toFolder: "Sources/ValkeyJSON/", commands: jsonCommands, module: true)
    }

    func writeValkeyCommands(toFolder: String, commands: ValkeyCommands, module: Bool) throws {
        // get list of groups
        var groups: Set<String> = .init()
        for command in commands.commands.values {
            groups.insert(command.group)
        }
        for group in groups {
            let groupCommands = commands.commands.filter { $0.value.group == group }
            let output = renderValkeyCommands(groupCommands, fullCommandList: commands, module: module)
            let filename = "\(toFolder)\(group.swiftTypename)Commands.swift"
            try output.write(toFile: filename, atomically: true, encoding: .utf8)
        }
    }

    func load<Value: Decodable>(fileURL: URL, as: Value.Type = Value.self) throws -> Value {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(Value.self, from: data)
    }
}
