//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
/// A type that provides the ability to send a Valkey command and get a response.
@available(valkeySwift 1.0, *)
public protocol ValkeyClientProtocol: Sendable {
    /// Send RESP command to Valkey connection
    /// - Parameter command: ValkeyCommand structure
    /// - Returns: The command response as defined in the ValkeyCommand
    func execute<Command: ValkeyCommand>(_ command: Command) async throws -> Command.Response

    /// Pipeline a series of commands to Valkey connection
    ///
    /// Once all the responses for the commands have been received the function returns
    /// an array of RESPToken Results, one for each command.
    ///
    /// This is an alternative version of the pipelining function ``ValkeyClient/execute(_:)->(_,_)``
    /// that allows for a collection of ValkeyCommands. It provides more flexibility but
    /// is more expensive to run and the command responses are returned as ``RESPToken``
    /// instead of the response type for the command.
    ///
    /// - Parameter commands: Collection of ValkeyCommands
    /// - Returns: Array holding the RESPToken responses of all the commands
    @inlinable
    func execute(_ commands: [any ValkeyCommand]) async -> sending [Result<RESPToken, Error>]
}
