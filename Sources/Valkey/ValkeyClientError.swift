//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
/// Errors returned by a Valkey client.
public struct ValkeyClientError: Error, CustomStringConvertible {

    /// Valkey client error codes
    public struct ErrorCode: Equatable, Sendable, CustomStringConvertible {
        fileprivate enum _Internal: Equatable, Sendable {
            case connectionClosing
            case connectionClosed
            case commandError
            case subscriptionError
            case unsolicitedToken
            case tokenDoesNotExist
            case cancelled
            case connectionClosedDueToCancellation
            case timeout
            case clientIsShutDown
            case connectionCreationCircuitBreakerTripped
            case respParsingError
            case respDecodeError
            case clusterError
            case unrecognisedError
        }

        fileprivate let value: _Internal
        fileprivate init(_ value: _Internal) {
            self.value = value
        }

        /// The connection is closing.
        public static var connectionClosing: Self { .init(.connectionClosing) }
        /// The connection is closed.
        public static var connectionClosed: Self { .init(.connectionClosed) }
        /// An rrror returned by Valkey command.
        public static var commandError: Self { .init(.commandError) }
        /// An error returned by Valkey subscription.
        public static var subscriptionError: Self { .init(.subscriptionError) }
        /// Received an unsolicited token from the server.
        public static var unsolicitedToken: Self { .init(.unsolicitedToken) }
        /// Expected token to exist.
        ///
        /// Thrown when iterating an array of tokens that is too short.
        public static var tokenDoesNotExist: Self { .init(.tokenDoesNotExist) }
        /// Task cancelled.
        public static var cancelled: Self { .init(.cancelled) }
        /// Connection closed because another command was cancelled.
        public static var connectionClosedDueToCancellation: Self { .init(.connectionClosedDueToCancellation) }
        /// Connection closed because it timed out.
        public static var timeout: Self { .init(.timeout) }
        /// Client is shutdown.
        public static var clientIsShutDown: Self { .init(.clientIsShutDown) }
        /// Connection pool connection creation circuit breaker triggered
        public static var connectionCreationCircuitBreakerTripped: Self { .init(.connectionCreationCircuitBreakerTripped) }
        /// Found error while trying to parse RESP returned from server
        public static var respParsingError: Self { .init(.respParsingError) }
        /// RESPToken decode error
        public static var respDecodeError: Self { .init(.respDecodeError) }
        /// Cluster error
        public static var clusterError: Self { .init(.clusterError) }
        /// Unrecognised error
        public static var unrecognisedError: Self { .init(.unrecognisedError) }

        /// The string representation of the error.
        public var description: String {
            switch self.value {
            case .connectionClosing: "Connection is closing."
            case .connectionClosed: "Connection has been closed."
            case .commandError: "Valkey command returned an error."
            case .subscriptionError: "Received invalid subscription push event."
            case .unsolicitedToken: "Received unsolicited token from Valkey server."
            case .tokenDoesNotExist: "Expected token does not exist."
            case .cancelled: "Task was cancelled."
            case .connectionClosedDueToCancellation: "Connection was closed because another command was cancelled."
            case .timeout: "Connection was closed because it timed out."
            case .clientIsShutDown: "Client is shutdown and not serving requests."
            case .connectionCreationCircuitBreakerTripped: "Connection pool connection creation circuit breaker triggered."
            case .respParsingError: "Found error while trying to parse RESP returned from server."
            case .respDecodeError: "Error thrown while decoding a RESPToken."
            case .clusterError: "Cluster reported an error."
            case .unrecognisedError: "Unrecognised error."
            }
        }
    }

    /// The error code
    public let errorCode: ErrorCode
    /// An optional message associated with the error code
    public let message: String?
    /// If there is an underlying error it will be stored here
    public let underlyingError: Error?
    /// Source file where the error was created
    public let file: StaticString
    /// Source line where the error was created
    public let line: UInt

    /// Create a new error code.
    /// - Parameters:
    ///   - errorCode: The error code.
    ///   - message: The message to include.
    ///   - error: The underlying error.
    ///   - file: Source file (automatically captured).
    ///   - line: Source line (automatically captured).
    public init(
        _ errorCode: ErrorCode,
        message: String? = nil,
        error: Error? = nil,
        file: StaticString = #fileID,
        line: UInt = #line
    ) {
        self.errorCode = errorCode
        self.message = message
        self.underlyingError = error
        self.file = file
        self.line = line
    }

    /// The string representation of the error.
    public var description: String {
        var result = "\(self.errorCode)"
        if let message = self.message {
            result += " \(message)"
        }
        if let underlyingError = self.underlyingError {
            result += "\n  Underlying error: \(underlyingError)"
        }
        result += "\n  at \(self.file):\(self.line)"
        return result
    }
}
