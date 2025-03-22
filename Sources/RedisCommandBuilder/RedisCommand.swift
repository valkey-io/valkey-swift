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
    struct Argument: Decodable {
        let name: String
        let type: ArgumentType
        let multiple: Bool?
        let optional: Bool?
        let token: String?
        let arguments: [Argument]?
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
    let keySpecs: [KeySpec]?

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
