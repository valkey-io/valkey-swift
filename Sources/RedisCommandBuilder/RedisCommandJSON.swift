import Foundation

struct RedisCommands: Decodable {
    let commands: [String: RedisCommand]

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.commands = try container.decode([String: RedisCommand].self)
    }
}

struct RedisCommand: Decodable {
    enum ArgumentType: String, Decodable {
        case integer
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
        let multiple: Bool?
        let optional: Bool?
        let token: String?
        let arguments: [Argument]?
        let keySpecIndex: Int?

        private enum CodingKeys: String, CodingKey {
            case name
            case type
            case multiple
            case optional
            case token
            case arguments
            case keySpecIndex = "key_spec_index"
        }
    }
    struct Argument: Decodable {
        let name: String
        let type: ArgumentType
        let multiple: Bool
        let optional: Bool
        let token: String?
        let arguments: [Argument]?
        let combinedWithCount: Bool?

        init(argument: InternalArgument, keySpec: KeySpec?) {
            self.name = argument.name
            self.type = argument.type
            self.multiple = argument.multiple ?? false
            self.optional = argument.optional ?? false
            self.token = argument.token
            self.arguments = argument.arguments
            self.combinedWithCount = keySpec?.findKeys.type == .keynum
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.type = try container.decode(ArgumentType.self, forKey: .type)
            self.multiple = try container.decodeIfPresent(Bool.self, forKey: .multiple) ?? false
            self.optional = try container.decodeIfPresent(Bool.self, forKey: .optional) ?? false
            self.token = try container.decodeIfPresent(String.self, forKey: .token)
            self.arguments = try container.decodeIfPresent([Argument].self, forKey: .arguments)
            self.combinedWithCount = false
        }

        private enum CodingKeys: String, CodingKey {
            case name
            case type
            case multiple
            case optional
            case token
            case arguments
        }
    }
    struct KeySpec: Decodable {
        struct BeginSearch: Decodable {
            enum SearchType: String, Decodable {
                case index
                case keyword
                case unknown
            }
            struct Spec: Decodable {
                let index: Int?
                let keyword: String?
                let startFrom: Int?
            }
            let type: SearchType
            let spec: Spec
        }
        struct FindKeys: Decodable {
            enum FindKeysType: String, Decodable {
                case range
                case keynum
                case unknown
            }
            struct Spec: Decodable {
                let keynumidx: Int?
                let lastkey: Int
                let keystep: Int
                let limit: Int
            }
            let type: FindKeysType
        }
        let beginSearch: BeginSearch
        let findKeys: FindKeys

        private enum CodingKeys: String, CodingKey {
            case beginSearch = "begin_search"
            case findKeys = "find_keys"
        }
    }
    let summary: String
    let since: String
    let group: String
    let complexity: String?
    let aclCategories: [String]
    let arguments: [Argument]?

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.summary = try container.decode(String.self, forKey: .summary)
        self.since = try container.decode(String.self, forKey: .since)
        self.group = try container.decode(String.self, forKey: .group)
        self.complexity = try container.decodeIfPresent(String.self, forKey: .complexity)
        self.aclCategories = try container.decode([String].self, forKey: .aclCategories)
        if let arguments = try container.decodeIfPresent([InternalArgument].self, forKey: .arguments) {
            if let keySpecs = try container.decodeIfPresent([KeySpec].self, forKey: .keySpecs) {
                // combine argument and keyspec
                var arguments = arguments.map { Argument(argument: $0, keySpec: $0.keySpecIndex.map { keySpecs[$0] }) }
                // remove array counts before arrays
                if let index = arguments.firstIndex(where: { $0.combinedWithCount == true }) {
                    let previousIndex = arguments.index(before: index)
                    arguments.remove(at: previousIndex)
                    self.arguments = arguments
                } else {
                    self.arguments = arguments
                }
            } else {
                self.arguments = arguments.map { .init(argument: $0, keySpec: nil) }
            }
        } else {
            self.arguments = nil
        }
    }

    private enum CodingKeys: String, CodingKey {
        case summary
        case since
        case group
        case complexity
        case aclCategories = "acl_categories"
        case arguments
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
