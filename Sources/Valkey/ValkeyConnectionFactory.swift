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

import Logging
import NIOCore
import NIOSSL
import Synchronization

@available(valkeySwift 1.0, *)
package final class ValkeyConnectionFactory: Sendable {

    enum Mode: Sendable {
        case `default`
        case custom(@Sendable (ValkeyServerAddress, any EventLoop) async throws -> Channel)
    }

    let mode: Mode
    let configuration: ValkeyClientConfiguration
    let cache: SSLContextCache?

    package init(configuration: ValkeyClientConfiguration) {
        self.configuration = configuration
        self.mode = .default
        switch configuration.tls.base {
        case .enable(let tlsConfiguration, _):
            self.cache = SSLContextCache(tlsConfiguration: tlsConfiguration)
        case .disable:
            self.cache = nil
        }
    }

    package init(
        configuration: ValkeyClientConfiguration,
        customHandler: (@Sendable (ValkeyServerAddress, any EventLoop) async throws -> any Channel)?
    ) {
        self.configuration = configuration
        if let customHandler {
            self.mode = .custom(customHandler)
        } else {
            self.mode = .default
        }
        switch configuration.tls.base {
        case .enable(let tlsConfiguration, _):
            self.cache = SSLContextCache(tlsConfiguration: tlsConfiguration)
        case .disable:
            self.cache = nil
        }
    }

    package func makeConnection(
        address: ValkeyServerAddress,
        connectionID: Int,
        eventLoop: any EventLoop,
        logger: Logger
    ) async throws -> ValkeyConnection {
        switch self.mode {
        case .default:
            let connectionConfig = try await self.makeConnectionConfiguration()
            return try await ValkeyConnection.connect(
                address: address,
                connectionID: connectionID,
                configuration: connectionConfig,
                eventLoop: eventLoop,
                logger: logger
            )

        case .custom(let customHandler):
            async let connectionConfigPromise = self.makeConnectionConfiguration()
            let channel = try await customHandler(address, eventLoop)
            let connectionConfig = try await connectionConfigPromise

            let connection = try await eventLoop.submit {
                let channelHandler = try ValkeyConnection._setupChannel(
                    channel,
                    configuration: connectionConfig,
                    logger: logger
                )
                return ValkeyConnection(
                    channel: channel,
                    connectionID: connectionID,
                    channelHandler: channelHandler,
                    configuration: connectionConfig,
                    logger: logger
                )
            }.get()
            try await connection.initialHandshake()
            return connection
        }
    }

    func makeConnectionConfiguration() async throws -> ValkeyConnectionConfiguration {
        let tls: ValkeyConnectionConfiguration.TLS =
            switch self.configuration.tls.base {
            case .disable:
                .disable
            case .enable(_, let clientName):
                try await .enable(self.cache!.getSSLContext(), tlsServerName: clientName)
            }

        return ValkeyConnectionConfiguration(
            authentication: self.configuration.authentication.flatMap {
                .init(username: $0.username, password: $0.password)
            },
            commandTimeout: self.configuration.commandTimeout,
            blockingCommandTimeout: self.configuration.blockingCommandTimeout,
            tls: tls,
            clientName: nil
        )
    }
}
