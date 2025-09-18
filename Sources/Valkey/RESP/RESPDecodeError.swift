//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
/// Error returned when decoding a RESPToken.
/// Error thrown when decoding RESPTokens
public struct RESPDecodeError: Error, CustomStringConvertible {
    @usableFromInline
    enum InternalError: Sendable {
        case unexpectedTokenIdentifier(expected: [RESPTypeIdentifier])
        case invalidArraySize
        case missingToken(key: String)
        case cannotParseInteger
        case cannotParseDouble
        case unexpectedToken
    }
    @usableFromInline
    let error: InternalError
    let token: RESPToken.Value

    public static func unexpectedTokenIdentifier(expected: [RESPTypeIdentifier], token: RESPToken) -> Self {
        .init(error: .unexpectedTokenIdentifier(expected: expected), token: token.value)
    }
    public static func invalidArraySize(_ array: RESPToken.Array) -> Self { .init(error: .invalidArraySize, token: .array(array)) }
    public static func missingToken(key: String, token: RESPToken) -> Self { .init(error: .missingToken(key: key), token: token.value) }
    public static func cannotParseInteger(token: RESPToken) -> Self { .init(error: .cannotParseInteger, token: token.value) }
    public static func cannotParseDouble(token: RESPToken) -> Self { .init(error: .cannotParseDouble, token: token.value) }
    public static func unexpectedToken(token: RESPToken) -> Self { .init(error: .unexpectedToken, token: token.value) }

    public var description: String {
        switch self.error {
        case .unexpectedTokenIdentifier(let expected):
            if expected.count == 0 {
                return "Found unexpected token while decoding \(self.token)"
            } else if expected.count == 1 {
                return "Expected to find a \(expected[0]) token but found a \(self.token)"
            } else {
                let expectedTokens = "\(expected.dropLast().map { "\"\($0)\"" }.joined(separator: ", ")) or \"\(expected.last!)\""
                return "Expected to find a \(expectedTokens) token but found a \(self.token)"
            }
        case .invalidArraySize:
            return "Invalid array length while decoding \(self.token)"
        case .missingToken(let key):
            return "Expected map to contain token with key \"\(key)\" while decoding \(self.token)"
        case .cannotParseInteger:
            return "Cannot parse integer while decoding \(self.token)"
        case .cannotParseDouble:
            return "Cannot parse double while decoding \(self.token)"
        case .unexpectedToken:
            return "Token was unexpected \(self.token)"
        }
    }
}
