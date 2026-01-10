//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore

@_documentation(visibility: internal)
public struct XREADMessage: RESPTokenDecodable, Sendable {
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
    public let messages: [XREADMessage]
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
    case messages([XREADMessage])
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
public typealias XRANGEResponse = [XREADMessage]
extension XRANGE {
    public typealias Response = XRANGEResponse
}

@_documentation(visibility: internal)
public typealias XREADResponse = XREADStreams<XREADMessage>?
extension XREAD {
    public typealias Response = XREADResponse
}

@_documentation(visibility: internal)
public typealias XREADGROUPResponse = XREADStreams<XREADGroupMessage>?
extension XREADGROUP {
    public typealias Response = XREADGROUPResponse
}

@_documentation(visibility: internal)
public typealias XREVRANGEResponse = [XREADMessage]
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
        public let idle: Int
        /// The number of milliseconds that have passed since the consumer's last successful interaction
        public let inactive: Int

        public init(_ token: RESPToken) throws {
            switch token.value {
            case .array(let array):
                let map = try array.asMap()
                var name: String?
                var pending: Int?
                var idle: Int?
                var inactive: Int?

                for entry in map {
                    switch try entry.key.decode(as: String.self) {
                    case "name": name = try entry.value.decode(as: String.self)
                    case "pending": pending = try entry.value.decode(as: Int.self)
                    case "idle": idle = try entry.value.decode(as: Int.self)
                    case "inactive": inactive = try entry.value.decode(as: Int.self)
                    default: break
                    }
                }
                guard let name else { throw RESPDecodeError.missingToken(key: "name", token: token) }
                guard let pending else { throw RESPDecodeError.missingToken(key: "pending", token: token) }
                guard let idle else { throw RESPDecodeError.missingToken(key: "idle", token: token) }
                guard let inactive else { throw RESPDecodeError.missingToken(key: "inactive", token: token) }

                self.name = name
                self.pending = pending
                self.idle = idle
                self.inactive = inactive
            default:
                throw RESPDecodeError.tokenMismatch(expected: [.array], token: token)
            }
        }
    }

    public struct ConsumerGroup: RESPTokenDecodable, Sendable {
        public let name: String
        public let consumers: Int
        public let pending: Int
        public let lastDeliveredId: String
        public let entriesRead: Int
        public let lag: Int?

        public init(_ token: RESPToken) throws {
            switch token.value {
            case .array(let array):
                let map = try array.asMap()
                var name: String?
                var consumers: Int?
                var pending: Int?
                var lastDeliveredId: String?
                var entriesRead: Int?
                var lag: Int?

                for entry in map {
                    switch try entry.key.decode(as: String.self) {
                    case "name": name = try entry.value.decode(as: String.self)
                    case "consumers": consumers = try entry.value.decode(as: Int.self)
                    case "pending": pending = try entry.value.decode(as: Int.self)
                    case "last-delivered-id": lastDeliveredId = try entry.value.decode(as: String.self)
                    case "entries-read": entriesRead = try entry.value.decode(as: Int.self)
                    case "lag": lag = try entry.value.decode(as: Int?.self)
                    default: break
                    }
                }
                guard let name else { throw RESPDecodeError.missingToken(key: "name", token: token) }
                guard let consumers else { throw RESPDecodeError.missingToken(key: "consumers", token: token) }
                guard let pending else { throw RESPDecodeError.missingToken(key: "pending", token: token) }
                guard let lastDeliveredId else { throw RESPDecodeError.missingToken(key: "last-delivered-id", token: token) }
                guard let entriesRead else { throw RESPDecodeError.missingToken(key: "entries-read", token: token) }

                self.name = name
                self.consumers = consumers
                self.pending = pending
                self.lastDeliveredId = lastDeliveredId
                self.entriesRead = entriesRead
                self.lag = lag
            default:
                throw RESPDecodeError.tokenMismatch(expected: [.array], token: token)
            }
        }
    }

}
extension XINFO.CONSUMERS {
    public typealias Response = XINFO.CONSUMERSResponse
}

extension XINFO.GROUPS {
    public typealias Response = XINFO.GROUPSResponse
}
