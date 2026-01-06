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

extension CLUSTER.NODES {
    public typealias Response = ValkeyClusterNodes
}

extension CLUSTER.REPLICAS {
    public typealias Response = ValkeyClusterNodes
}

extension CLUSTER.SLAVES {
    public typealias Response = ValkeyClusterNodes
}

/// Response type for cluster node listing commands.
///
/// Contains an array of cluster nodes from CLUSTER NODES, CLUSTER SLAVES, or CLUSTER REPLICAS responses.
public struct ValkeyClusterNodes: Hashable, Sendable, RESPTokenDecodable {
    /// The array of cluster nodes
    public var nodes: [ValkeyClusterNode]

    /// Creates a cluster nodes response from the response token you provide.
    /// - Parameter respToken: The response token containing cluster nodes data.
    public init(_ token: RESPToken) throws {
        self.nodes = try Self.makeClusterNodes(token: token)
    }

    fileprivate static func makeClusterNodes(token: RESPToken) throws(RESPDecodeError) -> [ValkeyClusterNode] {
        switch token.value {
        case .bulkString, .verbatimString:
            // For CLUSTER NODES response (single bulk string containing all nodes)
            let string = try String(token)
            let lines = string.split(separator: "\n").map(String.init).filter { !$0.isEmpty }
            return try lines.map { line throws(RESPDecodeError) in
                try ValkeyClusterNode.parseNodeLine(line)
            }

        case .array(let array):
            // For CLUSTER SLAVES/REPLICAS response (array of bulk strings)
            return try array.map { nodeToken throws(RESPDecodeError) in
                let nodeString = try String(nodeToken)
                return try ValkeyClusterNode.parseNodeLine(nodeString)
            }

        default:
            throw RESPDecodeError.tokenMismatch(expected: [.bulkString, .verbatimString, .array], token: token)
        }
    }
}

/// A single node entry from cluster node listing commands.
///
/// Represents a node from CLUSTER NODES, CLUSTER SLAVES, or CLUSTER REPLICAS responses.
/// Each node contains information about its ID, endpoint, role, status, and assigned slots.
public struct ValkeyClusterNode: Hashable, Sendable, RESPTokenDecodable {
    /// Individual node flag indicating the node's role or status
    public enum Flag: String, Sendable, Hashable, CaseIterable {
        /// The node is a primary (master)
        case master
        /// The node is a replica (slave)
        case slave
        /// The node is myself
        case myself
        /// The node is in PFAIL state
        case pfail = "fail?"
        /// The node is in FAIL state
        case fail
        /// The node is in handshake state
        case handshake
        /// The node has no address
        case noaddr
        /// The node doesn't participate in failovers
        case nofailover
        /// No flags are set
        case noflags
    }

    /// The unique node ID
    public var nodeId: String
    /// The IP address and port (format: ip:port@cport or ip:port@cport,hostname)
    public var endpoint: String
    /// Node flags indicating role and status
    public var flags: Set<Flag>
    /// ID of the primary node (if this is a replica), or "-" if this is a primary
    public var primaryId: String?
    /// Last ping sent timestamp
    public var pingSent: Int64
    /// Last pong received timestamp
    public var pongReceived: Int64
    /// Configuration epoch for this node
    public var configEpoch: Int64
    /// Link state to this node (connected or disconnected)
    public var linkState: String
    /// Hash slots served by this node (only for primaries)
    public var slots: [String]

    /// Creates a new cluster node
    /// - Parameters:
    ///   - nodeId: The unique node ID
    ///   - endpoint: The IP address and port
    ///   - flags: Node flags indicating role and status
    ///   - primaryId: ID of the primary node (if replica)
    ///   - pingSent: Last ping sent timestamp
    ///   - pongReceived: Last pong received timestamp
    ///   - configEpoch: Configuration epoch
    ///   - linkState: Link state to this node
    ///   - slots: Hash slots served by this node
    public init(
        nodeId: String,
        endpoint: String,
        flags: Set<Flag>,
        primaryId: String?,
        pingSent: Int64,
        pongReceived: Int64,
        configEpoch: Int64,
        linkState: String,
        slots: [String] = []
    ) {
        self.nodeId = nodeId
        self.endpoint = endpoint
        self.flags = flags
        self.primaryId = primaryId
        self.pingSent = pingSent
        self.pongReceived = pongReceived
        self.configEpoch = configEpoch
        self.linkState = linkState
        self.slots = slots
    }

    /// Creates a cluster node from the response token you provide.
    /// - Parameter respToken: The response token containing cluster node data.
    public init(_ respToken: RESPToken) throws {
        let nodeString = try String(respToken)
        self = try Self.parseNodeLine(nodeString)
    }

    fileprivate static func parseNodeLine(_ line: String) throws(RESPDecodeError) -> ValkeyClusterNode {
        let components = line.split(separator: " ").map(String.init)
        guard components.count >= 8 else {
            throw RESPDecodeError(.unexpectedToken, token: RESPToken(validated: .init(string: line)), message: "Invalid node line format")
        }

        let nodeId = components[0]
        let endpoint = components[1]
        let flagsString = components[2]
        let primaryId = components[3] == "-" ? nil : components[3]
        let pingSent = Int64(components[4]) ?? 0
        let pongReceived = Int64(components[5]) ?? 0
        let configEpoch = Int64(components[6]) ?? 0
        let linkState = components[7]
        let slots = Array(components.dropFirst(8))

        // Parse flags
        var flags: Set<Flag> = []
        let flagComponents = flagsString.split(separator: ",").map(String.init)
        for flagString in flagComponents {
            if let flag = Flag(rawValue: flagString) {
                flags.insert(flag)
            }
        }

        return ValkeyClusterNode(
            nodeId: nodeId,
            endpoint: endpoint,
            flags: flags,
            primaryId: primaryId,
            pingSent: pingSent,
            pongReceived: pongReceived,
            configEpoch: configEpoch,
            linkState: linkState,
            slots: slots
        )
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
    public init(_ respToken: RESPToken) throws {
        self = try Self.makeClusterDescription(respToken: respToken)
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
    public init(_ respToken: RESPToken) throws {
        self = try Self.makeClusterLink(respToken: respToken)
    }

    fileprivate static func makeClusterLink(respToken: RESPToken) throws(RESPDecodeError) -> ValkeyClusterLink {
        switch respToken.value {
        case .array(let array):
            return try Self.makeFromTokenSequence(MapStyleArray(underlying: array), respToken)

        case .map(let map):
            let mapped = map.lazy.compactMap { (keyNode, value) -> (String, RESPToken)? in
                if let key = try? String(keyNode) {
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
                guard let directionString = try? String(value),
                    let directionValue = ValkeyClusterLink.Direction(rawValue: directionString)
                else {
                    throw RESPDecodeError.missingToken(key: "direction", token: respToken)
                }
                direction = directionValue

            case "node":
                node = try? String(value)

            case "create-time":
                createTime = try? Int64(value)

            case "events":
                events = try? String(value)

            case "send-buffer-allocated":
                sendBufferAllocated = try? Int64(value)

            case "send-buffer-used":
                sendBufferUsed = try? Int64(value)

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
    public init(_ respToken: RESPToken) throws {
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
                if let key = try? String(keyNode) {
                    return (key, value)
                } else {
                    return nil
                }
            }
            for (key, value) in mapped {
                switch key {
                case "key-count":
                    keyCount = try? Int64(value)

                case "cpu-usec":
                    cpuUsec = try? Int64(value)

                case "network-bytes-in":
                    networkBytesIn = try? Int64(value)

                case "network-bytes-out":
                    networkBytesOut = try? Int64(value)

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
                    keyCount = try? Int64(valueToken)

                case "cpu-usec":
                    cpuUsec = try? Int64(valueToken)

                case "network-bytes-in":
                    networkBytesIn = try? Int64(valueToken)

                case "network-bytes-out":
                    networkBytesOut = try? Int64(valueToken)

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
    public init(_ respToken: RESPToken) throws {
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
    fileprivate static func makeClusterDescription(respToken: RESPToken) throws(RESPDecodeError) -> ValkeyClusterDescription {
        guard case .array(let shardsToken) = respToken.value else {
            throw RESPDecodeError.tokenMismatch(expected: [.array], token: respToken)
        }
        let shards = try shardsToken.map { shardToken throws(RESPDecodeError) in
            try ValkeyClusterDescription.Shard(shardToken)
        }
        return ValkeyClusterDescription(shards)
    }
}

extension HashSlots {
    fileprivate init(_ token: RESPToken) throws(RESPDecodeError) {
        guard case .array(let array) = token.value else {
            throw RESPDecodeError.tokenMismatch(expected: [.array], token: token)
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

        if slotRanges.isEmpty { throw RESPDecodeError.invalidArraySize(array, minExpectedSize: 1) }
        self = slotRanges
    }
}

extension [ValkeyClusterDescription.Node] {
    fileprivate init(_ token: RESPToken) throws(RESPDecodeError) {
        guard case .array(let array) = token.value else {
            throw RESPDecodeError.tokenMismatch(expected: [.array], token: token)
        }

        self = try array.map { token throws(RESPDecodeError) in
            try ValkeyClusterDescription.Node(token)
        }
    }
}

extension ValkeyClusterDescription.Shard {
    fileprivate init(_ token: RESPToken) throws(RESPDecodeError) {
        switch token.value {
        case .array(let array):
            self = try Self.makeFromTokenSequence(MapStyleArray(underlying: array))

        case .map(let map):
            let mapped = map.lazy.compactMap { (keyNode, value) -> (String, RESPToken)? in
                if let key = try? String(keyNode) {
                    return (key, value)
                } else {
                    return nil
                }
            }
            self = try Self.makeFromTokenSequence(mapped)

        default:
            throw RESPDecodeError.tokenMismatch(expected: [.array, .map], token: token)
        }
    }

    fileprivate static func makeFromTokenSequence<TokenSequence: Sequence>(
        _ sequence: TokenSequence
    ) throws(RESPDecodeError) -> Self where TokenSequence.Element == (String, RESPToken) {
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

        return .init(slots: slotRanges, nodes: nodes)
    }
}

extension ValkeyClusterDescription.Node {
    fileprivate init(_ token: RESPToken) throws(RESPDecodeError) {
        switch token.value {
        case .array(let array):
            do {
                self = try Self.makeFromTokenSequence(MapStyleArray(underlying: array))
            } catch {
                switch error {
                case .decodeError(let error):
                    throw error
                case .missingRequiredValue:
                    throw RESPDecodeError(.missingToken, token: token, message: "Missing required token for Node")
                }
            }

        case .map(let map):
            let mapped = map.lazy.compactMap { (keyNode, value) -> (String, RESPToken)? in
                if let key = try? String(keyNode) {
                    return (key, value)
                } else {
                    return nil
                }
            }
            do {
                self = try Self.makeFromTokenSequence(mapped)
            } catch {
                switch error {
                case .decodeError(let error):
                    throw error
                case .missingRequiredValue:
                    throw RESPDecodeError(.missingToken, token: token, message: "Missing required token for Node")
                }
            }

        default:
            throw RESPDecodeError.tokenMismatch(expected: [.array, .map], token: token)
        }
    }

    fileprivate enum TokenSequenceError: Error {
        case decodeError(RESPDecodeError)
        case missingRequiredValue
    }

    fileprivate static func makeFromTokenSequence<TokenSequence: Sequence>(
        _ sequence: TokenSequence
    ) throws(TokenSequenceError) -> Self where TokenSequence.Element == (String, RESPToken) {
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
                id = try? String(nodeVal)
            case "port":
                port = try? Int64(nodeVal)
            case "tls-port":
                tlsPort = try? Int64(nodeVal)
            case "ip":
                ip = try? String(nodeVal)
            case "hostname":
                hostname = try? String(nodeVal)
            case "endpoint":
                endpoint = try? String(nodeVal)
            case "role":
                guard let roleString = try? String(nodeVal), let roleValue = ValkeyClusterDescription.Node.Role(rawValue: roleString) else {
                    throw .decodeError(RESPDecodeError(.unexpectedToken, token: nodeVal, message: "Invalid Role String"))
                }
                role = roleValue

            case "replication-offset":
                replicationOffset = try? Int64(nodeVal)
            case "health":
                guard let healthString = try? String(nodeVal),
                    let healthValue = ValkeyClusterDescription.Node.Health(rawValue: healthString)
                else {
                    throw .decodeError(RESPDecodeError(.unexpectedToken, token: nodeVal, message: "Invalid Node Health String"))
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
            throw .missingRequiredValue
        }

        // we need at least port or tlsport
        if port == nil && tlsPort == nil {
            throw .missingRequiredValue
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
            let ip = try? String(ipToken)
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
            let nodeId = try? String(nodeIdToken)
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
                    if let key = try? String(keyToken),
                        let value = try? String(valueToken)
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
                    if let value = try? String(valueToken) {
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
                let key = try? String(nodeKey),
                let nodeVal = self.underlying.next()
            else {
                return nil
            }

            return (key, nodeVal)
        }
    }
}
