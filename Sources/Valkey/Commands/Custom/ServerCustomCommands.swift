//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
extension ROLE {
    public enum Response: RESPTokenDecodable, Sendable {
        struct DecodeError: Error {}
        public struct Primary: Sendable {
            public struct Replica: RESPTokenDecodable, Sendable {
                public let ip: String
                public let port: Int
                public let replicationOffset: Int

                public init(fromRESP token: RESPToken) throws {
                    (self.ip, self.port, self.replicationOffset) = try token.decodeArrayElements()
                }
            }
            public let replicationOffset: Int
            public let replicas: [Replica]

            init(arrayIterator: inout RESPToken.Array.Iterator) throws {
                guard let replicationOffsetToken = arrayIterator.next(), let replicasToken = arrayIterator.next() else {
                    throw DecodeError()
                }
                self.replicationOffset = try .init(fromRESP: replicationOffsetToken)
                self.replicas = try .init(fromRESP: replicasToken)
            }
        }
        public struct Replica: Sendable {
            public enum State: String, RESPTokenDecodable, Sendable {
                case connect
                case connecting
                case sync
                case connected

                public init(fromRESP token: RESPToken) throws {
                    let string = try String(fromRESP: token)
                    guard let state = State(rawValue: string) else {
                        throw RESPDecodeError.unexpectedToken(token: token)
                    }
                    self = state
                }
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
                    throw DecodeError()
                }
                self.primaryIP = try .init(fromRESP: primaryIPToken)
                self.primaryPort = try .init(fromRESP: primaryPortToken)
                self.state = try .init(fromRESP: stateToken)
                self.replicationOffset = try .init(fromRESP: replicationToken)
            }
        }
        public struct Sentinel: Sendable {
            public let primaryNames: [String]

            init(arrayIterator: inout RESPToken.Array.Iterator) throws {
                guard let primaryNamesToken = arrayIterator.next() else { throw DecodeError() }
                self.primaryNames = try .init(fromRESP: primaryNamesToken)
            }
        }
        case primary(Primary)
        case replica(Replica)
        case sentinel(Sentinel)

        public init(fromRESP token: RESPToken) throws {
            switch token.value {
            case .array(let array):
                do {
                    var iterator = array.makeIterator()
                    guard let roleToken = iterator.next() else {
                        throw RESPDecodeError.invalidArraySize(array)
                    }
                    let role = try String(fromRESP: roleToken)
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
                        throw DecodeError()
                    }
                } catch {
                    throw RESPDecodeError.unexpectedToken(token: token)
                }
            default:
                throw RESPDecodeError.unexpectedTokenIdentifier(expected: [.array], token: token)
            }
        }
    }
}
