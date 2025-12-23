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
