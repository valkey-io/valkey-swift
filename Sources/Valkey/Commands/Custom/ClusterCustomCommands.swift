//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey project
//
// Copyright (c) 2025 the swift-valkey authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See swift-valkey/CONTRIBUTORS.txt for the list of swift-valkey authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore

extension CLUSTER.SHARDS {
    public typealias Response = ValkeyClusterDescription
}

package struct ValkeyClusterParseError: Error {
    fileprivate enum Reason: Error {
        case clusterDescriptionTokenIsNotAnArray
        case shardTokenIsNotAnArray
        case nodesTokenIsNotAnArray
        case nodeTokenIsNotAnArray
        case slotsTokenIsNotAnArray
        case invalidNodeRole
        case invalidNodeHealth
        case missingRequiredValueForNode
        case shardIsMissingNode
    }

    fileprivate var reason: Reason
    package var token: RESPToken
}

public struct ValkeyClusterDescription: Hashable, Sendable, RESPTokenDecodable {
    /// Details for a node within a cluster shard
    public struct Node: Hashable, Sendable {
        /// Replication role of a given shard (master or replica)
        public struct Role: Sendable, Hashable, RawRepresentable {
            public static let master = Role(base: .master)
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
                case master
                case replica
            }

            private var base: Base

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

        public var master: Node? {
            self.nodes.first
        }

        public var replicas: ArraySlice<Node> {
            self.nodes.dropFirst(1)
        }

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

            var slotRanges: HashSlots = []
            var nodes: [ValkeyClusterDescription.Node] = []

            switch shardToken.value {
            case .array(let keysAndValues):
                var keysAndValuesIterator = keysAndValues.makeIterator()
                while let keyToken = keysAndValuesIterator.next(), let key = try? String(fromRESP: keyToken) {
                    switch key {
                    case "slots":
                        slotRanges = try HashSlots(&keysAndValuesIterator)

                    case "nodes":
                        nodes = try [ValkeyClusterDescription.Node](&keysAndValuesIterator)

                    default:
                        continue
                    }
                }

            case .map(let keysAndValues):
                for (keyToken, value) in keysAndValues {
                    switch try? String(fromRESP: keyToken) {
                    case "slots":
                        slotRanges = try HashSlots(value)

                    case "nodes":
                        nodes = try [ValkeyClusterDescription.Node](value)

                    default:
                        continue
                    }
                }
            default:
                throw ValkeyClusterParseError.Reason.shardTokenIsNotAnArray
            }

            // nodes must not be empty
            if nodes.isEmpty {
                throw .shardIsMissingNode
            }

            return ValkeyClusterDescription.Shard(slots: slotRanges, nodes: nodes)
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
            throw .nodeTokenIsNotAnArray
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
                    let nodeVal = self.underlying.next() else {
                return nil
            }

            return (key, nodeVal)
        }
    }
}
