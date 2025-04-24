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

/// Errors returned by ``ValkeyClient``
public struct ValkeyClientError: Error, CustomStringConvertible, Equatable {
    public struct ErrorCode: Equatable, Sendable {
        fileprivate enum _Internal: Equatable, Sendable {
            case connectionClosed
            case commandError
            case subscriptionError
        }

        fileprivate let value: _Internal
        fileprivate init(_ value: _Internal) {
            self.value = value
        }

        /// Connection is closed
        public static var connectionClosed: Self { .init(.connectionClosed) }
        /// Error returned by Valkey command
        public static var commandError: Self { .init(.commandError) }
        /// Error returned by Valkey subscription
        public static var subscriptionError: Self { .init(.subscriptionError) }
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
        case .commandError: self.message ?? "Valkey command returned an error"
        case .subscriptionError: self.message ?? "Received invalid subscription push event"
        }
    }
}
