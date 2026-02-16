//
// This source file is part of the valkey-swift project
// Copyright (c) 2025-2026 the valkey-swift project authors
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

/// Response type for cluster node listing commands.
///
/// Contains an array of cluster nodes from CLUSTER NODES, CLUSTER REPLICAS responses.
public struct ValkeyClusterNodes: Hashable, Sendable, RESPTokenDecodable {
    /// The array of cluster nodes
    public var nodes: [ValkeyClusterNode]

    /// Creates a cluster nodes response from the response token you provide.
    /// - Parameter token: The response token containing cluster nodes data.
    public init(_ token: RESPToken) throws(RESPDecodeError) {
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
            // For CLUSTER REPLICAS response (array of bulk strings)
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
/// Represents a node from CLUSTER NODES or CLUSTER REPLICAS responses.
/// Each node contains information about its ID, endpoint, role, status, and assigned slots.
public struct ValkeyClusterNode: Hashable, Sendable, RESPTokenDecodable {
    /// Individual node flag indicating the node's role or status
    public struct Flag: Hashable, RawRepresentable, RESPTokenDecodable, CustomStringConvertible, Sendable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(_ token: RESPToken) throws(RESPDecodeError) {
            let string = try String(token)
            self = .init(rawValue: string)
        }

        public var description: String { self.rawValue }
        /// The node is a primary
        public static var primary: Flag { .init(rawValue: "master") }
        /// The node is a replica
        public static var replica: Flag { .init(rawValue: "slave") }
        /// The node is myself
        public static var myself: Flag { .init(rawValue: "myself") }
        /// The node is in PFAIL state
        public static var pfail: Flag { .init(rawValue: "fail?") }
        /// The node is in FAIL state
        public static var fail: Flag { .init(rawValue: "fail") }
        /// The node is in handshake state
        public static var handshake: Flag { .init(rawValue: "handshake") }
        /// The node has no address
        public static var noaddr: Flag { .init(rawValue: "noaddr") }
        /// The node doesn't participate in failovers
        public static var nofailover: Flag { .init(rawValue: "nofailover") }
        /// No flags are set
        public static var noflags: Flag { .init(rawValue: "noflags") }
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
    init(
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
    public init(_ respToken: RESPToken) throws(RESPDecodeError) {
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
            flags.insert(Flag(rawValue: flagString))
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
    /// Temporary for decoding hash slots
    struct TokenDecodableHashSlots: RESPTokenDecodable {
        let slots: HashSlots

        public init(_ token: RESPToken) throws(RESPDecodeError) {
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
            self.slots = slotRanges
        }
    }
    /// Details for a node within a cluster shard.
    public struct Node: Hashable, Sendable, RESPTokenDecodable {
        /// Replication role of a given node within a shard (primary or replica).
        public struct Role: Sendable, Hashable, RESPTokenDecodable {
            /// The node is primary.
            public static let primary = Role(base: .primary)
            /// The node is a replica.
            public static let replica = Role(base: .replica)

            public init(_ token: RESPToken) throws(RESPDecodeError) {
                let string = try token.decode(as: String.self)
                guard let baseValue = Base(rawValue: string) else {
                    throw RESPDecodeError(.unexpectedToken, token: token, message: "Invalid Role String: \(string)")
                }
                self = .init(base: baseValue)
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
        public struct Health: Sendable, Hashable, RESPTokenDecodable {
            /// The node is online.
            public static let online = Health(base: .online)
            /// The node is in a failed state.
            public static let fail = Health(base: .fail)
            /// The node is loading.
            public static let loading = Health(base: .loading)

            public init(_ token: RESPToken) throws(RESPDecodeError) {
                let string = try token.decode(as: String.self)
                guard let baseValue = Base(rawValue: string) else {
                    throw RESPDecodeError(.unexpectedToken, token: token, message: "Invalid Node Health String: \(string)")
                }
                self = .init(base: baseValue)
            }

            enum Base: String {
                case online
                case fail
                case loading
            }

            private var base: Base
            package var rawValue: String { base.rawValue }

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
        package init(
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

        public init(_ token: RESPToken) throws(RESPDecodeError) {
            (self.id, self.port, self.tlsPort, self.ip, self.hostname, self.endpoint, self.role, self.replicationOffset, self.health) =
                try token.decodeMapValues("id", "port", "tls-port", "ip", "hostname", "endpoint", "role", "replication-offset", "health")
        }
    }

    /// A portion of a valkey cluster
    public struct Shard: Hashable, Sendable, RESPTokenDecodable {
        /// The slots represented in the shard.
        public var slots: HashSlots
        /// The nodes that make up the shard.
        public var nodes: [Node]

        /// Create a new shard.
        /// - Parameters:
        ///   - slots: The slots in the shard.
        ///   - nodes: The nodes in the shard.
        package init(slots: HashSlots, nodes: [Node]) {
            self.slots = slots
            self.nodes = nodes
        }

        public init(_ token: RESPToken) throws(RESPDecodeError) {
            let hashSlots: TokenDecodableHashSlots
            (hashSlots, self.nodes) = try token.decodeMapValues("slots", "nodes")
            self.slots = hashSlots.slots
        }

        package func getPrimaryAndReplicas<Err: Error>(
            onDuplicatePrimary: (Node, Node) throws(Err) -> Node
        ) throws(Err) -> (
            primary: ValkeyClusterDescription.Node?, replicas: [ValkeyClusterDescription.Node]
        ) {
            var primary: Node? = nil
            var isFailedPrimary = false
            var replicas = [Node]()
            replicas.reserveCapacity(self.nodes.count)

            for node in self.nodes {
                switch node.role.base {
                case .primary:
                    switch (primary, isFailedPrimary) {
                    case (.some(let primaryNode), false):
                        if node.health != .fail {
                            // only update primary if it is online/loading
                            primary = try onDuplicatePrimary(primaryNode, node)
                        }
                    case (.some, true), (.none, _):
                        primary = node
                        isFailedPrimary = (node.health == .fail)
                    }
                case .replica:
                    replicas.append(node)
                }
            }
            return (primary: primary, replicas: replicas)
        }
    }

    /// The individual portions of a valkey cluster, known as shards.
    public var shards: [Shard]

    /// Creates a cluster description from the response token you provide.
    /// - Parameter respToken: The response token.
    public init(_ respToken: RESPToken) throws(RESPDecodeError) {
        self.shards = try [Shard](respToken, decodeSingleElementAsArray: false)
    }

    /// Creates a cluster description from a list of shards you provide.
    /// - Parameter shards: The shards that make up the cluster.
    package init(_ shards: [ValkeyClusterDescription.Shard]) {
        self.shards = shards
    }
}

/// A cluster link between nodes in a Valkey cluster.
///
/// A description is returned when you call ``ValkeyClientProtocol/clusterLinks()``.
public struct ValkeyClusterLink: Hashable, Sendable, RESPTokenDecodable {
    /// Direction of the cluster link.
    public struct Direction: Sendable, Hashable, RESPTokenDecodable {
        /// The link is established by the local node to the peer.
        public static var to: Direction { Direction(base: .to) }
        /// The link is accepted by the local node from the peer.
        public static var from: Direction { Direction(base: .from) }

        public init(_ token: RESPToken) throws(RESPDecodeError) {
            let string = try token.decode(as: String.self)
            guard let baseValue = Base(rawValue: string) else {
                throw RESPDecodeError(.unexpectedToken, token: token, message: "Cannot construct \(Self.self) from \(string)")
            }
            self = .init(base: baseValue)
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
    public var direction: Direction
    /// The node ID of the peer
    public var node: String
    /// Creation time of the link
    public var createTime: Int
    /// Events currently registered for the link (e.g., "r", "w", "rw")
    public var events: String
    /// Allocated size of the link's send buffer
    public var sendBufferAllocated: Int
    /// Size of the portion of the link's send buffer currently holding data
    public var sendBufferUsed: Int

    /// Creates a new cluster link
    /// - Parameters:
    ///   - direction: The direction of the link
    ///   - node: The node ID of the peer
    ///   - createTime: Creation time of the link
    ///   - events: Events registered for the link
    ///   - sendBufferAllocated: Allocated send buffer size
    ///   - sendBufferUsed: Used send buffer size
    init(
        direction: Direction,
        node: String,
        createTime: Int,
        events: String,
        sendBufferAllocated: Int,
        sendBufferUsed: Int
    ) {
        self.direction = direction
        self.node = node
        self.createTime = createTime
        self.events = events
        self.sendBufferAllocated = sendBufferAllocated
        self.sendBufferUsed = sendBufferUsed
    }

    /// Creates a cluster link from the response token you provide.
    /// - Parameter token: The response token.
    public init(_ token: RESPToken) throws(RESPDecodeError) {
        (self.direction, self.node, self.createTime, self.events, self.sendBufferAllocated, self.sendBufferUsed) = try token.decodeMapValues(
            "direction",
            "node",
            "create-time",
            "events",
            "send-buffer-allocated",
            "send-buffer-used"
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

    /// Creates a cluster slot stats from the response token you provide.
    /// - Parameter token: The response token.
    public init(_ token: RESPToken) throws(RESPDecodeError) {
        let slotAndStats: (Int, RESPToken) =
            switch token.value {
            case .array(let array):
                try array.decodeElements()
            default:
                throw RESPDecodeError.tokenMismatch(expected: [.array], token: token)
            }
        self.slot = slotAndStats.0
        (self.keyCount, self.cpuUsec, self.networkBytesIn, self.networkBytesOut) = try slotAndStats.1.decodeMapValues(
            "key-count",
            "cpu-usec",
            "network-bytes-in",
            "network-bytes-out"
        )
    }
}

/// A slot range mapping in a Valkey cluster.
///
/// A description is returned when you call ``ValkeyClientProtocol/clusterSlots()``.
public struct ValkeyClusterSlotRange: Hashable, Sendable, RESPTokenDecodable {
    /// A node serving a slot range in a Valkey cluster.
    public struct Node: Hashable, Sendable, RESPTokenDecodable {
        /// The IP address of the node
        public var ip: String
        /// The port of the node
        public var port: Int
        /// The node ID
        public var nodeId: String
        /// Additional networking metadata
        public var metadata: [String: String]

        public init(_ token: RESPToken) throws(RESPDecodeError) {
            (self.ip, self.port, self.nodeId, self.metadata) = try token.decodeArrayElements()
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
    init(startSlot: Int, endSlot: Int, nodes: [Node]) {
        self.startSlot = startSlot
        self.endSlot = endSlot
        self.nodes = nodes
    }

    /// Creates a cluster slot range from the response token you provide.
    /// - Parameter respToken: The response token.
    public init(_ respToken: RESPToken) throws(RESPDecodeError) {
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
            let node = try Node(nodeToken)
            nodes.append(node)
        }

        return ValkeyClusterSlotRange(
            startSlot: startSlot,
            endSlot: endSlot,
            nodes: nodes
        )
    }
}

extension ValkeyClusterDescription.Node {
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
