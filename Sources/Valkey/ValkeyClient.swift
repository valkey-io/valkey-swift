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

import Logging
import NIOCore
import NIOPosix
import NIOSSL
import NIOTransportServices

/// Valkey client
///
/// Connect to Valkey server.
///
/// Supports TLS via both NIOSSL and Network framework.
public struct ValkeyClient {
    /// Server address
    let serverAddress: ServerAddress
    /// configuration
    let configuration: ValkeyClientConfiguration
    /// EventLoopGroup to use
    let eventLoopGroup: EventLoopGroup
    /// Logger
    let logger: Logger

    /// Initialize Valkey client
    ///
    /// - Parametes:
    ///   - address: Valkey database address
    ///   - configuration: Valkey client configuration
    ///   - tlsConfiguration: Valkey TLS connection configuration
    ///   - eventLoopGroup: EventLoopGroup to run WebSocket client on
    ///   - logger: Logger
    public init(
        _ address: ServerAddress,
        configuration: ValkeyClientConfiguration = .init(),
        eventLoopGroup: EventLoopGroup = MultiThreadedEventLoopGroup.singleton,
        logger: Logger
    ) {
        self.serverAddress = address
        self.configuration = configuration
        self.eventLoopGroup = eventLoopGroup
        self.logger = logger
    }
}

extension ValkeyClient {
    /// Create connection and run operation using connection
    ///
    /// - Parameters:
    ///   - logger: Logger
    ///   - operation: Closure handling Valkey connection
    public func withConnection<Value: Sendable>(
        logger: Logger,
        operation: @escaping @Sendable (ValkeyConnection) async throws -> Value
    ) async throws -> Value {
        let valkeyConnection = ValkeyConnection(
            address: self.serverAddress,
            configuration: self.configuration,
            eventLoopGroup: self.eventLoopGroup,
            logger: logger
        )
        return try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await valkeyConnection.run()
            }
            let value: Value = try await operation(valkeyConnection)
            group.cancelAll()
            return value
        }
    }
}
