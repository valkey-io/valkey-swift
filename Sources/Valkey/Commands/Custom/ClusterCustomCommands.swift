//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore

extension CLUSTER.GETKEYSINSLOT {
    public typealias Response = [ValkeyKey]
}

extension CLUSTER.MYID {
    public typealias Response = String
}

extension CLUSTER.MYSHARDID {
    public typealias Response = String
}

extension CLUSTER.LINKS {
    public typealias Response = [ValkeyClusterLink]
}

extension CLUSTER.SHARDS {
    public typealias Response = ValkeyClusterDescription
}

extension CLUSTER.SLOTSTATS {
    public typealias Response = [ValkeyClusterSlotStats]
}

extension CLUSTER.SLOTS {
    public typealias Response = [ValkeyClusterSlotRange]
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

/// A description of a Valkey cluster.
///
/// A description is return when you call ``ValkeyClientProtocol/clusterShards()``.
public struct ValkeyClusterDescription: Hashable, Sendable, RESPTokenDecodable {
    /// Details for a node within a cluster shard.
    public struct Node: Hashable, Sendable {
        /// Replication role of a given node within a shard (primary or replica).
        public struct Role: Sendable, Hashable, RawRepresentable {
            /// The node is primary.
            public static let primary = Role(base: .primary)
            /// The node is a replica.
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
            /// The node is online.
            public static let online = Health(base: .online)
            /// The node is in a failed state.
            public static let failed = Health(base: .failed)
            /// The node is loading.
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

        /// The ID of the node
        public var id: String
        /// The port
        public var port: Int?
        /// The TLS port
        public var tlsPort: Int?
        /// The IP address
        public var ip: String
        /// The hostname
        public var hostname: String?
        /// The endpoint
        public var endpoint: String
        /// The role of the node
        public var role: Role
        /// The replication offset for the node
        public var replicationOffset: Int
        /// The health of the node
        public var health: Health

        /// Creates a new node
        /// - Parameters:
        ///   - id: The node ID
        ///   - port: The port
        ///   - tlsPort: The TLS port
        ///   - ip: The IP address
        ///   - hostname: The hostname
        ///   - endpoint: The endpoint
        ///   - role: The node role
        ///   - replicationOffset: The replication offset
        ///   - health: The node health
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

    /// A portion of a valkey cluster
    public struct Shard: Hashable, Sendable {
        /// The slots represented in the shard.
        public var slots: HashSlots
        /// The nodes that make up the shard.
        public var nodes: [Node]

        /// Create a new shard.
        /// - Parameters:
        ///   - slots: The slots in the shard.
        ///   - nodes: The nodes in the shard.
        public init(slots: HashSlots, nodes: [Node]) {
            self.slots = slots
            self.nodes = nodes
        }
    }

    /// The individual portions of a valkey cluster, known as shards.
    public var shards: [Shard]

    /// Creates a cluster description from the response token you provide.
    /// - Parameter respToken: The response token.
    public init(fromRESP respToken: RESPToken) throws {
        do {
            self = try Self.makeClusterDescription(respToken: respToken)
        } catch {
            throw ValkeyClusterParseError(reason: error, token: respToken)
        }
    }

    /// Creates a cluster description from a list of shards you provide.
    /// - Parameter shards: The shards that make up the cluster.
    public init(_ shards: [ValkeyClusterDescription.Shard]) {
        self.shards = shards
    }
}

/// A cluster link between nodes in a Valkey cluster.
///
/// A description is returned when you call ``ValkeyClientProtocol/clusterLinks()``.
public struct ValkeyClusterLink: Hashable, Sendable, RESPTokenDecodable {
    /// Direction of the cluster link.
    public struct Direction: Sendable, Hashable, RawRepresentable {
        /// The link is established by the local node to the peer.
        public static let to = Direction(base: .to)
        /// The link is accepted by the local node from the peer.
        public static let from = Direction(base: .from)

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
            case to
            case from
        }

        private(set) var base: Base

        init(base: Base) {
            self.base = base
        }
    }

    /// The direction of the link (to or from)
    public var direction: Direction?
    /// The node ID of the peer
    public var node: String?
    /// Creation time of the link
    public var createTime: Int?
    /// Events currently registered for the link (e.g., "r", "w", "rw")
    public var events: String?
    /// Allocated size of the link's send buffer
    public var sendBufferAllocated: Int?
    /// Size of the portion of the link's send buffer currently holding data
    public var sendBufferUsed: Int?

    /// Creates a new cluster link
    /// - Parameters:
    ///   - direction: The direction of the link
    ///   - node: The node ID of the peer
    ///   - createTime: Creation time of the link
    ///   - events: Events registered for the link
    ///   - sendBufferAllocated: Allocated send buffer size
    ///   - sendBufferUsed: Used send buffer size
    public init(
        direction: Direction? = nil,
        node: String? = nil,
        createTime: Int? = nil,
        events: String? = nil,
        sendBufferAllocated: Int? = nil,
        sendBufferUsed: Int? = nil
    ) {
        self.direction = direction
        self.node = node
        self.createTime = createTime
        self.events = events
        self.sendBufferAllocated = sendBufferAllocated
        self.sendBufferUsed = sendBufferUsed
    }

    /// Creates a cluster link from the response token you provide.
    /// - Parameter respToken: The response token.
    public init(fromRESP respToken: RESPToken) throws {
        self = try Self.makeClusterLink(respToken: respToken)
    }

    fileprivate static func makeClusterLink(respToken: RESPToken) throws(RESPDecodeError) -> ValkeyClusterLink {
        switch respToken.value {
        case .array(let array):
            return try Self.makeFromTokenSequence(MapStyleArray(underlying: array), respToken)

        case .map(let map):
            let mapped = map.lazy.compactMap { (keyNode, value) -> (String, RESPToken)? in
                if let key = try? String(fromRESP: keyNode) {
                    return (key, value)
                } else {
                    return nil
                }
            }
            return try Self.makeFromTokenSequence(mapped, respToken)

        default:
            throw RESPDecodeError.tokenMismatch(expected: [.array, .map], token: respToken)
        }
    }

    fileprivate static func makeFromTokenSequence<TokenSequence: Sequence>(
        _ sequence: TokenSequence,
        _ respToken: RESPToken
    ) throws(RESPDecodeError) -> Self where TokenSequence.Element == (String, RESPToken) {
        var direction: ValkeyClusterLink.Direction?
        var node: String?
        var createTime: Int64?
        var events: String?
        var sendBufferAllocated: Int64?
        var sendBufferUsed: Int64?

        for (key, value) in sequence {
            switch key {
            case "direction":
                guard let directionString = try? String(fromRESP: value),
                    let directionValue = ValkeyClusterLink.Direction(rawValue: directionString)
                else {
                    throw RESPDecodeError.missingToken(key: "direction", token: respToken)
                }
                direction = directionValue

            case "node":
                node = try? String(fromRESP: value)

            case "create-time":
                createTime = try? Int64(fromRESP: value)

            case "events":
                events = try? String(fromRESP: value)

            case "send-buffer-allocated":
                sendBufferAllocated = try? Int64(fromRESP: value)

            case "send-buffer-used":
                sendBufferUsed = try? Int64(fromRESP: value)

            default:
                // ignore unexpected keys for forward compatibility
                continue
            }
        }

        return ValkeyClusterLink(
            direction: direction,
            node: node,
            createTime: createTime.map { Int($0) },
            events: events,
            sendBufferAllocated: sendBufferAllocated.map { Int($0) },
            sendBufferUsed: sendBufferUsed.map { Int($0) }
        )
    }
}

/// Slot usage statistics for a hash slot in a Valkey cluster.
///
/// A description is returned when you call ``ValkeyClientProtocol/clusterSlotStats(filter:)``.
public struct ValkeyClusterSlotStats: Hashable, Sendable, RESPTokenDecodable {
    /// The hash slot number
    public var slot: Int
    /// Number of keys in the slot
    public var keyCount: Int?
    /// CPU time consumed by the slot in microseconds
    public var cpuUsec: Int?
    /// Network bytes read for the slot
    public var networkBytesIn: Int?
    /// Network bytes written for the slot
    public var networkBytesOut: Int?

    /// Creates a new cluster slot stats
    /// - Parameters:
    ///   - slot: The hash slot number
    ///   - keyCount: Number of keys in the slot
    ///   - cpuUsec: CPU time consumed in microseconds
    ///   - networkBytesIn: Network bytes read
    ///   - networkBytesOut: Network bytes written
    public init(
        slot: Int,
        keyCount: Int? = nil,
        cpuUsec: Int? = nil,
        networkBytesIn: Int? = nil,
        networkBytesOut: Int? = nil
    ) {
        self.slot = slot
        self.keyCount = keyCount
        self.cpuUsec = cpuUsec
        self.networkBytesIn = networkBytesIn
        self.networkBytesOut = networkBytesOut
    }

    /// Creates a cluster slot stats from the response token you provide.
    /// - Parameter respToken: The response token.
    public init(fromRESP respToken: RESPToken) throws {
        self = try Self.makeClusterSlotStats(respToken: respToken)
    }

    fileprivate static func makeClusterSlotStats(respToken: RESPToken) throws(RESPDecodeError) -> ValkeyClusterSlotStats {
        guard case .array(let array) = respToken.value else {
            throw RESPDecodeError.tokenMismatch(expected: [.array], token: respToken)
        }

        guard array.count >= 2 else {
            throw RESPDecodeError.invalidArraySize(array, minExpectedSize: 2)
        }

        var iterator = array.makeIterator()

        // First element: slot number
        guard let slotToken = iterator.next(),
            case .number(let slotNumber) = slotToken.value
        else {
            throw RESPDecodeError.missingToken(key: "slot", token: respToken)
        }

        // Second element: statistics map
        guard let statsToken = iterator.next() else {
            throw RESPDecodeError.missingToken(key: "statistics", token: respToken)
        }

        return try Self.makeFromStatsToken(slot: Int(slotNumber), statsToken: statsToken)
    }

    fileprivate static func makeFromStatsToken(slot: Int, statsToken: RESPToken) throws(RESPDecodeError) -> Self {
        var keyCount: Int64?
        var cpuUsec: Int64?
        var networkBytesIn: Int64?
        var networkBytesOut: Int64?

        switch statsToken.value {
        case .map(let map):
            // For RESP3, handle RESPToken stats as map
            let mapped = map.lazy.compactMap { (keyNode, value) -> (String, RESPToken)? in
                if let key = try? String(fromRESP: keyNode) {
                    return (key, value)
                } else {
                    return nil
                }
            }
            for (key, value) in mapped {
                switch key {
                case "key-count":
                    keyCount = try? Int64(fromRESP: value)

                case "cpu-usec":
                    cpuUsec = try? Int64(fromRESP: value)

                case "network-bytes-in":
                    networkBytesIn = try? Int64(fromRESP: value)

                case "network-bytes-out":
                    networkBytesOut = try? Int64(fromRESP: value)

                default:
                    // ignore unexpected keys for forward compatibility
                    continue
                }
            }

        case .array(let array):
            // // For RESP2, handle RESPToken stats as key-value pairs in array format
            let mapArray = MapStyleArray(underlying: array)
            for (key, valueToken) in mapArray {
                switch key {
                case "key-count":
                    keyCount = try? Int64(fromRESP: valueToken)

                case "cpu-usec":
                    cpuUsec = try? Int64(fromRESP: valueToken)

                case "network-bytes-in":
                    networkBytesIn = try? Int64(fromRESP: valueToken)

                case "network-bytes-out":
                    networkBytesOut = try? Int64(fromRESP: valueToken)

                default:
                    // ignore unexpected keys for forward compatibility
                    continue
                }
            }

        default:
            throw RESPDecodeError.tokenMismatch(expected: [.array, .map], token: statsToken)
        }

        return ValkeyClusterSlotStats(
            slot: slot,
            keyCount: keyCount.map { Int($0) },
            cpuUsec: cpuUsec.map { Int($0) },
            networkBytesIn: networkBytesIn.map { Int($0) },
            networkBytesOut: networkBytesOut.map { Int($0) }
        )
    }
}

/// A slot range mapping in a Valkey cluster.
///
/// A description is returned when you call ``ValkeyClientProtocol/clusterSlots()``.
public struct ValkeyClusterSlotRange: Hashable, Sendable, RESPTokenDecodable {
    /// A node serving a slot range in a Valkey cluster.
    public struct Node: Hashable, Sendable {
        /// The IP address of the node
        public var ip: String
        /// The port of the node
        public var port: Int
        /// The node ID
        public var nodeId: String
        /// Additional networking metadata
        public var metadata: [String: String]

        /// Creates a new cluster slot node
        /// - Parameters:
        ///   - ip: The IP address
        ///   - port: The port
        ///   - nodeId: The node ID
        ///   - metadata: Additional networking metadata
        public init(
            ip: String,
            port: Int,
            nodeId: String,
            metadata: [String: String] = [:]
        ) {
            self.ip = ip
            self.port = port
            self.nodeId = nodeId
            self.metadata = metadata
        }
    }

    /// The start slot of the range
    public var startSlot: Int
    /// The end slot of the range
    public var endSlot: Int
    /// The nodes serving this slot range
    public var nodes: [Node]

    /// Creates a new cluster slot range
    /// - Parameters:
    ///   - startSlot: The start slot
    ///   - endSlot: The end slot
    ///   - nodes: The nodes serving this range
    public init(startSlot: Int, endSlot: Int, nodes: [Node]) {
        self.startSlot = startSlot
        self.endSlot = endSlot
        self.nodes = nodes
    }

    /// Creates a cluster slot range from the response token you provide.
    /// - Parameter respToken: The response token.
    public init(fromRESP respToken: RESPToken) throws {
        self = try Self.makeClusterSlotRange(respToken: respToken)
    }

    fileprivate static func makeClusterSlotRange(respToken: RESPToken) throws(RESPDecodeError) -> ValkeyClusterSlotRange {
        guard case .array(let array) = respToken.value else {
            throw RESPDecodeError.tokenMismatch(expected: [.array], token: respToken)
        }

        guard array.count >= 3 else {
            throw RESPDecodeError.invalidArraySize(array, minExpectedSize: 3)
        }

        var iterator = array.makeIterator()

        // First element: start slot
        guard let startSlotToken = iterator.next(),
            case .number(let startSlotNumber) = startSlotToken.value
        else {
            throw RESPDecodeError.missingToken(key: "start slot", token: respToken)
        }

        // Second element: end slot
        guard let endSlotToken = iterator.next(),
            case .number(let endSlotNumber) = endSlotToken.value
        else {
            throw RESPDecodeError.missingToken(key: "end slot", token: respToken)
        }

        let startSlot = Int(startSlotNumber)
        let endSlot = Int(endSlotNumber)

        // Remaining elements are nodes
        var nodes: [Node] = []
        while let nodeToken = iterator.next() {
            let node = try Node.makeSlotNode(respToken: nodeToken)
            nodes.append(node)
        }

        return ValkeyClusterSlotRange(
            startSlot: startSlot,
            endSlot: endSlot,
            nodes: nodes
        )
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

extension ValkeyClusterSlotRange.Node {
    fileprivate static func makeSlotNode(respToken: RESPToken) throws(RESPDecodeError) -> ValkeyClusterSlotRange.Node {
        guard case .array(let array) = respToken.value else {
            throw RESPDecodeError.tokenMismatch(expected: [.array], token: respToken)
        }

        // IP, Port and Node Id are expected, additional metadata is optional
        guard array.count >= 3 else {
            throw RESPDecodeError.invalidArraySize(array, minExpectedSize: 3)
        }

        var iterator = array.makeIterator()

        // First element: IP address
        guard let ipToken = iterator.next(),
            let ip = try? String(fromRESP: ipToken)
        else {
            throw RESPDecodeError.missingToken(key: "ip", token: respToken)
        }

        // Second element: port
        guard let portToken = iterator.next(),
            case .number(let portNumber) = portToken.value
        else {
            throw RESPDecodeError.missingToken(key: "port", token: respToken)
        }
        let port = Int(portNumber)

        // Third element: node ID
        guard let nodeIdToken = iterator.next(),
            let nodeId = try? String(fromRESP: nodeIdToken)
        else {
            throw RESPDecodeError.missingToken(key: "node id", token: respToken)
        }

        var metadata: [String: String] = [:]

        // Any additional elements are treated as metadata
        while let metadataToken = iterator.next() {
            switch metadataToken.value {
            case .map(let map):
                // Handle metadata as a map
                for (keyToken, valueToken) in map {
                    if let key = try? String(fromRESP: keyToken),
                        let value = try? String(fromRESP: valueToken)
                    {
                        metadata[key] = value
                    }
                }
            case .array(let array):
                // Skip empty arrays (indicates no additional metadata)
                guard array.count > 0 else { continue }

                // Handle metadata as key-value pairs in array format (using MapStyleArray)
                let mapArray = MapStyleArray(underlying: array)
                for (key, valueToken) in mapArray {
                    if let value = try? String(fromRESP: valueToken) {
                        metadata[key] = value
                    }
                }
            default:
                throw RESPDecodeError.tokenMismatch(expected: [.array, .map], token: respToken)
            }
        }

        return ValkeyClusterSlotRange.Node(
            ip: ip,
            port: port,
            nodeId: nodeId,
            metadata: metadata
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
