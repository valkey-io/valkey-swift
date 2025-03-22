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
        self.append("    ///\n")
        self.append("    /// Version: \(command.since)\n")
        if let complexity = command.complexity {
            self.append("    /// Complexity: \(complexity)\n")
        }
        self.append("    /// Categories: \(command.aclCategories.joined(separator: ", "))\n")
    }

    mutating func appendOneOfEnum(argument: RedisCommand.Argument, functionName: String) {
        guard let arguments = argument.arguments, arguments.count > 0 else {
            preconditionFailure("OneOf without arguments")
        }
        let enumName = enumName(name: argument.name, functionName: functionName)
        self.append("    public enum \(enumName): RESPRepresentable {\n")
        for arg in arguments {
            if case .pureToken = arg.type {
                self.append("        case \(arg.name.swiftArgument)\n")
            } else {
                self.append("        case \(arg.name.swiftArgument)(\(arg.type.swiftName))\n")
            }
        }
        self.append("\n")
        self.append("        @inlinable\n")
        self.append("        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {\n")
        self.append("            switch self {\n")
        for arg in arguments {
            if case .pureToken = arg.type {
                self.append(
                    "            case .\(arg.name.swiftArgument): \"\(arg.token!)\".writeToRESPBuffer(&buffer)\n"
                )
            } else {
                self.append(
                    "            case .\(arg.name.swiftArgument)(let \(arg.name.swiftArgument)): \(arg.redisRepresentable).writeToRESPBuffer(&buffer)\n"
                )
            }
        }
        self.append("            }\n")
        self.append("        }\n")
        self.append("    }\n")
    }

    mutating func appendFunction(command: RedisCommand, name: String) {
        guard command.arguments?.contains(where: { $0.type.swiftName == "Never" }) != true else {
            print("Skipping \(name)")
            return
        }
        var commandName = name
        var subCommand: String? = nil
        if name.contains(" ") {
            var split = name.split(separator: " ", maxSplits: 1)
            commandName = .init(split.removeFirst())
            subCommand = .init(split.last!)
        }
        let arguments = (command.arguments ?? [])
        // Enums
        for arg in arguments {
            if case .oneOf = arg.type {
                guard arg.arguments?.contains(where: { $0.type.swiftName == "Never" }) != true else {
                    print("Skipping \(name)")
                    return
                }
                self.appendOneOfEnum(argument: arg, functionName: name)
            }
        }
        // Comment header
        self.appendFunctionCommentHeader(command: command)
        // Operation function
        let parametersString =
            arguments
            .map { "\($0.name.swiftArgument): \(parameterType($0, functionName: name))" }
            .joined(separator: ", ")
        self.append("    @inlinable\n")
        self.append("    public func \(name.swiftFunction)(\(parametersString)) async throws -> RESP3Token {\n")
        let argumentsString =
            arguments
            .map { "\($0.name.swiftArgument): \($0.name.swiftVariable)" }
            .joined(separator: ", ")
        self.append(
            "        let response = try await send(\(name.swiftFunction)Command(\(argumentsString)))\n"
        )
        self.append("        return response\n")
        self.append("    }\n\n")
        // Command function
        let commandParametersString =
            arguments
            .map { "\($0.name.swiftArgument): \(parameterType($0, functionName: name, isArray: true))" }
            .joined(separator: ", ")
        self.append("    @inlinable\n")
        self.append("    public func \(name.swiftFunction)Command(\(commandParametersString)) -> RESPCommand {\n")
        let commandArguments =
            if let subCommand {
                ["\"\(commandName)\"", "\"\(subCommand)\""] + arguments.map(\.redisRepresentable)
            } else {
                ["\"\(commandName)\""] + arguments.map(\.redisRepresentable)
            }
        let commandArgumentsString = commandArguments.joined(separator: ", ")
        self.append("        return RESPCommand(\(commandArgumentsString))\n")
        self.append("    }\n\n")

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

private func enumName(name: String, functionName: String) -> String {
    "\(functionName.swiftFunction.uppercased())\(name.swiftArgument.upperFirst())"
}

private func parameterType(_ parameter: RedisCommand.Argument, functionName: String, isArray: Bool = false) -> String {
    var parameterString = parameter.type.swiftName
    if case .oneOf = parameter.type {
        parameterString = enumName(name: parameter.name, functionName: functionName)
    }
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

extension RedisCommand.ArgumentType {
    var swiftName: String {
        switch self {
        case .block: "Never"
        case .double: "Double"
        case .integer: "Int"
        case .key: "RedisKey"
        case .oneOf: "String"
        case .pattern: "String"
        case .pureToken: "Bool"
        case .string: "String"
        case .unixTime: "Date"
        }
    }
}

extension RedisCommand.Argument {
    var redisRepresentable: String {
        switch self.type {
        case .pureToken: "RedisPureToken(\"\(self.token!)\", \(self.name.swiftVariable))"
        default:
            if let token = self.token {
                "RESPWithToken(\"\(token)\", \(self.name.swiftVariable))"
            } else {
                self.name.swiftVariable
            }
        }
    }
}
