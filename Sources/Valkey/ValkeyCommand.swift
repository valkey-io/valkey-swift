//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
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

    /// Type-erased keys affected. This property works correctly when accessed through
    /// existential types (any ValkeyCommand) unlike keysAffected which uses associated types.
    var keysAffectedArray: [ValkeyKey] { get }

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
    /// Type-erased keys accessor - converts associated type to array
    public var keysAffectedArray: [ValkeyKey] { Array(keysAffected) }
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
    var keysAffected: [ValkeyKey] { command.keysAffectedArray }

    @usableFromInline
    var keysAffectedArray: [ValkeyKey] { command.keysAffectedArray }

    @inlinable
    func encode(into commandEncoder: inout ValkeyCommandEncoder) {
        self.command.encode(into: &commandEncoder)
    }
}
