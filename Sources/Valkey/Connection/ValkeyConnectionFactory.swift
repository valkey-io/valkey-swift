//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import Logging
import NIOCore
import NIOSSL
import Synchronization

@available(valkeySwift 1.0, *)
package final class ValkeyConnectionFactory: Sendable {

    enum Mode: Sendable {
        case `default`
        case custom(@Sendable (ValkeyServerAddress, any EventLoop) async throws -> any Channel)
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
        readOnly: Bool,
        connectionID: Int,
        eventLoop: any EventLoop,
        logger: Logger
    ) async throws -> ValkeyConnection {
        switch self.mode {
        case .default:
            let connectionConfig = try await self.makeConnectionConfiguration(readOnly: readOnly)
            return try await ValkeyConnection.connect(
                address: address,
                connectionID: connectionID,
                configuration: connectionConfig,
                eventLoop: eventLoop,
                logger: logger
            )

        case .custom(let customHandler):
            async let connectionConfigPromise = self.makeConnectionConfiguration(readOnly: readOnly)
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
                    address: address,
                    logger: logger
                )
            }.get()
            try await connection.waitOnActive()
            return connection
        }
    }

    func makeConnectionConfiguration(readOnly: Bool) async throws -> ValkeyConnectionConfiguration {
        let tls: ValkeyConnectionConfiguration.TLS =
            switch self.configuration.tls.base {
            case .disable:
                .disable
            case .enable(_, let clientName):
                try await .enable(self.cache!.getSSLContext(), tlsServerName: clientName)
            }

        let newConfig = ValkeyConnectionConfiguration(
            authentication: self.configuration.authentication.flatMap {
                .init(username: $0.username, password: $0.password)
            },
            commandTimeout: self.configuration.commandTimeout,
            blockingCommandTimeout: self.configuration.blockingCommandTimeout,
            tls: tls,
            clientName: nil,
            readOnly: readOnly,
            databaseNumber: self.configuration.databaseNumber,
            enableClientRedirect: self.configuration.enableClientCapaRedirect
        )

        #if DistributedTracingSupport
        var mConfig = newConfig
        mConfig.tracing = self.configuration.tracing
        return mConfig
        #else
        return newConfig
        #endif
    }
}
