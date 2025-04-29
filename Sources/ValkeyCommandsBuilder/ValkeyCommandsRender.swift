extension String {
    var cleanupReplyComment: String {
        self
            .replacing("../topics/protocol.md", with: "https:/valkey.io/topics/protocol/")
            .replacing(" reply]", with: "]")
    }

    mutating func appendDeprecatedMessage(command: ValkeyCommand, name: String, tab: String) {
        guard let deprecatedSince = command.deprecatedSince else { return }
        self.append("\(tab)@available(*, deprecated, message: \"Since \(deprecatedSince)")
        if let replacedBy = command.replacedBy {
            self.append(". Replaced by \(replacedBy)")
        }
        self.append(".\")\n")
    }
    mutating func appendCommandCommentHeader(command: ValkeyCommand, name: String, reply: [String], tab: String) {
        self.append("\(tab)/// \(command.summary)\n")
    }

    mutating func appendFunctionCommentHeader(command: ValkeyCommand, name: String, reply: [String]) {
        let linkName = name.replacing(" ", with: "-").lowercased()
        self.append("    /// \(command.summary)\n")
        self.append("    ///\n")
        self.append("    /// - Documentation: [\(name)](https:/valkey.io/commands/\(linkName))\n")
        self.append("    /// - Version: \(command.since)\n")
        if let complexity = command.complexity {
            self.append("    /// - Complexity: \(complexity)\n")
        }
        self.append("    /// - Categories: \(command.aclCategories.joined(separator: ", "))\n")
        var reply = reply
        let firstReply = reply.removeFirst()
        self.append("    /// - Returns: \(firstReply.cleanupReplyComment)\n")
        for line in reply {
            self.append("    ///     \(line.cleanupReplyComment)\n")
        }
    }

    mutating func appendOneOfEnum(argument: ValkeyCommand.Argument, names: [String], tab: String) {
        guard let arguments = argument.arguments, arguments.count > 0 else {
            preconditionFailure("OneOf without arguments")
        }
        let names = names + [argument.name.swiftTypename]
        let enumName = enumName(names: names)
        for arg in arguments {
            if case .oneOf = arg.type {
                self.appendOneOfEnum(argument: arg, names: names, tab: tab)
            } else if case .block = arg.type {
                self.appendBlock(argument: arg, names: names, tab: tab, genericStrings: false)
            }
        }
        self.append("\(tab)    public enum \(enumName): RESPRenderable, Sendable {\n")
        var allPureTokens = true
        for arg in arguments {
            if case .pureToken = arg.type {
                self.append("\(tab)        case \(arg.swiftArgument)\n")
            } else {
                allPureTokens = false
                self.append(
                    "\(tab)        case \(arg.swiftArgument)(\(variableType(arg, names: names, scope: nil, isArray: true, genericStrings: false)))\n"
                )
            }
        }
        self.append("\n")
        if allPureTokens {
            self.append("\(tab)        @inlinable\n")
            self.append("\(tab)        public var respEntries: Int { 1 }\n\n")
        } else {
            self.append("\(tab)        @inlinable\n")
            self.append("\(tab)        public var respEntries: Int {\n")
            self.append("\(tab)            switch self {\n")
            for arg in arguments {
                if case .pureToken = arg.type {
                    self.append(
                        "\(tab)            case .\(arg.swiftArgument): \"\(arg.token!)\".respEntries\n"
                    )
                } else {
                    self.append(
                        "\(tab)            case .\(arg.swiftArgument)(let \(arg.swiftArgument)): \(arg.respRepresentable(isArray: false, genericString: false)).respEntries\n"
                    )
                }
            }
            self.append("\(tab)            }\n")
            self.append("\(tab)        }\n\n")
        }
        self.append("\(tab)        @inlinable\n")
        self.append("\(tab)        public func encode(into commandEncoder: inout ValkeyCommandEncoder) {\n")
        self.append("\(tab)            switch self {\n")
        for arg in arguments {
            if case .pureToken = arg.type {
                self.append(
                    "\(tab)            case .\(arg.swiftArgument): \"\(arg.token!)\".encode(into: &commandEncoder)\n"
                )
            } else {
                self.append(
                    "\(tab)            case .\(arg.swiftArgument)(let \(arg.swiftArgument)): \(arg.respRepresentable(isArray: false, genericString: false)).encode(into: &commandEncoder)\n"
                )
            }
        }
        self.append("\(tab)            }\n")
        self.append("\(tab)        }\n")
        self.append("\(tab)    }\n")
    }

    mutating func appendBlock(argument: ValkeyCommand.Argument, names: [String], tab: String, genericStrings: Bool) {
        guard let arguments = argument.arguments, arguments.count > 0 else {
            preconditionFailure("OneOf without arguments")
        }
        let names = names + [argument.name.swiftTypename]
        let blockName = enumName(names: names)
        for arg in arguments {
            if case .oneOf = arg.type {
                self.appendOneOfEnum(argument: arg, names: names, tab: tab)
            } else if case .block = arg.type {
                self.appendBlock(argument: arg, names: names, tab: tab, genericStrings: genericStrings)
            }
        }
        self.append("\(tab)    public struct \(blockName): RESPRenderable, Sendable {\n")
        for arg in arguments {
            self.append(
                "\(tab)        @usableFromInline let \(arg.swiftVariable): \(variableType(arg, names: names, scope: nil, isArray: true, genericStrings: genericStrings))\n"
            )
        }
        self.append("\n")
        let commandParametersString =
            arguments
            .map { "\($0.name.swiftVariable): \(parameterType($0, names: names, scope: nil, isArray: true, genericStrings: genericStrings))" }
            .joined(separator: ", ")
        self.append("\n\(tab)        @inlinable public init(\(commandParametersString)) {\n")
        for arg in arguments {
            self.append("\(tab)            self.\(arg.name.swiftVariable) = \(arg.name.swiftVariable)\n")
        }
        self.append("\(tab)        }\n\n")
        self.append("\(tab)        @inlinable\n")
        self.append("\(tab)        public var respEntries: Int {\n")
        self.append("\(tab)            ")
        let entries = arguments.map {
            if case .pureToken = $0.type {
                "\"\($0.token!)\".respEntries"
            } else {
                "\($0.respRepresentable(isArray: false, genericString: genericStrings)).respEntries"
            }
        }
        self.append(entries.joined(separator: " + "))
        self.append("\n")
        self.append("\(tab)        }\n\n")
        self.append("\(tab)        @inlinable\n")
        self.append("\(tab)        public func encode(into commandEncoder: inout ValkeyCommandEncoder) {\n")
        for arg in arguments {
            if case .pureToken = arg.type {
                self.append("\(tab)            \"\(arg.token!)\".encode(into: &commandEncoder)\n")
            } else {
                self.append(
                    "\(tab)            \(arg.respRepresentable(isArray: false, genericString: genericStrings)).encode(into: &commandEncoder)\n"
                )
            }
        }
        self.append("\(tab)        }\n")
        self.append("\(tab)    }\n")
    }

    mutating func appendCommand(command: ValkeyCommand, reply: [String], name: String, tab: String, disableResponseCalculation: Bool) {
        var commandName = name
        var subCommand: String? = nil
        let typeName: String
        if name.contains(" ") {
            var split = name.split(separator: " ", maxSplits: 1)
            commandName = .init(split.removeFirst())
            subCommand = .init(split.last!)
            typeName = subCommand!.commandTypeName
        } else {
            typeName = name.commandTypeName
        }
        let keyArguments = command.arguments?.filter { $0.type == .key } ?? []
        let conformance = "ValkeyCommand"
        let genericTypeParameters = genericTypeParameters(command.arguments)
        // Comment header
        self.appendCommandCommentHeader(command: command, name: name, reply: reply, tab: tab)
        self.appendDeprecatedMessage(command: command, name: name, tab: tab)
        self.append("\(tab)public struct \(typeName)\(genericTypeParameters): \(conformance) {\n")

        let arguments = (command.arguments ?? [])
        // Enums
        for arg in arguments {
            if case .oneOf = arg.type {
                self.appendOneOfEnum(argument: arg, names: [], tab: tab)
            } else if case .block = arg.type {
                self.appendBlock(argument: arg, names: [], tab: tab, genericStrings: !arg.optional)
            }
        }
        // return type
        var returnType = disableResponseCalculation ? "RESPToken" : getResponseType(reply: reply)
        if returnType == "Void" {
            returnType = "RESPToken"
        }
        // Command function
        let commandParametersString =
            arguments
            .map { "\($0.name.swiftVariable): \(parameterType($0, names: [], scope: nil, isArray: true, genericStrings: true))" }
            .joined(separator: ", ")
        let commandArguments =
            if let subCommand {
                ["\"\(commandName)\"", "\"\(subCommand)\""] + arguments.map { $0.respRepresentable(isArray: true, genericString: true) }
            } else {
                ["\"\(commandName)\""] + arguments.map { $0.respRepresentable(isArray: true, genericString: true) }
            }
        let commandArgumentsString = commandArguments.joined(separator: ", ")
        if returnType != "RESPToken" {
            self.append("\(tab)    public typealias Response = \(returnType)\n\n")
        }
        if arguments.count > 0 {
            for arg in arguments {
                self.append(
                    "\(tab)    public var \(arg.name.swiftVariable): \(variableType(arg, names: [], scope: nil, isArray: true, genericStrings: true))\n"
                )
            }
            self.append("\n")
        }
        self.append("\(tab)    @inlinable public init(\(commandParametersString)) {\n")
        for arg in arguments {
            self.append("\(tab)        self.\(arg.name.swiftVariable) = \(arg.name.swiftVariable)\n")
        }
        self.append("\(tab)    }\n\n")
        if keyArguments.count > 0 {
            let (keysAffectedType, keysAffected) = constructKeysAffected(keyArguments)
            self.append("\(tab)    public var keysAffected: \(keysAffectedType) { \(keysAffected) }\n\n")
        }

        self.append("\(tab)    @inlinable public func encode(into commandEncoder: inout ValkeyCommandEncoder) {\n")
        self.append("\(tab)        commandEncoder.encodeArray(\(commandArgumentsString))\n")
        self.append("\(tab)    }\n")
        self.append("\(tab)}\n\n")
    }

    mutating func appendFunction(command: ValkeyCommand, reply: [String], name: String, disableResponseCalculation: Bool) {
        let arguments = (command.arguments ?? [])
        //var converting: Bool = false
        var returnType: String = " -> \(name.commandTypeName).Response"
        var ignoreSendResponse = ""
        let type = disableResponseCalculation ? "RESPToken" : getResponseType(reply: reply)
        if type == "Void" {
            returnType = ""
            ignoreSendResponse = "_ = "
        } else if type != "RESPToken" {
            //converting = true
            returnType = " -> \(type)"
        }
        func _appendFunction(isArray: Bool) {
            // Comment header
            self.appendFunctionCommentHeader(command: command, name: name, reply: reply)
            // Operation function
            let genericTypeParameters = genericTypeParameters(command.arguments)
            let genericParameters = genericParameters(command.arguments)
            let parametersString =
                arguments
                .map {
                    "\($0.functionLabel(isArray: isArray)): \(parameterType($0, names: [], scope: "\(name.commandTypeName)\(genericParameters)", isArray: isArray, genericStrings: true))"
                }
                .joined(separator: ", ")
            self.append("    @inlinable\n")
            self.appendDeprecatedMessage(command: command, name: name, tab: "    ")
            self.append("    public func \(name.swiftFunction)\(genericTypeParameters)(\(parametersString)) async throws\(returnType) {\n")
            let commandArguments = arguments.map { "\($0.name.swiftArgument): \($0.name.swiftVariable)" }
            let argumentsString = commandArguments.joined(separator: ", ")
            self.append(
                "        \(ignoreSendResponse)try await send(command: \(name.commandTypeName)(\(argumentsString)))\n"
            )
            self.append("    }\n\n")
        }
        //_appendFunction(isArray: false)
        //if arguments.contains(where: \.multiple) {
        _appendFunction(isArray: true)
        //}
    }
}

func renderValkeyCommands(_ commands: [String: ValkeyCommand], replies: RESPReplies) -> String {
    let disableResponseCalculationCommands: Set<String> = [
        "CLUSTER SHARDS",
        "LPOS",
    ]
    var string = """
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

        // This file is autogenerated by ValkeyCommandsBuilder

        import NIOCore

        #if canImport(FoundationEssentials)
        import FoundationEssentials
        #else
        import Foundation
        #endif


        """

    var keys = commands.keys.sorted()
    let namespaces = Set<String>(
        keys.compactMap {
            let (container, subCommand) = subCommand($0)
            return subCommand != nil ? String(container) : nil
        }
    )
    for namespace in namespaces.sorted() {
        if commands[namespace] != nil, let reply = replies.commands[namespace], reply.count > 0 {
            string.append("extension \(namespace.commandTypeName) {\n")
        } else {
            if let summary = commands[namespace]?.summary {
                string.append("/// \(summary)\n")
            }
            string.append("public enum \(namespace.commandTypeName) {\n")
        }
        for key in keys {
            let (container, subCommand) = subCommand(key)
            if container == namespace, subCommand != nil {
                let command = commands[key]!
                // if there is no reply info assume command is a container command
                guard let reply = replies.commands[key], reply.count > 0 else { continue }
                string.appendCommand(
                    command: command,
                    reply: reply,
                    name: key,
                    tab: "    ",
                    disableResponseCalculation: disableResponseCalculationCommands.contains(key)
                )
            }
        }
        string.append("}\n\n")
    }
    for key in keys {
        guard subCommand(key).1 == nil else { continue }
        let command = commands[key]!
        // if there is no reply info assume command is a container command
        guard let reply = replies.commands[key], reply.count > 0 else { continue }
        string.appendCommand(
            command: command,
            reply: reply,
            name: key,
            tab: "",
            disableResponseCalculation: disableResponseCalculationCommands.contains(key)
        )
    }

    /// Remove subscribe functions as we implement our own versions in code
    let subscribeFunctions = ["SUBSCRIBE", "PSUBSCRIBE", "SSUBSCRIBE", "UNSUBSCRIBE", "PUNSUBSCRIBE", "SUNSUBSCRIBE"]
    keys.removeAll { subscribeFunctions.contains($0) }

    string.append("extension ValkeyConnection {\n")
    for key in keys {
        let command = commands[key]!
        // if there is no reply info assume command is a container command
        guard let reply = replies.commands[key], reply.count > 0 else { continue }
        string.appendFunction(
            command: command,
            reply: reply,
            name: key,
            disableResponseCalculation: disableResponseCalculationCommands.contains(key)
        )
    }
    string.append("}\n")
    return string
}

private func constructKeysAffected(_ keyArguments: [ValkeyCommand.Argument]) -> (type: String, value: String) {
    if keyArguments.count == 1 {
        if keyArguments.first!.multiple {
            return (type: "[ValkeyKey]", value: keyArguments.first!.name.swiftVariable)
        } else {
            return (type: "CollectionOfOne<ValkeyKey>", value: ".init(\(keyArguments.first!.name.swiftVariable))")
        }
    } else {
        var keysAffectedBuilder: String = ""
        var inArray = false
        var first = true
        for key in keyArguments {
            if key.multiple {
                if inArray {
                    keysAffectedBuilder += "]"
                    inArray = false
                }
                if !first {
                    keysAffectedBuilder += " + "
                }
                keysAffectedBuilder += "\(key.name.swiftVariable)"
            } else if key.optional {
                if inArray {
                    keysAffectedBuilder += "]"
                    inArray = false
                }
                if !first {
                    keysAffectedBuilder += " + "
                }
                keysAffectedBuilder += "(\(key.name.swiftVariable).map { [$0] } ?? [])"
            } else {
                if !inArray {
                    if !first {
                        keysAffectedBuilder += " + "
                    }
                    keysAffectedBuilder += "[\(key.name.swiftVariable)"
                    inArray = true
                } else {
                    if !first {
                        keysAffectedBuilder += ", "
                    }
                    keysAffectedBuilder += "\(key.name.swiftVariable)"
                }
            }
            first = false
        }
        if inArray {
            keysAffectedBuilder += "]"
        }
        return (type: "[ValkeyKey]", value: keysAffectedBuilder)
    }
}

private func subCommand(_ command: String) -> (String.SubSequence, String.SubSequence?) {
    if command.contains(" ") {
        let split = command.split(separator: " ", maxSplits: 1)
        return (split[0], split[1])
    }
    return (command[...], nil)
}

private func getGenericParameterArguments(_ arguments: [ValkeyCommand.Argument]?) -> [ValkeyCommand.Argument] {
    guard let arguments else { return [] }
    return arguments.flatMap {
        guard !$0.optional else { return [ValkeyCommand.Argument]() }
        switch $0.type {
        case .string:
            return [$0]
        case .block:
            return getGenericParameterArguments($0.arguments)
        default:
            return []
        }
    }
}

/// construct the generic parameters for a command type
private func genericTypeParameters(_ arguments: [ValkeyCommand.Argument]?) -> String {
    let stringArguments = getGenericParameterArguments(arguments)
    //let stringArguments = arguments?.filter { $0.type == .string && !$0.optional } ?? []
    guard stringArguments.count > 0 else { return "" }
    return "<\(stringArguments.map { "\($0.name.swiftTypename): RESPStringRenderable"}.joined(separator: ", "))>"
}
/// construct the generic parameters for a command type
private func genericParameters(_ arguments: [ValkeyCommand.Argument]?) -> String {
    let stringArguments = getGenericParameterArguments(arguments)
    //    let stringArguments = arguments?.filter { $0.type == .string && !$0.optional } ?? []
    guard stringArguments.count > 0 else { return "" }
    return "<\(stringArguments.map { $0.name.swiftTypename }.joined(separator: ", "))>"
}

/// combine stack of names to create an enum name
private func enumName(names: [String]) -> String {
    names.map { $0.upperFirst() }.joined()
}

/// Get the text for a parameter type with its default value if it is optional
private func parameterType(_ parameter: ValkeyCommand.Argument, names: [String], scope: String?, isArray: Bool, genericStrings: Bool) -> String {
    let variableType = variableType(parameter, names: names, scope: scope, isArray: isArray, genericStrings: genericStrings)
    if parameter.type == .pureToken {
        return variableType + " = false"
    } else if parameter.multiple {
        if isArray == false, parameter.optional {
            return variableType + " = nil"
        } else if parameter.optional {
            return variableType + " = []"
        }
    } else if parameter.optional {
        return variableType + " = nil"
    }
    return variableType
}

/// Get the text for a variable type
private func variableType(_ parameter: ValkeyCommand.Argument, names: [String], scope: String?, isArray: Bool, genericStrings: Bool) -> String {
    var parameterString = parameter.type.swiftName
    // if type is a string and non-optional and convert strings to ge
    if parameter.type == .string, !parameter.optional, genericStrings {
        parameterString = parameter.name.swiftTypename
    }
    if case .oneOf = parameter.type {
        parameterString = "\(scope.map {"\($0)."} ?? "")\(enumName(names: names + [parameter.name.swiftTypename]))"
    }
    if case .block = parameter.type {
        parameterString = "\(scope.map {"\($0)."} ?? "")\(enumName(names: names + [parameter.name.swiftTypename]))"
    }
    if parameter.multiple, isArray {
        parameterString = "[\(parameterString)]"
    } else if parameter.optional, parameter.type != .pureToken {
        parameterString.append("?")
    }
    return parameterString
}

private func getResponseType(reply replies: [String]) -> String {
    let replies = replies.filter { $0.hasPrefix("[") || $0.hasPrefix("* [") }
    if replies.count == 1 {
        let returnType = getReturnType(reply: replies[0].dropPrefix("* "))
        return returnType ?? "RESPToken"
    } else if replies.count > 1 {
        var returnType = getReturnType(reply: replies[0].dropPrefix("* "))
        var `optional` = returnType == "Void"
        for value in replies.dropFirst(1) {
            if let returnType2 = getReturnType(reply: value.dropPrefix("* ")) {
                if returnType == "Void" {
                    returnType = returnType2
                    optional = true
                } else if returnType2 != returnType {
                    if returnType2 == "Void" {
                        optional = true
                    } else {
                        if optional {
                            return "RESPToken?"
                        } else {
                            return "RESPToken"
                        }
                    }
                }
            }
        }
        if returnType == "Void" {
            return "RESPToken"
        }
        if optional {
            return "\(returnType ?? "RESPToken")?"
        } else {
            return returnType ?? "RESPToken"
        }
    }
    return "RESPToken"
}
private func getReturnType(reply: some StringProtocol) -> String? {
    if reply.hasPrefix("[") {
        if reply.hasPrefix("[Integer") {
            return "Int"
        } else if reply.hasPrefix("[Double") {
            return "Double"
        } else if reply.hasPrefix("[Bulk string") {
            return "RESPToken"
        } else if reply.hasPrefix("[Verbatim string") {
            return "String"
        } else if reply.hasPrefix("[Simple string") {
            if reply.contains("`OK`") {
                return "Void"
            } else {
                return "String"
            }
        } else if reply.hasPrefix("[Array") || reply.hasPrefix("[Set") {
            return "RESPToken.Array"
        } else if reply.hasPrefix("[Map") {
            return "RESPToken.Map"
        } else if reply.hasPrefix("[Null") || reply.hasPrefix("[Nil") {
            return "Void"
        } else if reply.hasPrefix("[Simple error") {
            return nil
        }
        return "RESPToken"
    }
    return nil
}

extension ValkeyCommand.ArgumentType {
    var swiftName: String {
        switch self {
        case .block: "#"
        case .double: "Double"
        case .integer: "Int"
        case .key: "ValkeyKey"
        case .oneOf: "#"
        case .pattern: "String"
        case .pureToken: "Bool"
        case .string: "String"
        case .unixTime: "Date"
        }
    }
}

extension ValkeyCommand.Argument {
    func respRepresentable(isArray: Bool, genericString: Bool) -> String {
        var variable = self.functionLabel(isArray: multiple && isArray)
        switch self.type
        {
        case .pureToken: return "RESPPureToken(\"\(self.token!)\", \(variable))"
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
            } else if self.type == .string, !self.optional, genericString {
                if self.multiple {
                    variable = "\(variable).map { RESPBulkString($0) }"
                } else {
                    variable = "RESPBulkString(\(variable))"
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
            return "\(self.swiftVariable)"
        } else {
            return self.swiftVariable
        }
    }
}
