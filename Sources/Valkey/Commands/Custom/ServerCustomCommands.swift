//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
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
