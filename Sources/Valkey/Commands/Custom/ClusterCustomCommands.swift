//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore

extension CLUSTER.SHARDS {
    public typealias Response = ValkeyClusterDescription
}

package struct ValkeyClusterParseError: Error, Equatable {
    package enum Reason: Error {
        case clusterDescriptionTokenIsNotAnArray
        case shardTokenIsNotAnArrayOrMap
        case nodesTokenIsNotAnArray
        case nodeTokenIsNotAnArrayOrMap
        case slotsTokenIsNotAnArray
        case invalidNodeRole
        case invalidNodeHealth
        case missingRequiredValueForNode
        case shardIsMissingHashSlots
        case shardIsMissingNode
    }

    package var reason: Reason
    package var token: RESPToken

    package init(reason: Reason, token: RESPToken) {
        self.reason = reason
        self.token = token
    }
}

public struct ValkeyClusterDescription: Hashable, Sendable, RESPTokenDecodable {
    /// Details for a node within a cluster shard
    public struct Node: Hashable, Sendable {
        /// Replication role of a given node within a shard (primary or replica)
        public struct Role: Sendable, Hashable, RawRepresentable {
            public static let primary = Role(base: .primary)
            public static let replica = Role(base: .replica)

            public init?(rawValue: String) {
                guard let base = Base(rawValue: rawValue) else {
                    return nil
                }
                self.base = base
            }

            public var rawValue: String {
                self.base.rawValue
            }

            enum Base: String {
                case primary = "master"
                case replica
            }

            private(set) var base: Base

            init(base: Base) {
                self.base = base
            }

        }

        /// Node's health status
        public struct Health: Sendable, Hashable, RawRepresentable {
            public static let online = Health(base: .online)
            public static let failed = Health(base: .failed)
            public static let loading = Health(base: .loading)

            public init?(rawValue: String) {
                guard let base = Base(rawValue: rawValue) else {
                    return nil
                }
                self.base = base
            }

            public var rawValue: String {
                self.base.rawValue
            }

            enum Base: String {
                case online
                case failed
                case loading
            }

            private var base: Base

            init(base: Base) {
                self.base = base
            }
        }

        public var id: String
        public var port: Int?
        public var tlsPort: Int?
        public var ip: String
        public var hostname: String?
        public var endpoint: String
        public var role: Role
        public var replicationOffset: Int
        public var health: Health

        public init(
            id: String,
            port: Int?,
            tlsPort: Int?,
            ip: String,
            hostname: String?,
            endpoint: String,
            role: Role,
            replicationOffset: Int,
            health: Health
        ) {
            self.id = id
            self.port = port
            self.tlsPort = tlsPort
            self.ip = ip
            self.hostname = hostname
            self.endpoint = endpoint
            self.role = role
            self.replicationOffset = replicationOffset
            self.health = health
        }
    }

    public struct Shard: Hashable, Sendable {
        public var slots: HashSlots
        public var nodes: [Node]

        public init(slots: HashSlots, nodes: [Node]) {
            self.slots = slots
            self.nodes = nodes
        }
    }

    public var shards: [Shard]

    public init(fromRESP respToken: RESPToken) throws {
        do {
            self = try Self.makeClusterDescription(respToken: respToken)
        } catch {
            throw ValkeyClusterParseError(reason: error, token: respToken)
        }
    }

    public init(_ shards: [ValkeyClusterDescription.Shard]) {
        self.shards = shards
    }
}

extension ValkeyClusterDescription {
    fileprivate static func makeClusterDescription(respToken: RESPToken) throws(ValkeyClusterParseError.Reason) -> ValkeyClusterDescription {
        guard case .array(let shardsToken) = respToken.value else {
            throw .clusterDescriptionTokenIsNotAnArray
        }
        let shards = try shardsToken.map { shardToken throws(ValkeyClusterParseError.Reason) in
            try ValkeyClusterDescription.Shard(shardToken)
        }
        return ValkeyClusterDescription(shards)
    }
}

extension HashSlots {
    fileprivate init(_ iterator: inout RESPToken.Array.Iterator) throws(ValkeyClusterParseError.Reason) {
        guard let token = iterator.next() else {
            throw .slotsTokenIsNotAnArray
        }
        self = try HashSlots(token)
    }

    fileprivate init(_ token: RESPToken) throws(ValkeyClusterParseError.Reason) {
        guard case .array(let array) = token.value else {
            throw .slotsTokenIsNotAnArray
        }

        var slotRanges = [ClosedRange<HashSlot>]()
        slotRanges.reserveCapacity(array.count / 2)

        var slotsIterator = array.makeIterator()
        while case .number(let rangeStart) = slotsIterator.next()?.value,
            case .number(let rangeEnd) = slotsIterator.next()?.value,
            let start = HashSlot(rawValue: rangeStart),
            let end = HashSlot(rawValue: rangeEnd),
            start <= end
        {
            slotRanges.append(ClosedRange<HashSlot>(uncheckedBounds: (start, end)))
        }

        self = slotRanges
    }
}

extension [ValkeyClusterDescription.Node] {
    fileprivate init(_ iterator: inout RESPToken.Array.Iterator) throws(ValkeyClusterParseError.Reason) {
        guard let token = iterator.next() else {
            throw .nodesTokenIsNotAnArray
        }
        self = try Self(token)
    }

    fileprivate init(_ token: RESPToken) throws(ValkeyClusterParseError.Reason) {
        guard case .array(let array) = token.value else {
            throw .nodesTokenIsNotAnArray
        }

        self = try array.map { token throws(ValkeyClusterParseError.Reason) in
            try ValkeyClusterDescription.Node(token)
        }
    }
}

extension ValkeyClusterDescription.Shard {
    fileprivate init(_ token: RESPToken) throws(ValkeyClusterParseError.Reason) {
        switch token.value {
        case .array(let array):
            self = try Self.makeFromTokenSequence(MapStyleArray(underlying: array))

        case .map(let map):
            let mapped = map.lazy.compactMap { (keyNode, value) -> (String, RESPToken)? in
                if let key = try? String(fromRESP: keyNode) {
                    return (key, value)
                } else {
                    return nil
                }
            }
            self = try Self.makeFromTokenSequence(mapped)

        default:
            throw ValkeyClusterParseError.Reason.shardTokenIsNotAnArrayOrMap
        }
    }

    fileprivate static func makeFromTokenSequence<TokenSequence: Sequence>(
        _ sequence: TokenSequence
    ) throws(ValkeyClusterParseError.Reason) -> Self where TokenSequence.Element == (String, RESPToken) {
        var slotRanges = HashSlots()
        var nodes: [ValkeyClusterDescription.Node] = []

        for (keyToken, value) in sequence {
            switch keyToken {
            case "slots":
                slotRanges = try HashSlots(value)

            case "nodes":
                nodes = try [ValkeyClusterDescription.Node](value)

            default:
                continue
            }
        }

        if nodes.isEmpty { throw .shardIsMissingNode }
        if slotRanges.isEmpty { throw .shardIsMissingHashSlots }

        return .init(slots: slotRanges, nodes: nodes)
    }
}

extension ValkeyClusterDescription.Node {
    fileprivate init(_ token: RESPToken) throws(ValkeyClusterParseError.Reason) {
        switch token.value {
        case .array(let array):
            self = try Self.makeFromTokenSequence(MapStyleArray(underlying: array))

        case .map(let map):
            let mapped = map.lazy.compactMap { (keyNode, value) -> (String, RESPToken)? in
                if let key = try? String(fromRESP: keyNode) {
                    return (key, value)
                } else {
                    return nil
                }
            }
            self = try Self.makeFromTokenSequence(mapped)

        default:
            throw .nodeTokenIsNotAnArrayOrMap
        }
    }

    fileprivate static func makeFromTokenSequence<TokenSequence: Sequence>(
        _ sequence: TokenSequence
    ) throws(ValkeyClusterParseError.Reason) -> Self where TokenSequence.Element == (String, RESPToken) {
        var id: String?
        var port: Int64?
        var tlsPort: Int64?
        var ip: String?
        var hostname: String?
        var endpoint: String?
        var role: ValkeyClusterDescription.Node.Role?
        var replicationOffset: Int64?
        var health: ValkeyClusterDescription.Node.Health?

        var nodeIterator = sequence.makeIterator()
        while let (key, nodeVal) = nodeIterator.next() {
            switch key {
            case "id":
                id = try? String(fromRESP: nodeVal)
            case "port":
                port = try? Int64(fromRESP: nodeVal)
            case "tls-port":
                tlsPort = try? Int64(fromRESP: nodeVal)
            case "ip":
                ip = try? String(fromRESP: nodeVal)
            case "hostname":
                hostname = try? String(fromRESP: nodeVal)
            case "endpoint":
                endpoint = try? String(fromRESP: nodeVal)
            case "role":
                guard let roleString = try? String(fromRESP: nodeVal), let roleValue = ValkeyClusterDescription.Node.Role(rawValue: roleString) else {
                    throw .invalidNodeRole
                }
                role = roleValue

            case "replication-offset":
                replicationOffset = try? Int64(fromRESP: nodeVal)
            case "health":
                guard let healthString = try? String(fromRESP: nodeVal),
                    let healthValue = ValkeyClusterDescription.Node.Health(rawValue: healthString)
                else {
                    throw .invalidNodeHealth
                }
                health = healthValue

            default:
                // we ignore unexpected keys to be forward compliant
                continue
            }
        }
        guard let id = id, let ip = ip, let endpoint = endpoint, let role = role,
            let replicationOffset = replicationOffset, let health = health
        else {
            throw .missingRequiredValueForNode
        }

        // we need at least port or tlsport
        if port == nil && tlsPort == nil {
            throw .missingRequiredValueForNode
        }

        return ValkeyClusterDescription.Node(
            id: id,
            port: port.flatMap { Int($0) },
            tlsPort: tlsPort.flatMap { Int($0) },
            ip: ip,
            hostname: hostname,
            endpoint: endpoint,
            role: role,
            replicationOffset: Int(replicationOffset),
            health: health
        )
    }
}

struct MapStyleArray: Sequence {
    var underlying: RESPToken.Array

    func makeIterator() -> Iterator {
        Iterator(underlying: self.underlying.makeIterator())
    }

    struct Iterator: IteratorProtocol {
        var underlying: RESPToken.Array.Iterator

        mutating func next() -> (String, RESPToken)? {
            guard let nodeKey = self.underlying.next(),
                let key = try? String(fromRESP: nodeKey),
                let nodeVal = self.underlying.next()
            else {
                return nil
            }

            return (key, nodeVal)
        }
    }
}
