//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore

extension SCAN {
    public struct Response: RESPTokenDecodable, Sendable {
        public let cursor: Int
        public let keys: RESPToken.Array

        public init(fromRESP token: RESPToken) throws {
            (self.cursor, self.keys) = try token.decodeArrayElements(as: (Int, RESPToken.Array).self)
        }
    }
}
