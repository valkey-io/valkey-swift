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

/// A command that a Valkey client executes on a connection.
public protocol ValkeyCommand: Sendable, Hashable {
    associatedtype Response: RESPTokenDecodable & Sendable = RESPToken
    associatedtype Keys: Collection<ValkeyKey>

    /// The name of this command.
    static var name: String { get }

    /// Keys affected by command. This is used in cluster mode to determine which
    /// shard to connect to.
    var keysAffected: Keys { get }

    /// Does this command block the connection
    var isBlocking: Bool { get }

    /// Is this command readonly
    var isReadOnly: Bool { get }

    /// Encode Valkey Command into RESP
    /// - Parameter commandEncoder: ValkeyCommandEncoder
    func encode(into commandEncoder: inout ValkeyCommandEncoder)
}

extension ValkeyCommand {
    /// Default to no keys affected
    public var keysAffected: [ValkeyKey] { [] }
    /// Default is not blocking
    public var isBlocking: Bool { false }
    /// Default is not read only
    public var isReadOnly: Bool { false }
}

/// Wrapper for Valkey command that returns the response as a `RESPToken`
@usableFromInline
struct ValkeyRawResponseCommand<Command: ValkeyCommand>: ValkeyCommand {
    @inlinable
    static var name: String { Command.name }

    @usableFromInline
    let command: Command

    @inlinable
    init(_ command: Command) {
        self.command = command
    }

    @usableFromInline
    var keysAffected: [ValkeyKey] { command.keysAffected }

    @inlinable
    func encode(into commandEncoder: inout ValkeyCommandEncoder) {
        self.command.encode(into: &commandEncoder)
    }
}
