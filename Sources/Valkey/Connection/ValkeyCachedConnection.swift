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

import Logging
import NIOCore
import NIOPosix

/// Cache of Valkey commands and responses
@usableFromInline
actor ValkeyCache {
    /// Cache of commands. The key is a hash of the command
    var cachedCommands: [Int: RESPToken]
    /// Map of keys to array of command hashes affected by key
    var cachedKeys: [ValkeyKey: [Int]]

    init() {
        self.cachedCommands = [:]
        self.cachedKeys = [:]
    }

    @usableFromInline
    func getCachedValue<Command: ValkeyCommand>(for command: Command) -> RESPToken? {
        let hash = self.hash(for: command)
        return cachedCommands[hash]
    }

    @usableFromInline
    func storeCachedValue<Command: ValkeyCommand>(for command: Command, cachedResponse: RESPToken) {
        guard command.readOnly else { return }
        let hash = self.hash(for: command)

        cachedCommands[hash] = cachedResponse
        for key in command.keysAffected {
            self.cachedKeys[key, default: []].append(hash)
        }
    }

    func invalidate(key: ValkeyKey) {
        if let cachedCommands = self.cachedKeys[key] {
            for commandHash in cachedCommands {
                self.cachedCommands.removeValue(forKey: commandHash)
            }
        }
        self.cachedKeys.removeValue(forKey: key)
    }

    func hash<Command: ValkeyCommand>(for command: Command) -> Int {
        var hasher = Hasher()
        hasher.combine(command)
        return hasher.finalize()
    }
}

/// Connection to Valkey database backed by a cache
public final class ValkeyCachedConnection: ValkeyCommands, Sendable {
    /// invalidation subscription channel
    static let invalidateChannel = "__redis__:invalidate"
    @usableFromInline
    let connection: ValkeyConnection
    @usableFromInline
    let cache: ValkeyCache

    package init(connection: ValkeyConnection) {
        self.connection = connection
        self.cache = .init()
    }

    /// Close connection
    /// - Returns: EventLoopFuture that is completed on connection closure
    public func close() -> EventLoopFuture<Void> {
        self.connection.close()
    }

    /// Send RESP command to Valkey connection
    /// - Parameter command: RESPCommand structure
    /// - Returns: The command response as defined in the RESPCommand
    @inlinable
    public func send<Command: ValkeyCommand>(command: Command) async throws -> Command.Response {
        if command.readOnly, let response = await self.cache.getCachedValue(for: command) {
            return try .init(fromRESP: response)
        }
        let response = try await self.connection.send(command: ValkeyRawResponseCommand(command))
        if command.readOnly {
            await self.cache.storeCachedValue(for: command, cachedResponse: response)
        }
        return try .init(fromRESP: response)
    }

    public func run() async throws {
        try await self.connection.subscribe(to: Self.invalidateChannel) { subscription in
            for try await sub in subscription {
                let key = ValkeyKey(rawValue: sub.message)
                await self.cache.invalidate(key: key)
            }
            self.connection.logger.info("Subscription ended")
        }
    }
}

extension ValkeyClient {
    /// Create connection with cache attached and run operation using connection
    ///
    /// - Parameters:
    ///   - logger: Logger
    ///   - operation: Closure handling Valkey connection
    public func withCachedConnection<Value: Sendable>(
        logger: Logger,
        operation: (ValkeyCachedConnection) async throws -> Value
    ) async throws -> Value {
        try await withConnection(logger: logger) { connection in
            // start tracking
            _ = try await connection.clientTracking(status: .on)
            let cachedConnection = ValkeyCachedConnection(connection: connection)

            return try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await cachedConnection.run()
                }
                let value = try await operation(cachedConnection)
                group.cancelAll()
                return value
            }
        }
    }

}
