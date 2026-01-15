//
// This source file is part of the valkey-swift project
// Copyright (c) 2025-2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
extension SSCAN {
    public struct Response: RESPTokenDecodable, Sendable {
        public let cursor: Int
        public let elements: RESPToken.Array

        public init(_ token: RESPToken) throws(RESPDecodeError) {
            // cursor is encoded as a bulkString, but should be
            let (cursor, elements) = try token.decodeArrayElements(as: (Int, RESPToken.Array).self)
            self.cursor = cursor
            self.elements = elements
        }
    }
}
