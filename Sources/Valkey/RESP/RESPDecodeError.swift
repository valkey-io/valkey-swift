//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
/// Error returned when decoding a RESPToken.
/// Error thrown when decoding RESPTokens
public struct RESPDecodeError: Error {
    /// Error code for decode error
    public struct ErrorCode: Sendable, Equatable, CustomStringConvertible {
        fileprivate enum Code: Sendable, Equatable {
            case tokenMismatch
            case invalidArraySize
            case missingToken
            case cannotParseInteger
            case cannotParseDouble
            case unexpectedToken
        }

        fileprivate let code: Code
        fileprivate init(_ code: Code) {
            self.code = code
        }

        public var description: String { String(describing: self.code) }

        /// Token does not match one of the expected tokens
        public static var tokenMismatch: Self { .init(.tokenMismatch) }
        /// Does not match the expected array size
        public static var invalidArraySize: Self { .init(.invalidArraySize) }
        /// Token is missing
        public static var missingToken: Self { .init(.missingToken) }
        /// Failed to parse an integer
        public static var cannotParseInteger: Self { .init(.cannotParseInteger) }
        /// Failed to parse a double
        public static var cannotParseDouble: Self { .init(.cannotParseDouble) }
        /// Token is not as expected
        public static var unexpectedToken: Self { .init(.unexpectedToken) }
    }
    public let errorCode: ErrorCode
    public let message: String?
    public let token: RESPToken.Value

    public init(_ errorCode: ErrorCode, token: RESPToken.Value, message: String? = nil) {
        self.errorCode = errorCode
        self.token = token
        self.message = message
    }

    public init(_ errorCode: ErrorCode, token: RESPToken, message: String? = nil) {
        self = .init(errorCode, token: token.value, message: message)
    }

    /// Token does not match one of the expected tokens
    public static func tokenMismatch(expected: [RESPTypeIdentifier], token: RESPToken) -> Self {
        if expected.count == 0 {
            return .init(.tokenMismatch, token: token, message: "Found unexpected token while decoding")
        } else if expected.count == 1 {
            return .init(.tokenMismatch, token: token, message: "Expected to find a \(expected[0])")
        } else {
            let expectedTokens = "\(expected.dropLast().map { "\($0)" }.joined(separator: ", ")) or \(expected.last!)"
            return .init(.tokenMismatch, token: token, message: "Expected to find a \(expectedTokens) token")
        }
    }
    /// Does not match the expected array size
    public static func invalidArraySize(_ array: RESPToken.Array, expectedSize: Int? = nil, minExpectedSize: Int? = nil) -> Self {
        let message: String
        if let minExpectedSize = minExpectedSize {
            message = "Expected array of size at least \(minExpectedSize) but got an array of size \(array.count)"
        } else if let expectedSize = expectedSize {
            message = "Expected array of size \(expectedSize) but got an array of size \(array.count)"
        } else {
            message = "Expected array of a different size but got an array of size \(array.count)"
        }

        return .init(
            .invalidArraySize,
            token: .array(array),
            message: message
        )
    }
    /// Token associated with key is missing
    public static func missingToken(key: String, token: RESPToken) -> Self {
        .init(.missingToken, token: token, message: "Expected map to contain token with key \"\(key)\"")
    }
}

extension RESPDecodeError: CustomStringConvertible {
    public var description: String {
        "Error: \"\(self.message ?? String(describing: self.errorCode))\", token: \(self.token.debugDescription)"
    }
}
