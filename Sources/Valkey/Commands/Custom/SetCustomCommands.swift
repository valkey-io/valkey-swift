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

extension SPOP {
    public typealias Response = [RESPToken]
}

extension SSCAN {
    public struct Response: RESPTokenDecodable, Sendable {
        let cursor: Int
        let elements: RESPToken.Array

        public init(fromRESP token: RESPToken) throws {
            // cursor is encoded as a bulkString, but should be
            let (cursorString, elements) = try token.decodeArrayElements(as: (String, RESPToken.Array).self)
            guard let cursor = Int(cursorString) else { throw RESPParsingError(code: .unexpectedType, buffer: token.base) }
            self.cursor = cursor
            self.elements = elements
        }
    }
}
