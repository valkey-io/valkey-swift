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
        name: String? = nil,
        logger: Logger,
        operation: (ValkeyConnection) async throws -> Value
    ) async throws -> Value {
        let valkeyConnection = try await ValkeyConnection.connect(
            address: self.serverAddress,
            name: name,
            configuration: self.configuration,
            eventLoop: self.eventLoopGroup.any(),
            logger: logger
        )
        let value: Value
        do {
            value = try await operation(valkeyConnection)
        } catch {
            valkeyConnection.close()
            try? await valkeyConnection.channel.closeFuture.get()
            throw error
        }
        valkeyConnection.close()
        try await valkeyConnection.channel.closeFuture.get()
        return value
    }
}
