//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift project
//
// Copyright (c) 2025 the valkey-swift authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See valkey-swift/CONTRIBUTORS.txt for the list of valkey-swift authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Logging
import Synchronization
import _ValkeyConnectionPool

/// Extend ValkeyConnection so we can use it with the connection pool
@available(valkeySwift 1.0, *)
extension ValkeyConnection: PooledConnection {
    // connection id
    public typealias ID = Int
    // on close
    public nonisolated func onClose(_ closure: @escaping @Sendable ((any Error)?) -> Void) {
        self.channel.closeFuture.whenComplete { _ in closure(nil) }
    }
}

/// Keep alive behavior for Valkey connection
@available(valkeySwift 1.0, *)
struct ValkeyKeepAliveBehavior: ConnectionKeepAliveBehavior {
    let behavior: ValkeyClientConfiguration.KeepAliveBehavior?

    init(_ behavior: ValkeyClientConfiguration.KeepAliveBehavior?) {
        self.behavior = behavior
    }

    var keepAliveFrequency: Duration? {
        self.behavior?.frequency
    }

    func runKeepAlive(for connection: ValkeyConnection) async throws {
        _ = try await connection.ping()
    }
}

/// Connection id generator for Valkey connection pool
@available(valkeySwift 1.0, *)
final class ConnectionIDGenerator: ConnectionIDGeneratorProtocol {
    static let globalGenerator = ConnectionIDGenerator()

    private let atomic: Atomic<Int>

    init() {
        self.atomic = .init(0)
    }

    func next() -> Int {
        self.atomic.wrappingAdd(1, ordering: .relaxed).oldValue
    }
}

/// Valkey client connection pool metrics
@available(valkeySwift 1.0, *)
final class ValkeyClientMetrics: ConnectionPoolObservabilityDelegate {
    typealias ConnectionID = ValkeyConnection.ID

    let logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    func startedConnecting(id: ConnectionID) {
        self.logger.debug(
            "Creating new connection",
            metadata: [
                "valkey_connection_id": "\(id)"
            ]
        )
    }

    /// A connection attempt failed with the given error. After some period of
    /// time ``startedConnecting(id:)`` may be called again.
    func connectFailed(id: ConnectionID, error: Error) {
        self.logger.debug(
            "Connection creation failed",
            metadata: [
                "valkey_connection_id": "\(id)",
                "error": "\(String(reflecting: error))",
            ]
        )
    }

    func connectSucceeded(id: ConnectionID) {
        self.logger.debug(
            "Connection established",
            metadata: [
                "valkey_connection_id": "\(id)"
            ]
        )
    }

    /// The utlization of the connection changed; a stream may have been used, returned or the
    /// maximum number of concurrent streams available on the connection changed.
    func connectionLeased(id: ConnectionID) {
        self.logger.debug(
            "Connection leased",
            metadata: [
                "valkey_connection_id": "\(id)"
            ]
        )
    }

    func connectionReleased(id: ConnectionID) {
        self.logger.debug(
            "Connection released",
            metadata: [
                "valkey_connection_id": "\(id)"
            ]
        )
    }

    func keepAliveTriggered(id: ConnectionID) {
        self.logger.debug(
            "run ping pong",
            metadata: [
                "valkey_connection_id": "\(id)"
            ]
        )
    }

    func keepAliveSucceeded(id: ConnectionID) {}

    func keepAliveFailed(id: ValkeyConnection.ID, error: Error) {}

    /// The remote peer is quiescing the connection: no new streams will be created on it. The
    /// connection will eventually be closed and removed from the pool.
    func connectionClosing(id: ConnectionID) {
        self.logger.debug(
            "Close connection",
            metadata: [
                "valkey_connection_id": "\(id)"
            ]
        )
    }

    /// The connection was closed. The connection may be established again in the future (notified
    /// via ``startedConnecting(id:)``).
    func connectionClosed(id: ConnectionID, error: Error?) {
        self.logger.debug(
            "Connection closed",
            metadata: [
                "valkey_connection_id": "\(id)"
            ]
        )
    }

    func requestQueueDepthChanged(_ newDepth: Int) {

    }

    func connectSucceeded(id: ValkeyConnection.ID, streamCapacity: UInt16) {

    }

    func connectionUtilizationChanged(id: ValkeyConnection.ID, streamsUsed: UInt16, streamCapacity: UInt16) {

    }
}
