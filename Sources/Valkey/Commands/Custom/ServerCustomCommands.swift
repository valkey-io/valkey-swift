//
// This source file is part of the valkey-swift project
// Copyright (c) 2025-2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

extension ACL {
    public typealias GETUSERResponse = OptionalGETUSERResponse?
    public struct OptionalGETUSERResponse: RESPTokenDecodable, Sendable {
        public struct Flag: Hashable, RawRepresentable, RESPTokenDecodable, CustomStringConvertible, Sendable {
            public let rawValue: String

            public init(rawValue: String) {
                self.rawValue = rawValue
            }

            public init(_ token: RESPToken) throws {
                let string = try String(token)
                self = .init(rawValue: string)
            }

            public var description: String { "\"\(self.rawValue)\"" }

            /// User is enabled. It is possible to authenticate with this user
            public static var on: Flag { .init(rawValue: "on") }
            /// User has been disabled. It is no longer possible to authenticate with this user
            public static var off: Flag { .init(rawValue: "off") }
            /// User does not need a password to authenticate
            public static var noPassword: Flag { .init(rawValue: "nopass") }
            public static var sanitizePayload: Flag { .init(rawValue: "sanitize-payload") }
            public static var skipSanitizePayload: Flag { .init(rawValue: "skip-sanitize-payload") }

        }
        public struct Selector: RESPTokenDecodable, Sendable {
            public let commands: String
            public let keys: String
            public let channels: String?

            public init(_ token: RESPToken) throws {
                (self.commands, self.keys, self.channels) = try token.decodeMapValues("commands", "keys", "channels")
            }
        }

        public let flags: Set<Flag>
        public let passwords: [String]
        public let commands: String
        public let keys: String
        public let channels: String?
        public let selectors: [Selector]?

        public init(_ token: RESPToken) throws {
            (self.flags, self.passwords, self.commands, self.keys, self.channels, self.selectors) = try token.decodeMapValues(
                "flags",
                "passwords",
                "commands",
                "keys",
                "channels",
                "selectors"
            )
        }
    }
}

extension ACL.GETUSER {
    public typealias Response = ACL.GETUSERResponse
}

extension COMMAND {
    public typealias GETKEYSANDFLAGSResponse = [GETKEYSANDFLAGSKey]

    public struct GETKEYSANDFLAGSKey: RESPTokenDecodable, Sendable {
        public struct Flags: RawRepresentable, RESPTokenDecodable, Sendable, Equatable, CustomStringConvertible {
            public let rawValue: String

            public init(rawValue: String) {
                self.rawValue = rawValue
            }

            public init(_ token: RESPToken) throws {
                let string = try String(token)
                self = .init(rawValue: string)
            }

            public var description: String { self.rawValue }

            public static var rw: Self { .init(rawValue: "RW") }
            public static var ro: Self { .init(rawValue: "RO") }
            public static var ow: Self { .init(rawValue: "OW") }
            public static var rm: Self { .init(rawValue: "RM") }
            public static var access: Self { .init(rawValue: "access") }
            public static var update: Self { .init(rawValue: "update") }
            public static var insert: Self { .init(rawValue: "insert") }
            public static var delete: Self { .init(rawValue: "delete") }
            public static var notKey: Self { .init(rawValue: "not_key") }
            public static var incomplete: Self { .init(rawValue: "incomplete") }
            public static var variableFlags: Self { .init(rawValue: "variable_flags") }
        }
        public let key: ValkeyKey
        public let flags: [Flags]

        public init(_ token: RESPToken) throws {
            (self.key, self.flags) = try token.decodeArrayElements()
        }
    }

}

extension COMMAND.GETKEYSANDFLAGS {
    public typealias Response = COMMAND.GETKEYSANDFLAGSResponse
}

extension ROLE {
    public enum Response: RESPTokenDecodable, Sendable {
        struct MissingValueDecodeError: Error {
            let expectedNumberOfValues: Int
        }
        public struct Primary: Sendable {
            public struct Replica: RESPTokenDecodable, Sendable {
                public let ip: String
                public let port: Int
                public let replicationOffset: Int

                public init(_ token: RESPToken) throws {
                    (self.ip, self.port, self.replicationOffset) = try token.decodeArrayElements()
                }
            }
            public let replicationOffset: Int
            public let replicas: [Replica]

            init(arrayIterator: inout RESPToken.Array.Iterator) throws {
                guard let replicationOffsetToken = arrayIterator.next(), let replicasToken = arrayIterator.next() else {
                    throw MissingValueDecodeError(expectedNumberOfValues: 2)
                }
                self.replicationOffset = try .init(replicationOffsetToken)
                self.replicas = try .init(replicasToken)
            }
        }
        public struct Replica: Sendable {

            public struct State: Hashable, RawRepresentable, RESPTokenDecodable, CustomStringConvertible, Sendable {
                public let rawValue: String

                public init(rawValue: String) {
                    self.rawValue = rawValue
                }

                public init(_ token: RESPToken) throws {
                    let string = try String(token)
                    self = .init(rawValue: string)
                }

                public var description: String { "\"\(self.rawValue)\"" }

                /// The replica needs to connect to its primary.
                public static var connect: State { .init(rawValue: "connect") }
                /// The primary-replica connection is in progress
                public static var connecting: State { .init(rawValue: "connecting") }
                /// The primary and replica are trying to perform the synchronization
                public static var sync: State { .init(rawValue: "sync") }
                /// The replica is online
                public static var connected: State { .init(rawValue: "connected") }

            }
            public let primaryIP: String
            public let primaryPort: Int
            public let state: State
            public let replicationOffset: Int

            init(arrayIterator: inout RESPToken.Array.Iterator) throws {
                guard let primaryIPToken = arrayIterator.next(),
                    let primaryPortToken = arrayIterator.next(),
                    let stateToken = arrayIterator.next(),
                    let replicationToken = arrayIterator.next()
                else {
                    throw MissingValueDecodeError(expectedNumberOfValues: 4)
                }
                self.primaryIP = try .init(primaryIPToken)
                self.primaryPort = try .init(primaryPortToken)
                self.state = try .init(stateToken)
                self.replicationOffset = try .init(replicationToken)
            }
        }
        public struct Sentinel: Sendable {
            public let primaryNames: [String]

            init(arrayIterator: inout RESPToken.Array.Iterator) throws {
                guard let primaryNamesToken = arrayIterator.next() else { throw MissingValueDecodeError(expectedNumberOfValues: 1) }
                self.primaryNames = try .init(primaryNamesToken)
            }
        }
        case primary(Primary)
        case replica(Replica)
        case sentinel(Sentinel)

        public init(_ token: RESPToken) throws {
            switch token.value {
            case .array(let array):
                do {
                    var iterator = array.makeIterator()
                    guard let roleToken = iterator.next() else {
                        throw RESPDecodeError.invalidArraySize(array, expectedSize: 1)
                    }
                    let role = try String(roleToken)
                    switch role {
                    case "master":
                        let primary = try Primary(arrayIterator: &iterator)
                        self = .primary(primary)
                    case "slave":
                        let replica = try Replica(arrayIterator: &iterator)
                        self = .replica(replica)
                    case "sentinel":
                        let sentinel = try Sentinel(arrayIterator: &iterator)
                        self = .sentinel(sentinel)
                    default:
                        throw RESPDecodeError(.unexpectedToken, token: token)
                    }
                } catch let error as MissingValueDecodeError {
                    throw RESPDecodeError.invalidArraySize(array, expectedSize: error.expectedNumberOfValues + 1)
                }
            default:
                throw RESPDecodeError.tokenMismatch(expected: [.array], token: token)
            }
        }
    }
}

extension MEMORY.STATS {
    public struct Key: RawRepresentable, RESPTokenDecodable, Hashable, Sendable, CustomStringConvertible {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(_ token: RESPToken) throws {
            let string = try String(token)
            self = .init(rawValue: string)
        }

        public var description: String { self.rawValue }

        /// Peak memory consumed by Valkey in bytes (see INFO's used_memory_peak)
        public static var peakAllocated: Key { .init(rawValue: "peak.allocated") }
        /// Total number of bytes allocated by Valkey using its allocator (see INFO's used_memory)
        public static var totalAllocated: Key { .init(rawValue: "total.allocated") }
        /// Initial amount of memory consumed by Valkey at startup in bytes (see INFO's used_memory_startup)
        public static var startupAllocated: Key { .init(rawValue: "startup.allocated") }
        /// Memory usage by replication backlog (see INFO's mem_replication_backlog)
        public static var replicationBackLog: Key { .init(rawValue: "replication.backlog") }
        /// The total size in bytes of all replicas overheads (output and query buffers, connection contexts)
        public static var clientsSlaves: Key { .init(rawValue: "clients.slaves") }
        /// The total size in bytes of all clients overheads (output and query buffers, connection contexts)
        public static var clientsNormal: Key { .init(rawValue: "clients.normal") }
        /// Memory usage by cluster links (see INFO's mem_cluster_links).
        public static var clusterLinks: Key { .init(rawValue: "cluster.links") }
        /// The summed size in bytes of AOF related buffers.
        public static var aofBuffer: Key { .init(rawValue: "aof.buffer") }
        /// the summed size in bytes of the overheads of the Lua scripts' caches
        public static var luaCaches: Key { .init(rawValue: "lua.caches") }
        /// the summed size in bytes of the overheads of the Function scripts' caches
        public static var functionsCaches: Key { .init(rawValue: "functions.caches") }
        /// For each of the server's databases, the overheads of the main and expiry dictionaries (overhead.hashtable.main and overhead.hashtable.expires, respectively) are reported in bytes
        public static func db(_ number: Int) -> Key { .init(rawValue: "db.\(number)") }
        /// Total overhead of dictionary buckets in databases (Added in Valkey 8.0)
        public static var overheadDBHashtableLUT: Key { .init(rawValue: "overhead.db.hashtable.lut") }
        /// Temporary memory overhead of database dictionaries currently being rehashed (Added in Valkey 8.0)
        public static var overheadDBHashtableRehashing: Key { .init(rawValue: "overhead.db.hashtable.rehashing") }
        /// The sum of all overheads, i.e. startup.allocated, replication.backlog, clients.slaves, clients.normal, aof.buffer and those of the internal data structures that are used in managing the Valkey keyspace (see INFO's used_memory_overhead)
        public static var overheadTotal: Key { .init(rawValue: "overhead.total") }
        /// Number of DB dictionaries currently being rehashed (Added in Valkey 8.0)
        public static var dbDictionaryRehashingCount: Key { .init(rawValue: "db.dict.rehashing.count") }
        /// The total number of keys stored across all databases in the server
        public static var keysCount: Key { .init(rawValue: "keys.count") }
        /// The ratio between dataset.bytes and keys.count
        public static var keysBytesPerKey: Key { .init(rawValue: "keys.bytes-per-key") }
        /// The size in bytes of the dataset, i.e. overhead.total subtracted from total.allocated (see INFO's used_memory_dataset)
        public static var datasetBytes: Key { .init(rawValue: "dataset.bytes") }
        /// The percentage of dataset.bytes out of the total memory usage
        public static var datasetPercentage: Key { .init(rawValue: "dataset.percentage") }
        /// The percentage of total.allocated out of peak.allocated
        public static var peakPercentage: Key { .init(rawValue: "peak.percentage") }
        /// See INFO's allocator_allocated
        public static var allocatorAllocated: Key { .init(rawValue: "allocator.allocated") }
        /// See INFO's allocator_active
        public static var allocatorActive: Key { .init(rawValue: "allocator.active") }
        /// See INFO's allocator_resident
        public static var allocatorResident: Key { .init(rawValue: "allocator.resident") }
        /// See INFO's allocator_muzzy
        public static var allocatorMuzzy: Key { .init(rawValue: "allocator.muzzy") }
        /// See INFO's allocator_frag_ratio
        public static var allocatorFragmentationRatio: Key { .init(rawValue: "allocator-fragmentation.ratio") }
        /// See INFO's allocator_frag_bytes
        public static var allocatorFragmentationBytes: Key { .init(rawValue: "allocator-fragmentation.bytes") }
        /// See INFO's allocator_rss_ratio
        public static var allocatorRSSRatio: Key { .init(rawValue: "allocator-rss.ratio") }
        /// See INFO's allocator_rss_bytes
        public static var allocatorRSSBytes: Key { .init(rawValue: "allocator-rss.bytes") }
        /// See INFO's rss_overhead_ratio
        public static var rssOverheadRatio: Key { .init(rawValue: "rss-overhead.ratio") }
        /// See INFO's rss_overhead_bytes
        public static var rssOverheadBytes: Key { .init(rawValue: "rss-overhead.bytes") }
        /// See INFO's mem_fragmentation_ratio
        public static var fragmentation: Key { .init(rawValue: "fragmentation") }
        /// See INFO's mem_fragmentation_bytes
        public static var fragmentationBytes: Key { .init(rawValue: "fragmentation.bytes") }
    }

    public typealias Response = [Key: RESPToken]
}

extension MODULE.LIST {
    public typealias Response = [Module]
    public struct Module: RESPTokenDecodable & Sendable {
        /// Module name
        public let name: String
        /// Module version
        public let version: Int
        /// Module path
        public let path: String
        /// Module arguments
        public let args: [String]

        public init(_ token: RESPToken) throws {
            (self.name, self.version, self.path, self.args) = try token.decodeMapValues("name", "ver", "path", "args")
        }
    }
}

extension TIME {
    public struct Response: RESPTokenDecodable & Sendable {
        public let seconds: Int
        public let microSeconds: Int

        public init(_ token: RESPToken) throws {
            (self.seconds, self.microSeconds) = try token.decodeArrayElements()
        }
    }
}
