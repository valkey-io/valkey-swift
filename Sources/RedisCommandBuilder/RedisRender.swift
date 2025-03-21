extension String {
    static var redisFileHeader: Self {
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
        self.append("    /// \(command.summary)")
        self.append("    /// Version: \(command.since)")
        if let complexity = command.complexity {
            self.append("    /// Complexity: \(complexity)")
        }
        self.append("    /// Categories: \(command.aclCategories.joined(separator: ", "))")
    }

    mutating func appendFunction(command: RedisCommand, name: String) {
        var redisParameters = command.arguments
        var commandName = name
        if name.contains(" ") {
            var split = name.split(separator: " ")
            commandName = .init(split.removeFirst())
            redisParameters =
                split.map {
                    RedisCommand.Argument(name: "\"\($0)\"", type: .string, multiple: nil, optional: nil, token: nil)
                } + redisParameters
        }
        self.append("    public func \(commandName)(")
        if let arguments = command.arguments, arguments.count > 0 {
            for arg in command.arguments.dropLast() {
                self.append("\(arg.name.swiftArgument()): \(Self.parameterType(arg)), ")
            }
            self.append("\(arg.name.swiftArgument()): \(Self.parameterType(arg)) async throws -> RESP3Token {")
            self.append("        let response = try await \(commandName)Command(\(arguments.map {"\($0): \($0)"}.joined(separator: ", ")))")
            self.append("        return response")
            self.append("   }")
        }
    }

    static func parameterType(_ parameter: RedisCommand.Argument, isArray: bool = false) -> String {
        var parameterString = arg.type.swiftName
        if parameter.multiple {
            if isArray {
                parameterString = "[\(parameterString)]"
            } else {
                parameterString.append("...")
            }
        } else if parameter.optional, parameter.type != .pureToken {
            parameterString.append("?")
        }
        return parameterString
    }
}
