//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore

@_documentation(visibility: internal)
public struct XMessage: RESPTokenDecodable, Sendable {
    public let id: String
    public let fields: [(key: String, value: RESPBulkString)]

    public init(_ token: RESPToken) throws {
        switch token.value {
        case .array(let array):
            let (id, values) = try array.decodeElements(as: (String, RESPToken.Array).self)
            let keyValuePairs = try values.asMap()
                .map { try ($0.key.decode(as: String.self), $0.value.decode(as: RESPBulkString.self)) }
            self.id = id
            self.fields = keyValuePairs
        default:
            throw RESPDecodeError.tokenMismatch(expected: [.array], token: token)
        }
    }

    /// Accesses the value associated with the specified field key in the stream.
    ///
    /// The field collection is an array so subscript access is a O(n) where n is
    /// the number of fields.
    ///
    /// Alternatively the user can create a Dictionary if there are a large number of
    /// fields and many are accessed
    /// ```
    /// let fields = Dictionary(uniqueKeysWithValues: message.fields)
    /// let field = field["fieldName"]
    /// ```
    ///
    /// - Parameter key: The field key to look up.
    /// - Returns: The `RESPToken` value associated with the given key, or `nil` if the key does not exist.
    public subscript(field key: String) -> RESPBulkString? {
        fields.first(where: { $0.key == key })?.value
    }

    /// Accesses the values associated with the specified field key as an array of `RESPToken`.
    ///
    /// The field collection is an array so subscript access is a O(n) where n is
    /// the number of fields.
    ///
    /// - Parameter key: The field key to retrieve values for.
    /// - Returns: An array of `RESPToken` values associated with the given field key.
    public subscript(fields key: String) -> [RESPBulkString] {
        fields.compactMap {
            if $0.key == key {
                $0.value
            } else {
                nil
            }
        }
    }
}

@_documentation(visibility: internal)
public struct XREADGroupMessage: RESPTokenDecodable, Sendable {
    public let id: String
    public let fields: [(key: String, value: RESPBulkString)]?

    public init(_ token: RESPToken) throws {
        switch token.value {
        case .array(let array):
            let (id, values) = try array.decodeElements(as: (String, RESPToken.Array?).self)
            let keyValuePairs = try values.map {
                try $0.asMap()
                    .map { try ($0.key.decode(as: String.self), $0.value.decode(as: RESPBulkString.self)) }
            }
            self.id = id
            self.fields = keyValuePairs
        default:
            throw RESPDecodeError.tokenMismatch(expected: [.array], token: token)
        }
    }
}

@_documentation(visibility: internal)
public struct XREADStreams<Message>: RESPTokenDecodable, Sendable where Message: RESPTokenDecodable & Sendable {
    public struct Stream: Sendable {
        public let key: ValkeyKey
        public let messages: [Message]
    }

    public let streams: [Stream]

    public init(_ token: RESPToken) throws {
        switch token.value {
        case .map(let map):
            self.streams = try map.map {
                let key = try $0.key.decode(as: ValkeyKey.self)
                let messages = try $0.value.decode(as: [Message].self)
                return Stream(key: key, messages: messages)
            }
        default:
            throw RESPDecodeError.tokenMismatch(expected: [.map], token: token)
        }
    }
}

@_documentation(visibility: internal)
public struct XAUTOCLAIMResponse: RESPTokenDecodable, Sendable {
    public let streamID: String
    public let messages: [XMessage]
    public let deletedMessages: [String]

    public init(_ token: RESPToken) throws {
        switch token.value {
        case .array(let array):
            (self.streamID, self.messages, self.deletedMessages) = try array.decodeElements()
        default:
            throw RESPDecodeError.tokenMismatch(expected: [.array], token: token)
        }
    }
}
extension XAUTOCLAIM {
    public typealias Response = XAUTOCLAIMResponse
}

@_documentation(visibility: internal)
public enum XCLAIMResponse: RESPTokenDecodable, Sendable {
    case none
    case messages([XMessage])
    case ids([String])

    public init(_ token: RESPToken) throws {
        switch token.value {
        case .array(let array):
            if array.count == 0 {
                self = .none
                return
            }
            do {
                self = try .messages(array.decode())
            } catch {
                self = try .ids(array.decode())
            }
        default:
            throw RESPDecodeError.tokenMismatch(expected: [.array], token: token)
        }
    }
}

extension XCLAIM {
    public typealias Response = XCLAIMResponse
}

@_documentation(visibility: internal)
public enum XPENDINGResponse: RESPTokenDecodable, Sendable {
    public struct Standard: RESPTokenDecodable, Sendable {
        public struct Consumer: RESPTokenDecodable, Sendable {
            public let consumer: String
            public let count: String

            public init(_ token: RESPToken) throws {
                switch token.value {
                case .array(let array):
                    (self.consumer, self.count) = try array.decodeElements()
                default:
                    throw RESPDecodeError.tokenMismatch(expected: [.array], token: token)
                }
            }
        }
        public let pendingMessageCount: Int
        public let minimumID: String
        public let maximumID: String
        public let consumers: [Consumer]

        public init(_ token: RESPToken) throws {
            switch token.value {
            case .array(let array):
                (self.pendingMessageCount, self.minimumID, self.maximumID, self.consumers) = try array.decodeElements()
            default:
                throw RESPDecodeError.tokenMismatch(expected: [.array], token: token)
            }
        }
    }
    public struct Extended: RESPTokenDecodable, Sendable {
        struct PendingMessage: RESPTokenDecodable, Sendable {
            public let id: String
            public let consumer: String
            public let millisecondsSinceDelivered: Int
            public let numberOfTimesDelivered: Int

            public init(_ token: RESPToken) throws {
                switch token.value {
                case .array(let array):
                    (self.id, self.consumer, self.millisecondsSinceDelivered, self.numberOfTimesDelivered) = try array.decodeElements()
                default:
                    throw RESPDecodeError.tokenMismatch(expected: [.array], token: token)
                }
            }
        }
        let messages: [PendingMessage]

        public init(_ token: RESPToken) throws {
            switch token.value {
            case .array(let array):
                self.messages = try array.decode(as: [PendingMessage].self)
            default:
                throw RESPDecodeError.tokenMismatch(expected: [.array], token: token)
            }
        }
    }

    case standard(Standard)
    case extended(Extended)

    public init(_ token: RESPToken) throws {
        do {
            self = try .standard(.init(token))
        } catch {
            self = try .extended(.init(token))
        }
    }
}
extension XPENDING {
    public typealias Response = XPENDINGResponse
}

@_documentation(visibility: internal)
public typealias XRANGEResponse = [XMessage]
extension XRANGE {
    public typealias Response = XRANGEResponse
}

@_documentation(visibility: internal)
public typealias XREADResponse = XREADStreams<XMessage>?
extension XREAD {
    public typealias Response = XREADResponse
}

@_documentation(visibility: internal)
public typealias XREADGROUPResponse = XREADStreams<XREADGroupMessage>?
extension XREADGROUP {
    public typealias Response = XREADGROUPResponse
}

@_documentation(visibility: internal)
public typealias XREVRANGEResponse = [XMessage]
extension XREVRANGE {
    public typealias Response = XREVRANGEResponse
}

extension XINFO {
    public typealias CONSUMERSResponse = [Consumer]
    public typealias GROUPSResponse = [ConsumerGroup]

    public struct Consumer: RESPTokenDecodable, Sendable {
        /// Consumer's name
        public let name: String
        /// Pending messages for the consumer, which are messages that were delivered but are yet to be acknowledged
        public let pending: Int
        /// The number of milliseconds that have passed since the consumer's last attempted interaction
        public let idle: Int64
        /// The number of milliseconds that have passed since the consumer's last successful interaction
        public let inactive: Int64?

        public init(_ token: RESPToken) throws {
            (self.name, self.pending, self.idle, self.inactive) = try token.decodeMapElements("name", "pending", "idle", "inactive")
        }
    }

    public struct ConsumerGroup: RESPTokenDecodable, Sendable {
        public let name: String
        public let consumers: Int
        public let pending: Int
        public let lastDeliveredId: String
        public let entriesRead: Int?
        public let lag: Int?

        public init(_ token: RESPToken) throws {
            (self.name, self.consumers, self.pending, self.lastDeliveredId, self.entriesRead, self.lag) = try token.decodeMapElements(
                "name",
                "consumers",
                "pending",
                "last-delivered-id",
                "entries-read",
                "lag"
            )
        }
    }
}
extension XINFO.CONSUMERS {
    public typealias Response = XINFO.CONSUMERSResponse
}

extension XINFO.GROUPS {
    public typealias Response = XINFO.GROUPSResponse
}

extension XINFO.STREAM {
    public struct Response: RESPTokenDecodable, Sendable {
        public struct Consumer: RESPTokenDecodable, Sendable {
            /// Consumer name
            let name: String
            /// The UNIX timestamp of the last attempted interaction (Examples: XREADGROUP, XCLAIM, XAUTOCLAIM)
            let seenTime: Int64
            /// The UNIX timestamp of the last successful interaction (Examples: XREADGROUP that actually read
            /// some entries into the PEL, XCLAIM/XAUTOCLAIM that actually claimed some entries)
            let activeTime: Int64?
            /// The number of entries in the PEL: pending messages for the consumer, which are messages that were
            /// delivered but are yet to be acknowledged
            let pelCount: Int
            /// An array with pending entries information, has the same structure as described above, except the
            /// consumer name is omitted (redundant, since anyway we are in a specific consumer context)
            let pending: [XMessage]

            public init(_ token: RESPToken) throws {
                (self.name, self.seenTime, self.activeTime, self.pelCount, self.pending) = try token.decodeMapElements(
                    "name",
                    "seen-time",
                    "active-time",
                    "pel-count",
                    "pending"
                )
            }
        }

        public struct Group: RESPTokenDecodable, Sendable {
            /// the consumer group's name
            public let name: String
            /// The ID of the last entry delivered to the group's consumers
            public let lastDeliveredID: String
            /// The logical "read counter" of the last entry delivered to the group's consumers
            public let entriesRead: Int?
            /// The number of entries in the stream that are still waiting to be delivered to the group's consumers,
            /// or a NULL when that number can't be determined.
            public let lag: Int?
            /// The length of the group's pending entries list (PEL), which are messages that were delivered but are
            /// yet to be acknowledged
            public let pelCount: Int
            /// An array with pending entries information
            public let pending: [XMessage]
            /// An array with consumers information
            public let consumers: [Consumer]

            public init(_ token: RESPToken) throws {
                (self.name, self.lastDeliveredID, self.entriesRead, self.lag, self.pelCount, self.pending, self.consumers) =
                    try token.decodeMapElements(
                        "name",
                        "last-delivered-id",
                        "entries-read",
                        "lag",
                        "pel-count",
                        "pending",
                        "consumers"
                    )
            }
        }
        /// The number of entries in the stream (see XLEN)
        public let length: Int
        /// The number of keys in the underlying radix data structure
        public let numberOfRadixTreeKeys: Int
        /// The number of nodes in the underlying radix data structure
        public let numberOfRadixTreeNodes: Int
        /// The number of consumer groups defined for the stream
        public let numberOfGroups: Int
        /// The ID of the least-recently entry that was added to the stream
        public let lastGeneratedID: String
        /// The maximal entry ID that was deleted from the stream
        public let maxDeletedEntryID: String
        /// The count of all entries added to the stream during its lifetime
        public let entriesAdded: Int
        /// The ID and field-value tuples of the first entry in the stream
        public let firstEntry: XMessage?
        /// The ID and field-value tuples of the last entry in the stream
        public let lastEntry: XMessage?
        /// Array of the stream entries (ID and field-value tuples) in ascending order.
        public let entries: [XMessage]?
        /// Array of groups associated with stream
        public let groups: [Group]?

        public init(_ token: RESPToken) throws {
            var groupsToken: RESPToken
            (
                self.length,
                self.numberOfRadixTreeKeys,
                self.numberOfRadixTreeNodes,
                groupsToken,
                self.lastGeneratedID,
                self.maxDeletedEntryID,
                self.entriesAdded,
                self.firstEntry,
                self.lastEntry,
                self.entries
            ) =
                try token.decodeMapElements(
                    "length",
                    "radix-tree-keys",
                    "radix-tree-nodes",
                    "groups",
                    "last-generated-id",
                    "max-deleted-entry-id",
                    "entries-added",
                    "first-entry",
                    "last-entry",
                    "entries"
                )
            // The group entry can be either the number of groups, or an array of groups
            switch groupsToken.value {
            case .number(let value):
                self.numberOfGroups = Int(value)
                self.groups = nil
            case .array(let array):
                self.numberOfGroups = array.count
                self.groups = try array.decode(as: [Group].self)
            default:
                throw RESPDecodeError.tokenMismatch(expected: [.array, .integer], token: groupsToken)
            }
        }
    }
}
