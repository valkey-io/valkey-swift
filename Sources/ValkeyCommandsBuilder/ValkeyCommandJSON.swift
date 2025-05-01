import Foundation

struct ValkeyCommands: Decodable {
    let commands: [String: ValkeyCommand]

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.commands = try container.decode([String: ValkeyCommand].self)
    }
}

struct ValkeyCommand: Decodable {
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
            self.token = try container.decodeIfPresent(String.self, forKey: .token)
            self.arguments = try container.decodeIfPresent([Argument].self, forKey: .arguments)
            self.keySpecIndex = try container.decodeIfPresent(Int.self, forKey: .keySpecIndex)
        }

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
            self.combinedWithCount =
                switch keySpec?.findKeys {
                case .keynum: true
                case .range, .unknown: false
                case .none: false
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
    let summary: String
    let since: String
    let group: String
    let complexity: String?
    let deprecatedSince: String?
    let replacedBy: String?
    let aclCategories: [String]?
    let arguments: [Argument]?

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.summary = try container.decode(String.self, forKey: .summary)
        self.since = try container.decode(String.self, forKey: .since)
        self.group = try container.decode(String.self, forKey: .group)
        self.complexity = try container.decodeIfPresent(String.self, forKey: .complexity)
        self.deprecatedSince = try container.decodeIfPresent(String.self, forKey: .deprecatedSince)
        self.replacedBy = try container.decodeIfPresent(String.self, forKey: .replacedBy)
        self.aclCategories = try container.decodeIfPresent([String].self, forKey: .aclCategories)
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
        case deprecatedSince = "deprecated_since"
        case replacedBy = "replaced_by"
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
