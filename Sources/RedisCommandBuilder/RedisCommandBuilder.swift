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

    func createMustacheContext(from commands: RedisCommands) -> [String: Any] {
        let keys = commands.commands.keys.sorted()
        let context =
            keys
            .compactMap { name -> FunctionContext? in
                let command = commands.commands[name]!
                guard command.arguments?.first(where: { $0.type.swiftName == "Never" }) == nil else {
                    print("Skipping \(name)")
                    return nil
                }
                return createFunctionContext(from: command, named: name)
            }
        return ["commands": context]
    }

    func createFunctionContext(from command: RedisCommand, named name: String) -> FunctionContext {
        let parameters = command.arguments
        var commandName = name
        var arguments = command.arguments?.map { createArgumentContext(from: $0) } ?? []
        if name.contains(" ") {
            var split = name.split(separator: " ")
            commandName = .init(split.removeFirst())
            arguments = split.map { ArgumentContext(name: "\"\($0)\"", isString: true, type: "String", multiple: false) } + arguments
        }
        let buildArguments = arguments.contains { $0.multiple == true }
        return .init(
            summary: command.summary,
            version: command.since,
            complexity: command.complexity,
            categories: command.aclCategories,
            commandName: commandName,
            funcName: name.swiftFunction(),
            buildArgs: buildArguments,
            oneArg: arguments.count <= 1,
            parameters: parameters?.map { createArgumentContext(from: $0) } ?? [],
            arguments: arguments
        )
    }

    func createArgumentContext(from argument: RedisCommand.Argument) -> ArgumentContext {
        let name = argument.name.swiftArgument()
        return .init(
            name: name,
            isString: argument.type == .string,
            type: argument.type.swiftName,
            multiple: argument.multiple == true
        )
    }
}

struct ArgumentContext {
    let name: String
    let isString: Bool
    let type: String
    let multiple: Bool
}

struct FunctionContext {
    let summary: String
    let version: String
    let complexity: String?
    let categories: [String]
    let commandName: String
    let funcName: String
    let buildArgs: Bool
    let oneArg: Bool
    let parameters: [ArgumentContext]?
    let arguments: [ArgumentContext]?
}

extension RedisCommand.ArgumentType {
    var swiftName: String {
        switch self {
        case .block: "Never"
        case .double: "Double"
        case .integer: "Int"
        case .key: "RedisKey"
        case .oneOf: "Never"
        case .pattern: "Never"
        case .pureToken: "Bool"
        case .string: "String"
        case .unixTime: "Date"
        }
    }
}
