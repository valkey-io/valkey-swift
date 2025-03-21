extension String {
    var redisFileHeader: Self {
        """
        import NIOCore
        import RESP3

        #if canImport(FoundationEssentials)
        import FoundationEssentials
        #else
        import Foundation
        #endif
        """
    }

    mutating func appendFunctionCommentHeader(command: RedisCommand) {
        self.append("    /// \(command.summary)\n")
        self.append("    /// Version: \(command.since)\n")
        if let complexity = command.complexity {
            self.append("    /// Complexity: \(complexity)\n")
        }
        self.append("    /// Categories: \(command.aclCategories.joined(separator: ", "))\n")
    }

    mutating func appendFunction(command: RedisCommand, name: String) {
        guard command.arguments?.contains(where: {$0.type.swiftName == "Never"}) != true else {
            return
        }
        var redisParameters = command.arguments ?? []
        var commandName = name
        if name.contains(" ") {
            var split = name.split(separator: " ")
            commandName = .init(split.removeFirst())
            redisParameters =
                split.map {
                    RedisCommand.Argument(name: "\"\($0)\"", type: .string, multiple: nil, optional: nil, token: nil)
                } + redisParameters
        }
        self.appendFunctionCommentHeader(command: command)
        let arguments = (command.arguments ?? [])
        let parametersString = arguments
            .map {"\($0.name.swiftArgument): \(Self.parameterType($0))" }
            .joined(separator: ", ")
        self.append("    @inlinable\n")
        self.append("    public func \(name.swiftFunction)(\(parametersString)) async throws -> RESP3Token {\n")
        let argumentsString = arguments
            .map {"\($0.name.swiftArgument): \($0.name.swiftArgument)" }
            .joined(separator: ", ")
        self.append(
            "        let response = try await send(\(name.swiftFunction)Command(\(argumentsString)))\n"
        )
        self.append("        return response\n")
        self.append("   }\n\n")

        let commandParametersString = arguments
            .map {"\($0.name.swiftArgument): \(Self.parameterType($0, isArray: true))" }
            .joined(separator: ", ")
        self.append("    @inlinable\n")
        self.append("    public func \(name.swiftFunction)Command(\(commandParametersString)) -> RESPCommand {\n")
        let argumentsString2 = arguments
            .map(\.name.swiftArgument)
            .joined(separator: ", ")
        if argumentsString2.count > 0 {
            self.append("        return RESPCommand(\"\(commandName)\", \(argumentsString2))")
        } else {
            self.append("        return RESPCommand(\"\(commandName)\")")
        }
        self.append("    }\n\n")

    }

    static func parameterType(_ parameter: RedisCommand.Argument, isArray: Bool = false) -> String {
        var parameterString = parameter.type.swiftName
        if parameter.multiple == true {
            if isArray {
                parameterString = "[\(parameterString)]"
            } else {
                parameterString.append("...")
            }
        } else if parameter.optional == true, parameter.type != .pureToken {
            parameterString.append("?")
        }
        return parameterString
    }
}

func renderRedisCommands(_ commands: RedisCommands) -> String {
    var string = """
        import NIOCore
        import RESP3

        #if canImport(FoundationEssentials)
        import FoundationEssentials
        #else
        import Foundation
        #endif

        extension RedisConnection {

        """
    for key in commands.commands.keys.sorted() {
        string.appendFunction(command: commands.commands[key]!, name: key)
    }
    string.append("}\n")
    return string
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
