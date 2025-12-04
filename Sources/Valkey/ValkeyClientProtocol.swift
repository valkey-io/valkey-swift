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
    associatedtype Subscription: AsyncSequence<ValkeySubscriptionMessage, any Error>
    /// Send RESP command to Valkey connection
    /// - Parameter command: ValkeyCommand structure
    /// - Returns: The command response as defined in the ValkeyCommand
    func execute<Command: ValkeyCommand>(_ command: Command) async throws -> Command.Response

    /// Pipeline a series of commands to Valkey connection
    ///
    /// Once all the responses for the commands have been received the function returns
    /// an array of RESPToken Results, one for each command.
    ///
    /// This is an alternative version of the pipelining function ``ValkeyConnection/execute(_:)->(_,_)``
    /// that allows for a collection of ValkeyCommands. It provides more flexibility but
    /// is more expensive to run and the command responses are returned as ``RESPToken``
    /// instead of the response type for the command.
    ///
    /// - Parameter commands: Collection of ValkeyCommands
    /// - Returns: Array holding the RESPToken responses of all the commands
    func execute(_ commands: [any ValkeyCommand]) async -> [Result<RESPToken, any Error>]

    /// Pipeline a series of commands as a transaction to Valkey connection
    ///
    /// Another client will never be served in the middle of the execution of these
    /// commands. See https://valkey.io/topics/transactions/ for more information.
    ///
    /// EXEC and MULTI commands are added to the pipelined commands and the output
    /// of the EXEC command is transformed into an array of RESPToken Results, one for
    /// each command.
    ///
    /// This is an alternative version of the transaction function ``ValkeyConnection/transaction(_:)->(_,_)``
    /// that allows for a collection of ValkeyCommands. It provides more flexibility but the command
    /// responses are returned as ``RESPToken`` instead of the response type for the command.
    ///
    /// - Parameter commands: Collection of ValkeyCommands
    /// - Returns: Array holding the RESPToken responses of all the commands
    /// - Throws: ValkeyTransactionError when EXEC aborts
    func transaction(_ commands: [any ValkeyCommand]) async throws -> [Result<RESPToken, any Error>]

    /// Execute subscribe command and run closure using related ``ValkeySubscription``
    /// AsyncSequence
    ///
    /// This should not be called directly, used the related commands
    /// ``ValkeyClientProtocol/subscribe(to:process:)`` or
    /// ``ValkeyClientProtocol/psubscribe(to:process:)``
    func _subscribe<Value>(
        command: some ValkeySubscribeCommand,
        process: nonisolated(nonsending) (Subscription) async throws -> Value
    ) async throws -> Value
}

@available(valkeySwift 1.0, *)
extension ValkeyClientProtocol {
    /// Subscribe to list of channels and run closure with subscription
    ///
    /// When the closure is exited the channels are automatically unsubscribed from. It is
    /// possible to have multiple subscriptions running on the same connection and unsubscribe
    /// commands will only be sent to Valkey when there are no subscriptions active for that
    /// channel
    ///
    /// - Parameters:
    ///   - channels: list of channels to subscribe to
    ///   - isolation: Actor isolation
    ///   - process: Closure that is called with subscription async sequence
    /// - Returns: Return value of closure
    @inlinable
    public func subscribe<Value>(
        to channels: String...,
        process: (Subscription) async throws -> Value
    ) async throws -> Value {
        try await self.subscribe(to: channels, process: process)
    }

    /// Subscribe to list of channels and run closure with subscription
    ///
    /// When the closure is exited the channels are automatically unsubscribed from. It is
    /// possible to have multiple subscriptions running on the same connection and unsubscribe
    /// commands will only be sent to Valkey when there are no subscriptions active for that
    /// channel
    ///
    /// - Parameters:
    ///   - channels: list of channels to subscribe to
    ///   - isolation: Actor isolation
    ///   - process: Closure that is called with subscription async sequence
    /// - Returns: Return value of closure
    @inlinable
    public nonisolated(nonsending) func subscribe<Value>(
        to channels: [String],
        process: (Subscription) async throws -> Value
    ) async throws -> Value {
        try await self._subscribe(
            command: SUBSCRIBE(channels: channels),
            process: process
        )
    }

    /// Subscribe to list of channel patterns and run closure with subscription
    ///
    /// When the closure is exited the patterns are automatically unsubscribed from.
    ///
    /// When running subscribe from `ValkeyClient` a single connection is used for
    /// all subscriptions.
    ///
    /// - Parameters:
    ///   - patterns: list of channel patterns to subscribe to
    ///   - isolation: Actor isolation
    ///   - process: Closure that is called with subscription async sequence
    /// - Returns: Return value of closure
    @inlinable
    public func psubscribe<Value>(
        to patterns: String...,
        process: (Subscription) async throws -> Value
    ) async throws -> Value {
        try await self.psubscribe(to: patterns, process: process)
    }

    /// Subscribe to list of pattern matching channels and run closure with subscription
    ///
    /// When the closure is exited the patterns are automatically unsubscribed from.
    ///
    /// When running subscribe from `ValkeyClient` a single connection is used for
    /// all subscriptions.
    ///
    /// - Parameters:
    ///   - patterns: list of channel patterns to subscribe to
    ///   - isolation: Actor isolation
    ///   - process: Closure that is called with subscription async sequence
    /// - Returns: Return value of closure
    @inlinable
    public func psubscribe<Value>(
        to patterns: [String],
        process: (Subscription) async throws -> Value
    ) async throws -> Value {
        try await self._subscribe(
            command: PSUBSCRIBE(patterns: patterns),
            process: process
        )
    }
}
