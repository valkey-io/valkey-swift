//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift project
//
// Copyright (c) 2025 the valkey-swift authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See valkey-swift/CONTRIBUTORS.txt for the list of valkey-swift authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

public struct XREADMessage: RESPTokenDecodable, Sendable {
    public let id: String
    public let fields: [(key: String, value: String)]

    public init(fromRESP token: RESPToken) throws {
        switch token.value {
        case .array(let array):
            let (id, values) = try array.decodeElements(as: (String, RESPToken.Array).self)
            let keyValuePairs = try values.decodeKeyValueElements(key: String.self, value: String.self)
            self.id = id
            self.fields = keyValuePairs
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
}

public struct XREADGroupMessage: RESPTokenDecodable, Sendable {
    public let id: String
    public let fields: [(key: String, value: String)]?

    public init(fromRESP token: RESPToken) throws {
        switch token.value {
        case .array(let array):
            let (id, values) = try array.decodeElements(as: (String, RESPToken.Array?).self)
            let keyValuePairs = try values?.decodeKeyValueElements(key: String.self, value: String.self)
            self.id = id
            self.fields = keyValuePairs
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
}

public struct XREADStreams<Message>: RESPTokenDecodable, Sendable where Message: RESPTokenDecodable & Sendable {
    public struct Stream: Sendable {
        public let key: ValkeyKey
        public let messages: [Message]
    }

    public let streams: [Stream]

    public init(fromRESP token: RESPToken) throws {
        switch token.value {
        case .map(let map):
            self.streams = try map.map {
                let key = try $0.key.decode(as: ValkeyKey.self)
                let messages = try $0.value.decode(as: [Message].self)
                return Stream(key: key, messages: messages)
            }
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
}

extension XAUTOCLAIM {
    public struct Response: RESPTokenDecodable, Sendable {
        public let streamID: String
        public let messsages: [XREADMessage]
        public let deletedMessages: [String]

        public init(fromRESP token: RESPToken) throws {
            switch token.value {
            case .array(let array):
                (self.streamID, self.messsages, self.deletedMessages) = try array.decodeElements()
            default:
                throw RESPParsingError(code: .unexpectedType, buffer: token.base)
            }
        }
    }
}

extension XRANGE {
    public typealias Response = [XREADMessage]
}

extension XREAD {
    public typealias Response = XREADStreams<XREADMessage>?
}

extension XREADGROUP {
    public typealias Response = XREADStreams<XREADGroupMessage>?
}

extension XREVRANGE {
    public typealias Response = [XREADMessage]
}
