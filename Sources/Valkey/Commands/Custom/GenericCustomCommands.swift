//
// This source file is part of the valkey-swift project
// Copyright (c) 2025-2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore

extension SCAN {
    public struct Response: RESPTokenDecodable, Sendable {
        public let cursor: Int
        public let keys: RESPToken.Array

        public init(_ token: RESPToken) throws {
            (self.cursor, self.keys) = try token.decodeArrayElements(as: (Int, RESPToken.Array).self)
        }
    }
}

extension WAITAOF {
    public struct Response: RESPTokenDecodable, Sendable {
        /// Has local Valkey node fsynced to AOF(Append only file) all writes performed in the context of the current connection
        public let localSynced: Bool
        /// Number of replicas that have acknowledged they have fsynced to AOF(Append only file) all writes performed in the
        /// context of the current connection
        public let numberOfReplicasSynced: Int

        public init(_ token: RESPToken) throws {
            let localSynced: Int
            (localSynced, self.numberOfReplicasSynced) = try token.decodeArrayElements()
            self.localSynced = localSynced == 1 ? true : false
        }
    }
}
