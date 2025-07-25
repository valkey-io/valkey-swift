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
import NIOPosix
import NIOSSL
import NIOTransportServices
import Synchronization
import _ValkeyConnectionPool

#if ServiceLifecycleSupport
import ServiceLifecycle
#endif

/// Valkey client
///
/// Connect to Valkey server.
///
/// Supports TLS via both NIOSSL and Network framework.
@available(valkeySwift 1.0, *)
public final class ValkeyClient: Sendable {
    @usableFromInline
    typealias Pool = ConnectionPool<
        ValkeyConnection,
        ValkeyConnection.ID,
        ConnectionIDGenerator,
        ValkeyConnectionRequest<RESPToken>,
        Int,
        ValkeyKeepAliveBehavior,
        ValkeyClientMetrics,
        ContinuousClock
    >
    /// Server address
    let serverAddress: ValkeyServerAddress
    /// Connection pool
    @usableFromInline
    let connectionPool: Pool

    let connectionFactory: ValkeyConnectionFactory
    /// configuration
    var configuration: ValkeyClientConfiguration { self.connectionFactory.configuration }
    /// EventLoopGroup to use
    let eventLoopGroup: any EventLoopGroup
    /// Logger
    let logger: Logger
    /// running atomic
    let runningAtomic: Atomic<Bool>

    @usableFromInline
    let requestIDGenerator = IDGenerator()

    /// Initialize Valkey client
    ///
    /// - Parameters:
    ///   - address: Valkey database address
    ///   - configuration: Valkey client configuration
    ///   - eventLoopGroup: EventLoopGroup to run WebSocket client on
    ///   - logger: Logger
    public convenience init(
        _ address: ValkeyServerAddress,
        configuration: ValkeyClientConfiguration = .init(),
        eventLoopGroup: any EventLoopGroup = MultiThreadedEventLoopGroup.singleton,
        logger: Logger
    ) {
        self.init(
            address,
            connectionIDGenerator: ConnectionIDGenerator(),
            connectionFactory: ValkeyConnectionFactory(configuration: configuration),
            eventLoopGroup: eventLoopGroup,
            logger: logger
        )
    }

    package init(
        _ address: ValkeyServerAddress,
        connectionIDGenerator: ConnectionIDGenerator,
        connectionFactory: ValkeyConnectionFactory,
        eventLoopGroup: EventLoopGroup,
        logger: Logger
    ) {
        self.serverAddress = address

        var poolConfiguration = _ValkeyConnectionPool.ConnectionPoolConfiguration()
        poolConfiguration.minimumConnectionCount = connectionFactory.configuration.connectionPool.minimumConnectionCount
        poolConfiguration.maximumConnectionSoftLimit = connectionFactory.configuration.connectionPool.maximumConnectionCount
        poolConfiguration.maximumConnectionHardLimit = connectionFactory.configuration.connectionPool.maximumConnectionCount

        self.connectionPool = .init(
            configuration: poolConfiguration,
            idGenerator: connectionIDGenerator,
            requestType: ValkeyConnectionRequest.self,
            keepAliveBehavior: .init(connectionFactory.configuration.keepAliveBehavior),
            observabilityDelegate: ValkeyClientMetrics(logger: logger),
            clock: .continuous
        ) { (connectionID, pool) in
            var logger = logger
            logger[metadataKey: "valkey_connection_id"] = "\(connectionID)"

            let connection = try await connectionFactory.makeConnection(
                address: address,
                connectionID: connectionID,
                eventLoop: eventLoopGroup.any(),
                logger: logger
            )

            return ConnectionAndMetadata(connection: connection, maximalStreamsOnConnection: 1)
        }
        self.connectionFactory = connectionFactory
        self.eventLoopGroup = eventLoopGroup
        self.logger = logger
        self.runningAtomic = .init(false)
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyClient {
    /// Run ValkeyClient connection pool
    public func run() async {
        let atomicOp = self.runningAtomic.compareExchange(expected: false, desired: true, ordering: .relaxed)
        precondition(!atomicOp.original, "ValkeyClient.run() should just be called once!")
        #if ServiceLifecycleSupport
        await cancelWhenGracefulShutdown {
            await self.connectionPool.run()
        }
        #else
        await self.connectionPool.run()
        #endif
    }

    func triggerForceShutdown() {
        self.connectionPool.triggerForceShutdown()
    }

    /// Get connection from connection pool and run operation using connection
    ///
    /// - Parameters:
    ///   - isolation: Actor isolation
    ///   - operation: Closure handling Valkey connection
    /// - Returns: Value returned by closure
    public func withConnection<Value>(
        isolation: isolated (any Actor)? = #isolation,
        operation: (ValkeyConnection) async throws -> sending Value
    ) async throws -> Value {
        fatalError()
//        let connection = try await self.leaseConnection()
//
//        defer { self.connectionPool.releaseConnection(connection) }
//
//        return try await operation(connection)
    }

//    private func leaseConnection() async throws -> ValkeyConnection {
//        if !self.runningAtomic.load(ordering: .relaxed) {
//            self.logger.warning("Trying to lease connection from `ValkeyClient`, but `ValkeyClient.run()` hasn't been called yet.")
//        }
//        return try await self.connectionPool.leaseConnection()
//    }

}

/// Extend ValkeyClient so we can call commands directly from it
@available(valkeySwift 1.0, *)
extension ValkeyClient: ValkeyConnectionProtocol {
    /// Send command to Valkey connection from connection pool
    /// - Parameter command: Valkey command
    /// - Returns: Response from Valkey command
    @inlinable
    public func send<Command: ValkeyCommand>(command: Command) async throws -> Command.Response {
        let token = try await self._send(command)
        return try Command.Response(fromRESP: token)
    }

    @inlinable
    func _send<Command: ValkeyCommand>(_ command: Command) async throws -> RESPToken {
        let id = self.requestIDGenerator.next()
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<RESPToken, any Error>) in
            let request = ValkeyConnectionRequest(
                id: id,
                pool: self.connectionPool,
                continuation: continuation
            ) { connection, request in
                connection._write(command: command, request: request)
            }

            self.connectionPool.leaseConnection(request)
        }
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyClient {
    /// Pipeline a series of commands to Valkey connection
    ///
    /// This function will only return once it has the results of all the commands sent
    /// - Parameter commands: Parameter pack of ValkeyCommands
    /// - Returns: Parameter pack holding the results of all the commands
    @inlinable
    public func pipeline<each Command: ValkeyCommand>(
        _ commands: repeat each Command
    ) async -> sending (repeat Result<(each Command).Response, Error>) {
        do {
            return try await self.withConnection { connection in
                await connection.pipeline(repeat (each commands))
            }
        } catch {
            return (repeat Result<(each Command).Response, Error>.failure(error))
        }
    }
}

#if ServiceLifecycleSupport
@available(valkeySwift 1.0, *)
extension ValkeyClient: Service {}
#endif  // ServiceLifecycle

@available(valkeySwift 1.0, *)
@usableFromInline
enum RequestState: AtomicRepresentable, Sendable {
    @usableFromInline
    typealias AtomicRepresentation = Unmanaged<ValkeyConnection>?

    case waitingForConnection
    case onConnection(ValkeyConnection)

    @usableFromInline
    static func decodeAtomicRepresentation(_ storage: consuming Unmanaged<ValkeyConnection>?) -> RequestState {
        if let storage {
            return .onConnection(storage.takeRetainedValue())
        } else {
            return .waitingForConnection
        }
    }

    @usableFromInline
    static func encodeAtomicRepresentation(_ value: consuming RequestState) -> Unmanaged<ValkeyConnectionRequest.Connection>? {
        switch value {
        case .onConnection(let connection):
            return Unmanaged.passRetained(connection)
        case .waitingForConnection:
            return nil
        }
    }
}

@available(valkeySwift 1.0, *)
@usableFromInline
final class ValkeyConnectionRequest<T: Sendable>: Sendable, ConnectionRequestProtocol {
    @usableFromInline
    typealias Connection = ValkeyConnection

    @usableFromInline
    let id: Int
    @usableFromInline
    let pool: ValkeyClient.Pool
    @usableFromInline
    let continuation: CheckedContinuation<T, any Error>
    @usableFromInline
    let lock: Mutex<RequestState>
    @usableFromInline
    let onConnection: @Sendable (Connection, ValkeyConnectionRequest<T>) -> ()

    @inlinable
    init(
        id: Int,
        pool: ValkeyClient.Pool,
        continuation: CheckedContinuation<RESPToken, any Error>,
        _ onConnection: @escaping @Sendable (Connection, ValkeyConnectionRequest<T>) -> ()
    ) where T == RESPToken {
        self.id = id
        self.pool = pool
        self.continuation = continuation
        self.onConnection = onConnection
        self.lock = .init(.waitingForConnection)
    }

    @inlinable
    func complete(with result: Result<Connection, ConnectionPoolError>) {
        switch result {
        case .success(let connection):
            self.lock.withLock { state in
                state = .onConnection(connection)
            }
            self.onConnection(connection, self)
        case .failure(let error):
            continuation.resume(throwing: error)

        }
    }

    @inlinable
    func succeed(_ t: T) {
        self.continuation.resume(returning: t)
        let connection = self.lock.withLock { state -> ValkeyConnection? in
            switch state {
            case .onConnection(let connection):
                return connection
            case .waitingForConnection:
                return nil
            }
        }
        if let connection {
            self.pool.releaseConnection(connection, streams: 1)
        }
    }

    @inlinable
    func fail(_ error: any Error) {
        self.continuation.resume(throwing: error)
    }

    func cancel() {
        self.lock.withLock { state in
            switch state {
            case .onConnection(let connection):
                connection.cancel(requestID: self.id)

            case .waitingForConnection:
                self.pool.cancelLeaseConnection(self.id)
            }
        }
    }

}
