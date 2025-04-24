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

package struct ValkeyClusterParseError: Error {
    fileprivate enum Reason: Error{
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

package struct ValkeyClusterDescription: Hashable, Sendable {
    /// Details for a node within a cluster shard
    package struct Node: Hashable, Sendable {
        /// Replication role of a given shard (master or replica)
        package enum Role: String {
            case master
            case replica
        }

        /// Node's health status
        package enum Health: String {
            case online
            case failed
            case loading
        }

        package var id: String
        package var port: Int?
        package var tlsPort: Int?
        package var ip: String
        package var hostname: String?
        package var endpoint: String
        package var role: Role
        package var replicationOffset: Int
        package var health: Health

        package init(
            id: String,
            port: Int? = nil,
            tlsPort: Int? = nil,
            ip: String,
            hostname: String? = nil,
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

    package struct Shard: Hashable, Sendable {
        package var slotRanges: HashSlots
        package var nodes: [Node]

        package var master: Node? {
            self.nodes.first
        }

        package var replicas: ArraySlice<Node> {
            self.nodes.dropFirst(1)
        }

        package init(slotRanges: HashSlots, nodes: [Node]) {
            self.slotRanges = slotRanges
            self.nodes = nodes
        }
    }

    package var shards: [Shard]

    package init(respToken: RESPToken) throws(ValkeyClusterParseError) {
        do {
            self = try Self.makeClusterDescription(respToken: respToken)
        } catch {
            throw ValkeyClusterParseError(reason: error, token: respToken)
        }
    }

    package init(_ shards: [ValkeyClusterDescription.Shard]) {
        self.shards = shards
    }
}

extension ValkeyClusterDescription {
    fileprivate static func makeClusterDescription(respToken: RESPToken) throws(ValkeyClusterParseError.Reason) -> ValkeyClusterDescription {
        guard case .array(let shardsToken) = respToken.value else {
            throw .clusterDescriptionTokenIsNotAnArray
        }

        let shards = try shardsToken.map { shardToken throws(ValkeyClusterParseError.Reason) in

            guard case .array(let keysAndValues) = shardToken.value else {
                throw .shardTokenIsNotAnArray
            }

            var slotRanges: HashSlots = []
            var nodes: [ValkeyClusterDescription.Node] = []

            var keysAndValuesIterator = keysAndValues.makeIterator()
            while let keyToken = keysAndValuesIterator.next(), let key = String(keyToken) {
                switch key {
                case "slots":
                    slotRanges = try HashSlots(&keysAndValuesIterator)

                case "nodes":
                    nodes = try [ValkeyClusterDescription.Node](&keysAndValuesIterator)

                default:
                    continue
                }
            }

            // nodes must not be empty
            if nodes.isEmpty {
                throw .shardIsMissingNode
            }

            return ValkeyClusterDescription.Shard(slotRanges: slotRanges, nodes: nodes)
        }

        return ValkeyClusterDescription(shards)
    }
}

extension String {
    fileprivate init?(_ respToken: RESPToken) {
        switch respToken.value {
        case .bulkString(var byteBuffer),
             .simpleString(var byteBuffer),
             .blobError(var byteBuffer),
             .simpleError(var byteBuffer),
             .verbatimString(var byteBuffer):
            self = byteBuffer.readString(length: byteBuffer.readableBytes)!

        case .double(let value):
            self = "\(value)"

        case .number(let value):
            self = "\(value)"

        case .boolean(let value):
            self = "\(value)"

        case .array, .attribute, .bigNumber, .push, .set, .null, .map:
            return nil
        }
    }
}

extension Int64 {
    fileprivate init?(_ respToken: RESPToken) {
        switch respToken.value {
        case .number(let value):
            self = value

        case .bulkString,
             .simpleString,
             .blobError,
             .simpleError,
             .verbatimString,
             .double,
             .boolean,
             .array,
             .attribute,
             .bigNumber,
             .push,
             .set,
             .null,
             .map:
            return nil
        }
    }
}

extension HashSlots {
    fileprivate init(_ iterator: inout RESPToken.Array.Iterator) throws(ValkeyClusterParseError.Reason) {
        guard case .array(let array) = iterator.next()?.value else {
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
        guard case .array(let array) = iterator.next()?.value else {
            throw .nodesTokenIsNotAnArray
        }

        self = try array.map { token throws(ValkeyClusterParseError.Reason) in
            try ValkeyClusterDescription.Node(token)
        }
    }
}

extension ValkeyClusterDescription.Node {
    fileprivate init(_ token: RESPToken) throws(ValkeyClusterParseError.Reason) {
        guard case .array(let array) = token.value else {
            throw .nodeTokenIsNotAnArray
        }

        var id: String?
        var port: Int64?
        var tlsPort: Int64?
        var ip: String?
        var hostname: String?
        var endpoint: String?
        var role: ValkeyClusterDescription.Node.Role?
        var replicationOffset: Int64?
        var health: ValkeyClusterDescription.Node.Health?

        var nodeIterator = array.makeIterator()
        while let nodeKey = nodeIterator.next(), let key = String(nodeKey), let nodeVal = nodeIterator.next() {
            switch key {
            case "id":
                id = String(nodeVal)
            case "port":
                port = Int64(nodeVal)
            case "tls-port":
                tlsPort = Int64(nodeVal)
            case "ip":
                ip = String(nodeVal)
            case "hostname":
                hostname = String(nodeVal)
            case "endpoint":
                endpoint = String(nodeVal)
            case "role":
                guard let roleString = String(nodeVal), let roleValue = ValkeyClusterDescription.Node.Role(rawValue: roleString) else {
                    throw .invalidNodeRole
                }
                role = roleValue

            case "replication-offset":
                replicationOffset = Int64(nodeVal)
            case "health":
                guard let healthString = String(nodeVal), let healthValue = ValkeyClusterDescription.Node.Health(rawValue: healthString) else {
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

        self = ValkeyClusterDescription.Node(
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
