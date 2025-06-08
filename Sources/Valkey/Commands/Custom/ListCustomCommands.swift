//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift project
//
// Copyright (c) 2025 the valkey-swift authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See valkey-swift/CONTRIBUTORS.txt for the list of valkey-swift authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

extension LMPOP {
    /// - Returns: One of the following
    ///     * [Null]: If no element could be popped.
    ///     * [Array]: List key from which elements were popped.
    public struct OptionalResponse: RESPTokenDecodable, Sendable {
        let key: ValkeyKey
        let values: RESPToken.Array

        public init(fromRESP token: RESPToken) throws {
            switch token.value {
            case .array(let array):
                (self.key, self.values) = try array.decodeElements()
            default:
                throw RESPParsingError(code: .unexpectedType, buffer: token.base)
            }
        }
    }
    public typealias Response = OptionalResponse?
}
