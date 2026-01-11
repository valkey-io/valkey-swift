//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

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
            public enum State: String, RESPTokenDecodable, Sendable {
                case connect
                case connecting
                case sync
                case connected

                public init(_ token: RESPToken) throws {
                    let string = try String(token)
                    guard let state = State(rawValue: string) else {
                        throw RESPDecodeError(.unexpectedToken, token: token)
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

extension MODULE.LIST {
    public typealias Response = [Module]
    public struct Module: RESPTokenDecodable & Sendable {
        public let name: String
        public let version: String

        public init(_ token: RESPToken) throws {
            preconditionFailure("Waiting for decodeMapElements to be merged")
            //(self.name, self.version) = try token.decodeMapElements("name", "ver")
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
