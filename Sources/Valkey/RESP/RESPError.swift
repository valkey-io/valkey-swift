//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of valkey-swift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore

/// This error is thrown if a RESP3 package could not be decoded.
///
/// If you see this error, there a two potential reasons this might happen:
///
///   1. The Swift RESP3 implementation is wrong
///   2. You are contacting an untrusted backend
///
public struct RESPParsingError: Error {
    /// The error code associated with an error parsing a response.
    public struct Code: Hashable, Sendable, CustomStringConvertible {
        private enum Base {
            case invalidLeadingByte
            case invalidData
            case tooDeeplyNestedAggregatedTypes
            case missingColonInVerbatimString
            case canNotParseInteger
            case canNotParseDouble
            case canNotParseBigNumber
            case unexpectedType
            case invalidElementCount
        }

        private let base: Base

        private init(_ base: Base) {
            self.base = base
        }

        /// The leading byte is invalid.
        public static let invalidLeadingByte = Self.init(.invalidLeadingByte)
        /// The data is invalid.
        public static let invalidData = Self.init(.invalidData)
        /// The nested aggregate types are too deeply nested.
        public static let tooDeeplyNestedAggregatedTypes = Self.init(.tooDeeplyNestedAggregatedTypes)
        /// A colon is missing within a verbatim string
        public static let missingColonInVerbatimString = Self.init(.missingColonInVerbatimString)
        /// Can't parse the data as an integer.
        public static let canNotParseInteger = Self.init(.canNotParseInteger)
        /// Can't parse the data as a Double.
        public static let canNotParseDouble = Self.init(.canNotParseDouble)
        /// Can't parse the data as a big number.
        public static let canNotParseBigNumber = Self.init(.canNotParseBigNumber)
        /// The type is unexpected.
        public static let unexpectedType = Self.init(.unexpectedType)
        /// There is an invalid element count.
        public static let invalidElementCount = Self.init(.invalidElementCount)

        public var description: String {
            switch self.base {
            case .invalidLeadingByte:
                return "invalidLeadingByte"
            case .invalidData:
                return "invalidData"
            case .tooDeeplyNestedAggregatedTypes:
                return "tooDeeplyNestedAggregatedTypes"
            case .missingColonInVerbatimString:
                return "missingColonInVerbatimString"
            case .canNotParseInteger:
                return "canNotParseInteger"
            case .canNotParseDouble:
                return "canNotParseDouble"
            case .canNotParseBigNumber:
                return "canNotParseBigNumber"
            case .unexpectedType:
                return "unexpectedType"
            case .invalidElementCount:
                return "invalidElementCount"
            }
        }
    }

    /// The error code
    public var code: Code

    /// The byte buffer that failed to parse.
    public var buffer: ByteBuffer

    @usableFromInline
    package init(code: Code, buffer: ByteBuffer) {
        self.code = code
        self.buffer = buffer
    }
}
