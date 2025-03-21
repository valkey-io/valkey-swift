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
    }
    let summary: String
    let since: String
    let group: String
    let complexity: String?
    let aclCategories: [String]
    let arguments: [Argument]?

    private enum CodingKeys: String, CodingKey {
        case summary
        case since
        case group
        case complexity
        case aclCategories = "acl_categories"
        case arguments
    }
}

struct RESPReplies: Decodable {
    let commands: [String: [String]]
}
