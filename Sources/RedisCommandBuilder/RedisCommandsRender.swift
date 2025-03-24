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

    var cleanupReplyComment: String {
        self
            .replacing("/docs/reference", with: "https:/redis.io/docs/reference")
            .replacing(" reply]", with: "]")
    }

    mutating func appendFunctionCommentHeader(command: RedisCommand, name: String, reply: [String], inRedisCommand: Bool) {
        let linkName = name.replacing(" ", with: "-").lowercased()
        self.append("    /// \(command.summary)\n")
        self.append("    ///\n")
        self.append("    /// - Documentation: [\(name)](https:/redis.io/docs/latest/commands/\(linkName))\n")
        self.append("    /// - Version: \(command.since)\n")
        if let complexity = command.complexity {
            self.append("    /// - Complexity: \(complexity)\n")
        }
        self.append("    /// - Categories: \(command.aclCategories.joined(separator: ", "))\n")
        var reply = reply
        let firstReply = reply.removeFirst()
        self.append("    /// - \(inRedisCommand ? "Response:" : "Returns:") \(firstReply.cleanupReplyComment)\n")
        for line in reply {
            self.append("    ///     \(line.cleanupReplyComment)\n")
        }
    }

    mutating func appendOneOfEnum(argument: RedisCommand.Argument, names: [String]) {
        guard let arguments = argument.arguments, arguments.count > 0 else {
            preconditionFailure("OneOf without arguments")
        }
        let names = names + [argument.name.swiftTypename]
        let enumName = enumName(names: names)
        for arg in arguments {
            if case .oneOf = arg.type {
                self.appendOneOfEnum(argument: arg, names: names)
            } else if case .block = arg.type {
                self.appendBlock(argument: arg, names: names)
            }
        }
        self.append("    public enum \(enumName): RESPRenderable {\n")
        for arg in arguments {
            if case .pureToken = arg.type {
                self.append("        case \(arg.swiftArgument)\n")
            } else {
                self.append("        case \(arg.swiftArgument)(\(variableType(arg, names: names, inRESPCommand: true, isArray: true)))\n")
            }
        }
        self.append("\n")
        self.append("        @inlinable\n")
        self.append("        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {\n")
        self.append("            switch self {\n")
        for arg in arguments {
            if case .pureToken = arg.type {
                self.append(
                    "            case .\(arg.swiftArgument): \"\(arg.token!)\".writeToRESPBuffer(&buffer)\n"
                )
            } else {
                self.append(
                    "            case .\(arg.swiftArgument)(let \(arg.swiftArgument)): \(arg.redisRepresentable(isArray: true)).writeToRESPBuffer(&buffer)\n"
                )
            }
        }
        self.append("            }\n")
        self.append("        }\n")
        self.append("    }\n")
    }

    mutating func appendBlock(argument: RedisCommand.Argument, names: [String]) {
        guard let arguments = argument.arguments, arguments.count > 0 else {
            preconditionFailure("OneOf without arguments")
        }
        let names = names + [argument.name.swiftTypename]
        let enumName = enumName(names: names)
        for arg in arguments {
            if case .oneOf = arg.type {
                self.appendOneOfEnum(argument: arg, names: names)
            } else if case .block = arg.type {
                self.appendBlock(argument: arg, names: names)
            }
        }
        self.append("    public struct \(enumName): RESPRenderable {\n")
        for arg in arguments {
            self.append(
                "        @usableFromInline let \(arg.swiftVariable): \(variableType(arg, names: names, inRESPCommand: true, isArray: true))\n"
            )
        }
        self.append("\n")
        self.append("        @inlinable\n")
        self.append("        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {\n")
        self.append("            var count = 0\n")
        for arg in arguments {
            if case .pureToken = arg.type {
                self.append("            if self.\(arg.swiftArgument) { count += \"\(arg.token!)\".writeToRESPBuffer(&buffer) }\n")
            } else {
                self.append("            count += self.\(arg.swiftArgument).writeToRESPBuffer(&buffer)\n")
            }
        }
        self.append("            return count\n")
        self.append("        }\n")
        self.append("    }\n")
    }

    mutating func appendCommandFunction(command: RedisCommand, reply: [String], name: String) {
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
                self.appendOneOfEnum(argument: arg, names: [name])
            } else if case .block = arg.type {
                self.appendBlock(argument: arg, names: [name])
            }
        }

        func _appendCommandFunction(isArray: Bool) {
            // Comment header
            self.appendFunctionCommentHeader(command: command, name: name, reply: reply, inRedisCommand: true)
            // Command function
            let commandParametersString =
                arguments
                .map { "\($0.swiftArgument): \(parameterType($0, names: [name], inRESPCommand: true, isArray: isArray))" }
                .joined(separator: ", ")
            self.append("    @inlinable\n")
            self.append("    public static func \(name.swiftFunction)(\(commandParametersString)) -> RESPCommand {\n")
            let commandArguments =
                if let subCommand {
                    ["\"\(commandName)\"", "\"\(subCommand)\""] + arguments.map { $0.redisRepresentable(isArray: isArray) }
                } else {
                    ["\"\(commandName)\""] + arguments.map { $0.redisRepresentable(isArray: isArray) }
                }
            let commandArgumentsString = commandArguments.joined(separator: ", ")
            self.append("        RESPCommand(\(commandArgumentsString))\n")
            self.append("    }\n\n")
        }
        _appendCommandFunction(isArray: false)
        if arguments.contains(where: { $0.multiple == true }) {
            _appendCommandFunction(isArray: true)
        }
    }

    mutating func appendFunction(command: RedisCommand, reply: [String], name: String) {
        var commandName = name
        var subCommand: String? = nil
        if name.contains(" ") {
            var split = name.split(separator: " ", maxSplits: 1)
            commandName = .init(split.removeFirst())
            subCommand = .init(split.last!)
        }
        let arguments = (command.arguments ?? [])

        func _appendFunction(isArray: Bool) {
            // Comment header
            self.appendFunctionCommentHeader(command: command, name: name, reply: reply, inRedisCommand: false)
            // Operation function
            let parametersString =
                arguments
                .map { "\($0.swiftArgument): \(parameterType($0, names: [name], inRESPCommand: false, isArray: isArray))" }
                .joined(separator: ", ")
            self.append("    @inlinable\n")
            self.append("    public func \(name.swiftFunction)(\(parametersString)) async throws -> RESP3Token {\n")
            let commandArguments =
                if let subCommand {
                    ["\"\(commandName)\"", "\"\(subCommand)\""] + arguments.map { $0.redisRepresentable(isArray: isArray) }
                } else {
                    ["\"\(commandName)\""] + arguments.map { $0.redisRepresentable(isArray: isArray) }
                }
            let argumentsString = commandArguments.joined(separator: ", ")
            self.append(
                "        try await send(\(argumentsString))\n"
            )
            self.append("    }\n\n")
        }
        _appendFunction(isArray: false)
        if arguments.contains(where: { $0.multiple == true }) {
            _appendFunction(isArray: true)
        }
    }
}

func renderRedisCommands(_ commands: RedisCommands, replies: RESPReplies) -> String {
    var string = """
        import NIOCore
        import RESP3

        #if canImport(FoundationEssentials)
        import FoundationEssentials
        #else
        import Foundation
        #endif

        extension RESPCommand {

        """
    for key in commands.commands.keys.sorted() {
        // if there is no reply info assume command is a container command
        if let reply = replies.commands[key], reply.count > 0 {
            string.appendCommandFunction(command: commands.commands[key]!, reply: reply, name: key)
        }
    }
    string.append("}\n")
    string.append("\n")
    string.append("extension RedisConnection {\n")
    for key in commands.commands.keys.sorted() {
        // if there is no reply info assume command is a container command
        if let reply = replies.commands[key], reply.count > 0 {
            string.appendFunction(command: commands.commands[key]!, reply: reply, name: key)
        }
    }
    string.append("}\n")
    return string
}

private func enumName(names: [String]) -> String {
    var names = names
    let functionName = names.removeFirst()
    return "\(functionName.swiftFunction.uppercased())\(names.map { $0.upperFirst()}.joined())"
}

private func parameterType(_ parameter: RedisCommand.Argument, names: [String], inRESPCommand: Bool, isArray: Bool) -> String {
    let variableType = variableType(parameter, names: names, inRESPCommand: inRESPCommand, isArray: isArray)
    if parameter.type == .pureToken {
        return variableType + " = false"
    } else if parameter.optional == true, parameter.multiple != true {
        return variableType + " = nil"
    } else if parameter.multiple == true, isArray == false {
        return variableType + "? = nil"
    }
    return variableType
}

private func variableType(_ parameter: RedisCommand.Argument, names: [String], inRESPCommand: Bool, isArray: Bool) -> String {
    var parameterString = parameter.type.swiftName
    if case .oneOf = parameter.type {
        parameterString = "\(inRESPCommand ? "" : "RESPCommand.")\(enumName(names: names + [parameter.name.swiftTypename]))"
    }
    if case .block = parameter.type {
        parameterString = "\(inRESPCommand ? "" : "RESPCommand.")\(enumName(names: names + [parameter.name.swiftTypename]))"
    }
    if parameter.multiple == true {
        if isArray {
            parameterString = "[\(parameterString)]"
        }
    } else if parameter.optional == true, parameter.type != .pureToken {
        parameterString.append("?")
    }
    return parameterString
}

extension RedisCommand.ArgumentType {
    var swiftName: String {
        switch self {
        case .block: "#"
        case .double: "Double"
        case .integer: "Int"
        case .key: "RedisKey"
        case .oneOf: "#"
        case .pattern: "String"
        case .pureToken: "Bool"
        case .string: "String"
        case .unixTime: "Date"
        }
    }
}

extension RedisCommand.Argument {
    func redisRepresentable(isArray: Bool) -> String {
        switch self.type {
        case .pureToken: "RedisPureToken(\"\(self.token!)\", \(self.swiftVariable))"
        default:
            if let token = self.token {
                "RESPWithToken(\"\(token)\", \(self.swiftVariable))"
            } else if multiple == true, combinedWithCount == true {
                if isArray {
                    "RESPArrayWithCount(\(self.swiftVariable))"
                } else {
                    "1, \(self.swiftVariable)"
                }
            } else {
                self.swiftVariable
            }
        }
    }

    var swiftVariable: String {
        self.name.swiftVariable
    }

    var swiftArgument: String {
        self.name.swiftArgument
    }
}
