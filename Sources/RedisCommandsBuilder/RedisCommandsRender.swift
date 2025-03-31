extension String {
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
                    "            case .\(arg.swiftArgument)(let \(arg.swiftArgument)): \(arg.redisRepresentable(isArray: false)).writeToRESPBuffer(&buffer)\n"
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
                //if let token = arg.token {
                //    self.append("            count += RESPWithToken(\"\(token)\", \(arg.swiftArgument)).writeToRESPBuffer(&buffer)\n")
                //} else {
                self.append("            count += \(arg.redisRepresentable(isArray: false)).writeToRESPBuffer(&buffer)\n")
                //}
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
                .map { "\($0.functionLabel(isArray: isArray)): \(parameterType($0, names: [name], inRESPCommand: true, isArray: isArray))" }
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
        if arguments.contains(where: { $0.multiple }) {
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
        var converting: Bool = false
        var returnType: String = " -> RESPToken"
        if let type = getReturnType(reply: reply) {
            if type == "Void" {
                returnType = ""
            } else if type != "RESPToken" {
                converting = true
                returnType = " -> \(type)"
            }
        }
        func _appendFunction(isArray: Bool) {
            // Comment header
            self.appendFunctionCommentHeader(command: command, name: name, reply: reply, inRedisCommand: false)
            // Operation function
            let parametersString =
                arguments
                .map { "\($0.functionLabel(isArray: isArray)): \(parameterType($0, names: [name], inRESPCommand: false, isArray: isArray))" }
                .joined(separator: ", ")
            self.append("    @inlinable\n")
            self.append("    public func \(name.swiftFunction)(\(parametersString)) async throws\(returnType) {\n")
            let commandArguments =
                if let subCommand {
                    ["\"\(commandName)\"", "\"\(subCommand)\""] + arguments.map { $0.redisRepresentable(isArray: isArray) }
                } else {
                    ["\"\(commandName)\""] + arguments.map { $0.redisRepresentable(isArray: isArray) }
                }
            let argumentsString = commandArguments.joined(separator: ", ")
            self.append(
                "        try await send(\(argumentsString))\(converting ? ".converting()": "")\n"
            )
            self.append("    }\n\n")
        }
        _appendFunction(isArray: false)
        if arguments.contains(where: \.multiple) {
            _appendFunction(isArray: true)
        }
    }
}

func renderRedisCommands(_ commands: [String: RedisCommand], replies: RESPReplies) -> String {
    var string = """
        //===----------------------------------------------------------------------===//
        //
        // This source file is part of the swift-redis open source project
        //
        // Copyright (c) 2025 Apple Inc. and the swift-redis project authors
        // Licensed under Apache License v2.0
        //
        // See LICENSE.txt for license information
        // See CONTRIBUTORS.txt for the list of swift-redis project authors
        //
        // SPDX-License-Identifier: Apache-2.0
        //
        //===----------------------------------------------------------------------===//

        // This file is autogenerated by RedisCommandsBuilder

        import NIOCore
        import RESP
        import Redis

        #if canImport(FoundationEssentials)
        import FoundationEssentials
        #else
        import Foundation
        #endif

        extension RESPCommand {

        """

    for key in commands.keys.sorted() {
        let command = commands[key]!
        // if there is no reply info assume command is a container command
        guard let reply = replies.commands[key], reply.count > 0 else { continue }
        string.appendCommandFunction(command: command, reply: reply, name: key)
    }
    string.append("}\n")
    string.append("\n")
    string.append("extension RedisConnection {\n")
    for key in commands.keys.sorted() {
        let command = commands[key]!
        // if there is no reply info assume command is a container command
        guard let reply = replies.commands[key], reply.count > 0 else { continue }
        string.appendFunction(command: command, reply: reply, name: key)
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
    } else if parameter.multiple {
        if isArray == false, parameter.optional {
            return variableType + " = nil"
        }
    } else if parameter.optional {
        return variableType + " = nil"
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
    if parameter.multiple, isArray {
        parameterString = "[\(parameterString)]"
    } else if parameter.optional, parameter.type != .pureToken {
        parameterString.append("?")
    }
    return parameterString
}

private func getReturnType(reply replies: [String]) -> String? {
    let replies = replies.filter { $0.hasPrefix("[") || $0.hasPrefix("* [") }
    if replies.count == 1 {
        return getReturnType(reply: replies[0])
    } else if replies.count > 1 {
        var returnType = getReturnType(reply: replies[0].dropPrefix("* "))
        var `optional` = false
        for value in replies.dropFirst(1) {
            if let returnType2 = getReturnType(reply: value.dropPrefix("* ")) {
                if returnType == "Void" {
                    returnType = returnType2
                    optional = true
                } else if returnType2 != returnType {
                    if returnType2 == "Void" {
                        optional = true
                    } else {
                        return nil
                    }
                }
            }
        }
        if returnType != "Void", optional {
            return "\(returnType ?? "RESPToken")?"
        } else {
            return returnType
        }
    }
    return nil
}
private func getReturnType(reply: some StringProtocol) -> String? {
    if reply.hasPrefix("[") {
        if reply.hasPrefix("[Integer") {
            return "Int"
        } else if reply.hasPrefix("[Double") {
            return "Double"
        } else if reply.hasPrefix("[Bulk string") {
            return "String"
        } else if reply.hasPrefix("[Verbatim string") {
            return "String"
        } else if reply.hasPrefix("[Simple string") {
            if reply.contains("`OK`") {
                return "Void"
            } else {
                return "String"
            }
        } else if reply.hasPrefix("[Array") {
            if let range: Range = reply.firstRange(of: "): an array of ") {
                if let element = getReturnType(reply: reply[range.upperBound...]) {
                    return "[\(element)]"
                }
            }
            return "[RESPToken]"
        } else if reply.hasPrefix("[Null") || reply.hasPrefix("[Nil") {
            return "Void"
        } else if reply.hasPrefix("[Simple error") {
            return nil
        }
        return "RESPToken"
    }
    return nil
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
        var variable = self.functionLabel(isArray: multiple && isArray)
        switch self.type
        {
        case .pureToken: return "RedisPureToken(\"\(self.token!)\", \(variable))"
        default:
            if self.type == .unixTime {
                if self.optional {
                    if self.name.contains("millisecond") {
                        variable = "\(variable).map { Int($0.timeIntervalSince1970 * 1000) }"
                    } else {
                        variable = "\(variable).map { Int($0.timeIntervalSince1970) }"
                    }
                } else {
                    if self.name.contains("millisecond") {
                        variable = "Int(\(variable).timeIntervalSince1970 * 1000)"
                    } else {
                        variable = "Int(\(variable).timeIntervalSince1970)"
                    }
                }
            }
            if let token = self.token {
                return "RESPWithToken(\"\(token)\", \(variable))"
            } else if multiple, combinedWithCount == true {
                if isArray {
                    return "RESPArrayWithCount(\(variable))"
                } else {
                    return "1, \(variable)"
                }
            } else {
                return variable
            }
        }
    }

    var swiftVariable: String {
        self.name.swiftVariable
    }

    var swiftArgument: String {
        self.name.swiftArgument
    }

    func functionLabel(isArray: Bool) -> String {
        if isArray, self.multiple {
            return "\(self.swiftVariable)s"
        } else {
            return self.swiftVariable
        }
    }
}
