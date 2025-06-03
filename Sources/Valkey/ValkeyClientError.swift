//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey open source project
//
// Copyright (c) 2025 the swift-valkey project authors
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
            case connectionClosing
            case connectionClosed
            case commandError
            case subscriptionError
            case unsolicitedToken
            case transactionAborted
            case tokenDoesNotExist
            case cancelled
            case connectionClosedDueToCancellation
        }

        fileprivate let value: _Internal
        fileprivate init(_ value: _Internal) {
            self.value = value
        }

        /// Connection is closing
        public static var connectionClosing: Self { .init(.connectionClosing) }
        /// Connection is closed
        public static var connectionClosed: Self { .init(.connectionClosed) }
        /// Error returned by Valkey command
        public static var commandError: Self { .init(.commandError) }
        /// Error returned by Valkey subscription
        public static var subscriptionError: Self { .init(.subscriptionError) }
        /// Received an unsolicited token from the server
        public static var unsolicitedToken: Self { .init(.unsolicitedToken) }
        /// Transaction was aborted because a watched key was touched
        public static var transactionAborted: Self { .init(.transactionAborted) }
        /// Expected token to exist. Throw when iterating an array of tokens that is too short
        public static var tokenDoesNotExist: Self { .init(.tokenDoesNotExist) }
        /// Task was cancelled
        public static var cancelled: Self { .init(.cancelled) }
        /// Connection was closed because another command was cancelled
        public static var connectionClosedDueToCancellation: Self { .init(.connectionClosedDueToCancellation) }
    }

    public let errorCode: ErrorCode
    public let message: String?
    public init(_ errorCode: ErrorCode, message: String? = nil) {
        self.errorCode = errorCode
        self.message = message
    }

    public var description: String {
        switch self.errorCode.value {
        case .connectionClosing: "Connection is closing"
        case .connectionClosed: "Connection has been closed"
        case .commandError: self.message ?? "Valkey command returned an error"
        case .subscriptionError: self.message ?? "Received invalid subscription push event"
        case .unsolicitedToken: self.message ?? "Received unsolicited token from Valkey server"
        case .transactionAborted: self.message ?? "Transaction was aborted because a watched key was touched"
        case .tokenDoesNotExist: self.message ?? "Expected token does not exist."
        case .cancelled: self.message ?? "Task was cancelled."
        case .connectionClosedDueToCancellation: self.message ?? "Connection was closed because another command was cancelled."
        }
    }
}
