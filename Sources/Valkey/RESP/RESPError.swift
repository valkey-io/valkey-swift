//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey open source project
//
// Copyright (c) 2025 Apple Inc. and the swift-valkey project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-valkey project authors
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
        }

        private let base: Base

        private init(_ base: Base) {
            self.base = base
        }

        public static let invalidLeadingByte = Self.init(.invalidLeadingByte)
        public static let invalidData = Self.init(.invalidData)
        public static let tooDeeplyNestedAggregatedTypes = Self.init(.tooDeeplyNestedAggregatedTypes)
        public static let missingColonInVerbatimString = Self.init(.missingColonInVerbatimString)
        public static let canNotParseInteger = Self.init(.canNotParseInteger)
        public static let canNotParseDouble = Self.init(.canNotParseDouble)
        public static let canNotParseBigNumber = Self.init(.canNotParseBigNumber)
        public static let unexpectedType = Self.init(.unexpectedType)

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
            }
        }
    }

    public var code: Code
    public var buffer: ByteBuffer

    @usableFromInline
    package init(code: Code, buffer: ByteBuffer) {
        self.code = code
        self.buffer = buffer
    }
}
