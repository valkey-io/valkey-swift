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

public struct XREADEvent: RESPTokenDecodable, Sendable {
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

public struct XREADGroupEvent: RESPTokenDecodable, Sendable {
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

public struct XREADStreams<Event>: RESPTokenDecodable, Sendable where Event: RESPTokenDecodable & Sendable {
    public struct Stream: Sendable {
        public let key: ValkeyKey
        public let events: [Event]
    }

    public let streams: [Stream]

    public init(fromRESP token: RESPToken) throws {
        switch token.value {
        case .map(let map):
            self.streams = try map.map {
                let key = try $0.key.decode(as: ValkeyKey.self)
                let events = try $0.value.decode(as: [Event].self)
                return Stream(key: key, events: events)
            }
        default:
            throw RESPParsingError(code: .unexpectedType, buffer: token.base)
        }
    }
}

extension XRANGE {
    public typealias Response = [XREADEvent]
}

extension XREAD {
    public typealias Response = XREADStreams<XREADEvent>?
}

extension XREADGROUP {
    public typealias Response = XREADStreams<XREADGroupEvent>?
}

extension XREVRANGE {
    public typealias Response = [XREADEvent]
}
