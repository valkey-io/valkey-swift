//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import NIOCore

extension LMOVE {
    public typealias Response = ByteBuffer?
}

extension LMPOP {
    /// - Returns: One of the following
    ///     * [Null]: If no element could be popped.
    ///     * [Array]: List key from which elements were popped.
    public struct OptionalResponse: RESPTokenDecodable, Sendable {
        public let key: ValkeyKey
        public let values: RESPToken.Array

        public init(fromRESP token: RESPToken) throws {
            switch token.value {
            case .array(let array):
                (self.key, self.values) = try array.decodeElements()
            default:
                throw RESPDecodeError.tokenMismatch(expected: [.array], token: token)
            }
        }
    }
    public typealias Response = OptionalResponse?
}

extension BLMPOP {
    /// - Returns: One of the following
    ///     * [Null]: If no element could be popped.
    ///     * [Array]: List key from which elements were popped.
    public typealias Response = LMPOP.Response
}
