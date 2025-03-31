//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-redis open source project
//
// Copyright (c) 2025 Apple Inc. and the swift-redis project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-redis project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Errors returned by ``RedisClient``
public struct RedisClientError: Error, CustomStringConvertible {
    public struct ErrorCode: Equatable, Sendable {
        fileprivate enum _Internal: Equatable, Sendable {
            case connectionClosed
            case commandError
        }

        fileprivate let value: _Internal
        fileprivate init(_ value: _Internal) {
            self.value = value
        }

        /// Provided URL is invalid
        public static var connectionClosed: Self { .init(.connectionClosed) }
        /// Error returned by redis command
        public static var commandError: Self { .init(.commandError) }
    }

    public let errorCode: ErrorCode
    public let message: String?
    public init(_ errorCode: ErrorCode, message: String? = nil) {
        self.errorCode = errorCode
        self.message = message
    }

    public var description: String {
        switch self.errorCode.value {
        case .connectionClosed: "Connection has been closed"
        case .commandError: self.message ?? "Redis command returned an error"
        }
    }
}
