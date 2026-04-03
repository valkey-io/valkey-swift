//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import Logging
import NIOCore
import NIOEmbedded
import Testing
import Valkey

/// Standalone primary replica topology
actor TestSentinelTopology {
    enum Role {
        case primary(String)
        case replica(String)
        case sentinel
    }
    enum Flag: Substring {
        case primary = "master"
        case replica = "slave"
        case sentinel
        case disconnected
        case s_down
        // case o_down
        case master_down
    }
    struct Address: Hashable, CustomStringConvertible {
        let host: String
        let port: Int

        var description: String { "\(host):\(port)" }
    }
    struct Node {
        var flags: Set<SentinelInstance.Flag>
        var address: Address
    }
    struct Topology {
        var primary: Node
        var replicas: [Node]
        var keyValueMap: [String: String]
    }

    var namedTopologies: [String: Topology]
    var sentinels: [Node]
    private(set) var addressMap: [Address: Role]

    init(sentinels: [Address]) async {
        self.sentinels = sentinels.map { .init(flags: [.sentinel], address: $0) }
        self.namedTopologies = [:]
        self.addressMap = [:]
        self.updateAddressMap()
    }

    func updateAddressMap() {
        self.addressMap = [:]
        for sentinel in self.sentinels {
            self.addressMap[sentinel.address] = .sentinel
        }
        for (key, value) in namedTopologies {
            self.addressMap[value.primary.address] = .primary(key)
            for replica in value.replicas {
                self.addressMap[replica.address] = .replica(key)
            }
        }
    }

    func setKey(primary: String, key: String, value: String) {
        self.namedTopologies[primary]?.keyValueMap[key] = value
    }

    func getKey(primary: String, key: String) -> String? {
        self.namedTopologies[primary]?.keyValueMap[key]
    }

    /// Create Mock servers for cluster
    func mock(logger: Logger) async -> MockServerConnections {
        let mockConnections = MockServerConnections(logger: logger)
        for address in self.addressMap.keys {
            await addNode(to: mockConnections, address: address, logger: logger)
        }
        return mockConnections
    }

    /// Add Valkey node to mock connections
    func addNode(to mockConnections: MockServerConnections, address: Address, logger: Logger) async {
        guard let addressDetails = self.addressMap[address] else { return }

        switch addressDetails {
        case .primary(let name):
            break
        case .replica(let name):
            break
        case .sentinel:
            break
        }
        await mockConnections.addValkeyServer(.hostname(address.host, port: address.port)) { command in
            var iterator = command.makeIterator()
            switch iterator.next() {
            case "GET":
                guard let key = iterator.next() else { return .bulkError("ERR invalid command") }
                // Keys with $address prefix are special as they return the address of the node
                if key.hasPrefix("$address") {
                    return .bulkString(address.description)
                }
                return await self.getKey(key).map { .bulkString($0) } ?? .null

            case "SET":
                guard let key = iterator.next() else { return .bulkError("ERR invalid command") }
                guard let value = iterator.next() else { return .bulkError("ERR invalid command") }
                let addressDetails = await self.addressMap[address]
                if addressDetails == .replica {
                    return await .bulkError("REDIRECT \(self.primary.address)")
                }
                // Keys with $address prefix are special as they return the address of the node
                if key.hasPrefix("$address") {
                    return .bulkString(address.description)
                }
                await self.setKey(key, value: value)
                return .simpleString("OK")
            case "ROLE":
                let addressDetails = await self.addressMap[address]
                if addressDetails == .primary {
                    return await .array([
                        .bulkString("master"),
                        .number(1001),
                        .array(
                            self.replicas.map {
                                RESP3Value.array([
                                    .bulkString($0.address.host),
                                    .bulkString("\($0.address.port)"),
                                    .bulkString("1001"),
                                ])
                            }
                        ),
                    ])
                } else {
                    return await .array([
                        .bulkString("slave"),
                        .bulkString(self.primary.address.host),
                        .number(Int64(self.primary.address.port)),
                        .bulkString("connected"),
                        .number(1001),
                    ])
                }
            default:
                return nil
            }
        }
    }
}
