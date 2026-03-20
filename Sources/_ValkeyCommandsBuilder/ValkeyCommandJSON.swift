//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import Foundation

final class ValkeyCommands: Decodable {
    var commands: [String: ValkeyCommand]

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.commands = try container.decode([String: ValkeyCommand].self)
    }
}

struct ValkeyCommand: Decodable {
    enum ArgumentType: String, Decodable {
        case integer
        case float
        case double
        case string
        case key
        case block
        case oneOf = "oneof"
        case pureToken = "pure-token"
        case unixTime = "unix-time"
        case pattern
    }
    struct InternalArgument: Decodable {
        let name: String
        let type: ArgumentType
        let multiple: Bool
        let optional: Bool
        let token: String?
        let multipleToken: Bool
        var arguments: [Argument]?
        let keySpecIndex: Int?

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.type = try container.decode(ArgumentType.self, forKey: .type)
            var multiple = false
            do {
                multiple = try container.decodeIfPresent(Bool.self, forKey: .multiple) ?? false
            } catch {
                let value = try container.decodeIfPresent(String.self, forKey: .multiple)
                multiple = value == "true"
            }
            self.multiple = multiple
            self.optional = try container.decodeIfPresent(Bool.self, forKey: .optional) ?? false
            self.multipleToken = try container.decodeIfPresent(Bool.self, forKey: .multipleToken) ?? false
            var token = try container.decodeIfPresent(String.self, forKey: .token)
            if token == "\"\"" {
                token = ""
            }
            self.token = token
            if let arguments = try container.decodeIfPresent([InternalArgument].self, forKey: .arguments) {
                self.arguments = Self.processArguments(arguments, keySpecs: nil)
            } else {
                self.arguments = nil
            }
            self.keySpecIndex = try container.decodeIfPresent(Int.self, forKey: .keySpecIndex)
        }

        static func processArguments(_ arguments: [InternalArgument], keySpecs: [KeySpec]?) -> [Argument] {
            var arguments = arguments.map { Argument(argument: $0, keySpec: $0.keySpecIndex.flatMap { keySpecs?[$0] }) }
            if arguments.count >= 2 {
                var index = arguments.startIndex
                var prevIndex = index
                index += 1
                while index != arguments.endIndex {
                    if arguments[prevIndex].type == .integer, arguments[prevIndex].name == "count", arguments[index].multiple == true {
                        arguments[index].combinedWithCount = .itemCount
                    }
                    index += 1
                    prevIndex += 1
                }
            }

            // combine argument and keyspec
            // remove counts for arrays flagged with `combinedWithCount`
            var index = arguments.startIndex
            while let arrayIndex = arguments[index...].firstIndex(where: { $0.combinedWithCount != .none }) {
                let previousIndex = arguments.index(before: arrayIndex)
                arguments.remove(at: previousIndex)
                index = arrayIndex
            }
            return arguments.map { argument in
                guard argument.type == .block else { return argument }
                guard let arguments = argument.arguments else { return argument }
                switch arguments.count {
                case 1:
                    // Collapse blocks that consist of one argument into that argument
                    guard argument.token == nil || arguments[0].token == nil else { return argument }
                    var newArgument = arguments[0]
                    newArgument.name = argument.name
                    newArgument.token = argument.token ?? newArgument.token
                    newArgument.optional = argument.optional || newArgument.optional
                    newArgument.multiple = argument.multiple || newArgument.multiple
                    newArgument.multipleToken = argument.multipleToken || newArgument.multipleToken
                    return newArgument
                case 2:
                    // Collapse blocks that consist of a pure token and one other single argument into
                    // a none block type with a token attribute
                    guard argument.token == nil else { return argument }
                    guard arguments[0].type == .pureToken else { return argument }
                    guard arguments[1].optional == false else { return argument }
                    guard arguments[1].token == nil else { return argument }
                    guard !(arguments[1].multiple && argument.multiple) else { return argument }
                    var newArgument = arguments[1]
                    newArgument.name = argument.name
                    newArgument.token = arguments[0].token
                    newArgument.optional = argument.optional
                    newArgument.multiple = argument.multiple || newArgument.multiple
                    newArgument.multipleToken = argument.multiple
                    return newArgument
                default:
                    return argument
                }
            }
        }

        private enum CodingKeys: String, CodingKey {
            case name
            case type
            case multiple
            case optional
            case token
            case multipleToken = "multiple_token"
            case arguments
            case keySpecIndex = "key_spec_index"
        }
    }
    struct Argument: Decodable {
        enum ArrayCount: String, Decodable {
            case none
            case parameterCount
            case itemCount
        }

        init(
            name: String,
            type: ValkeyCommand.ArgumentType,
            multiple: Bool = false,
            optional: Bool = false,
            multipleToken: Bool = false,
            token: String? = nil,
            arguments: [ValkeyCommand.Argument]? = nil,
            combinedWithCount: ArrayCount = .none
        ) {
            self.name = name
            self.type = type
            self.multiple = multiple
            self.optional = optional
            self.multipleToken = multipleToken
            self.token = token
            self.arguments = arguments
            self.combinedWithCount = combinedWithCount
        }

        var name: String
        var type: ArgumentType
        var multiple: Bool
        var optional: Bool
        var multipleToken: Bool
        var token: String?
        var arguments: [Argument]?
        var combinedWithCount: ArrayCount

        init(argument: InternalArgument, keySpec: KeySpec?) {
            self.name = argument.name
            self.type = argument.type
            self.multiple = argument.multiple
            self.optional = argument.optional
            self.multipleToken = argument.multipleToken
            self.token = argument.token
            self.arguments = argument.arguments
            self.combinedWithCount =
                switch keySpec?.findKeys {
                case .keynum: .itemCount
                case .range, .unknown: .none
                case .none: .none
                }
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.type = try container.decode(ArgumentType.self, forKey: .type)
            var multiple = false
            do {
                multiple = try container.decodeIfPresent(Bool.self, forKey: .multiple) ?? false
            } catch {
                let value = try container.decodeIfPresent(String.self, forKey: .multiple)
                multiple = value == "true"
            }
            self.multiple = multiple
            self.optional = try container.decodeIfPresent(Bool.self, forKey: .optional) ?? false
            self.multipleToken = try container.decodeIfPresent(Bool.self, forKey: .multipleToken) ?? false
            var token = try container.decodeIfPresent(String.self, forKey: .token)
            if token == "\"\"" {
                token = ""
            }
            self.token = token
            if let arguments = try container.decodeIfPresent([InternalArgument].self, forKey: .arguments) {
                self.arguments = InternalArgument.processArguments(arguments, keySpecs: nil)
            } else {
                self.arguments = nil
            }
            self.combinedWithCount = .none
        }

        private enum CodingKeys: String, CodingKey {
            case name
            case type
            case multiple
            case optional
            case multipleToken = "multiple_token"
            case token
            case arguments
        }
    }

    enum ReplySchema: Decodable {
        enum Const: Decodable {
            case string(String)
            case integer(Int)

            init(from decoder: any Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let string = try? container.decode(String.self) {
                    self = .string(string)
                } else if let integer = try? container.decode(Int.self) {
                    self = .integer(integer)
                } else {
                    throw DecodingError.typeMismatch(
                        Const.self,
                        .init(codingPath: decoder.codingPath, debugDescription: "Cannot decode as String or Int")
                    )
                }
            }

        }
        struct Response: Decodable {
            enum ResponseType: String, Decodable {
                case number
                case integer
                case string
                case array
                case object
                case null
                case unknown
            }
            var description: String?
            var type: ResponseType
            var const: Const?
            var items: [ReplySchema]?

            init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.description = try container.decodeIfPresent(String.self, forKey: .description)
                if let const = try container.decodeIfPresent(Const.self, forKey: .const) {
                    switch const {
                    case .string: self.type = .string
                    case .integer: self.type = .integer
                    }
                    self.const = const
                    self.items = nil
                } else {
                    self.type = try container.decodeIfPresent(ResponseType.self, forKey: .type) ?? .unknown
                    self.items =
                        if let items = try? container.decodeIfPresent([ReplySchema].self, forKey: .items) {
                            items
                        } else if let item = try container.decodeIfPresent(ReplySchema.self, forKey: .items) {
                            [item]
                        } else {
                            nil
                        }
                    self.const = nil
                }
            }
            private enum CodingKeys: String, CodingKey {
                case description
                case type
                case const
                case items
            }
        }
        case oneOf(description: String?, responses: [Response])
        case response(Response)

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let responses = try container.decodeIfPresent([Response].self, forKey: .oneOf) {
                let description = try container.decodeIfPresent(String.self, forKey: .description)
                self = .oneOf(description: description, responses: responses)
            } else if let responses = try container.decodeIfPresent([Response].self, forKey: .anyOf) {
                let description = try container.decodeIfPresent(String.self, forKey: .description)
                self = .oneOf(description: description, responses: responses)
            } else {
                let singleValueContainer = try decoder.singleValueContainer()
                self = .response(try singleValueContainer.decode(Response.self))
            }
        }

        private enum CodingKeys: String, CodingKey {
            case oneOf
            case anyOf
            case description
        }
    }

    struct KeySpec: Decodable {
        enum BeginSearch: Decodable {
            struct Index: Decodable {
                let pos: Int
            }
            struct KeyWord: Decodable {
                let keyword: String
                let startFrom: Int

                private enum CodingKeys: String, CodingKey {
                    case keyword
                    case startFrom = "startfrom"
                }
            }
            case index(Index)
            case keyword(KeyWord)
            case unknown

            init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                if let index = try container.decodeIfPresent(Index.self, forKey: .index) {
                    self = .index(index)
                } else if let keyword = try container.decodeIfPresent(KeyWord.self, forKey: .keyword) {
                    self = .keyword(keyword)
                } else if try container.decodeNil(forKey: .unknown) {
                    self = .unknown
                } else {
                    throw DecodingError.dataCorrupted(
                        .init(codingPath: decoder.codingPath, debugDescription: "Cannot fine either keyword or index in \(container.allKeys)")
                    )
                }
            }
            private enum CodingKeys: String, CodingKey {
                case index
                case keyword
                case unknown
            }
        }
        enum FindKeys: Decodable {
            struct KeyNum: Decodable {
                let keynumidx: Int
                let firstkey: Int
                let step: Int
            }
            struct Range: Decodable {
                let lastkey: Int
                let step: Int
                let limit: Int
            }
            case range(Range)
            case keynum(KeyNum)
            case unknown

            init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                if let range = try container.decodeIfPresent(Range.self, forKey: .range) {
                    self = .range(range)
                } else if let keyNum = try container.decodeIfPresent(KeyNum.self, forKey: .keynum) {
                    self = .keynum(keyNum)
                } else if try container.decodeNil(forKey: .unknown) {
                    self = .unknown
                } else {
                    throw DecodingError.dataCorrupted(
                        .init(codingPath: decoder.codingPath, debugDescription: "Cannot fine range in \(container.allKeys)")
                    )
                }
            }

            private enum CodingKeys: String, CodingKey {
                case range
                case keynum
                case unknown
            }
        }
        let beginSearch: BeginSearch
        let findKeys: FindKeys

        private enum CodingKeys: String, CodingKey {
            case beginSearch = "begin_search"
            case findKeys = "find_keys"
        }
    }
    var summary: String
    var since: String?
    var group: String
    var complexity: String?
    var function: String?
    var history: [[String]]?
    var deprecatedSince: String?
    var replacedBy: String?
    var docFlags: [String]?
    var commandFlags: [String]?
    var aclCategories: [String]?
    var arguments: [Argument]?
    var replySchema: ReplySchema?

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.summary = try container.decode(String.self, forKey: .summary)
        self.since = try container.decodeIfPresent(String.self, forKey: .since)
        self.group = try container.decode(String.self, forKey: .group)
        self.complexity = try container.decodeIfPresent(String.self, forKey: .complexity)
        self.function = try container.decodeIfPresent(String.self, forKey: .function)
        self.history = try container.decodeIfPresent([[String]].self, forKey: .history)
        self.deprecatedSince = try container.decodeIfPresent(String.self, forKey: .deprecatedSince)
        self.replacedBy = try container.decodeIfPresent(String.self, forKey: .replacedBy)
        self.docFlags = try container.decodeIfPresent([String].self, forKey: .docFlags)
        self.commandFlags = try container.decodeIfPresent([String].self, forKey: .commandFlags)
        self.aclCategories = try container.decodeIfPresent([String].self, forKey: .aclCategories)
        if let arguments = try container.decodeIfPresent([InternalArgument].self, forKey: .arguments) {
            let keySpecs = try container.decodeIfPresent([KeySpec].self, forKey: .keySpecs)
            self.arguments = InternalArgument.processArguments(arguments, keySpecs: keySpecs)
        } else {
            self.arguments = nil
        }
        self.replySchema = try container.decodeIfPresent(ReplySchema.self, forKey: .replySchema)
    }

    private enum CodingKeys: String, CodingKey {
        case summary
        case since
        case group
        case complexity
        case function
        case history
        case deprecatedSince = "deprecated_since"
        case replacedBy = "replaced_by"
        case docFlags = "doc_flags"
        case commandFlags = "command_flags"
        case aclCategories = "acl_categories"
        case arguments
        case replySchema = "reply_schema"
        case keySpecs = "key_specs"
    }
}

struct RESPReplies: Decodable {
    let commands: [String: [String]]

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.commands = try container.decode([String: [String]].self)
    }
}
