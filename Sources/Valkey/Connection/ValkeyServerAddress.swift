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

import NIOCore

/// A Valkey server address to connect to.
public struct ValkeyServerAddress: Sendable, Equatable {
    enum _Internal: Equatable {
        case hostname(_ host: String, port: Int)
        case unixDomainSocket(path: String)
        case socketAddress(SocketAddress)
    }

    let value: _Internal
    init(_ value: _Internal) {
        self.value = value
    }

    // raw socket address
    public static func socketAddress(_ address: SocketAddress) -> Self { .init(.socketAddress(address)) }
    // Address defined by host and port. If using raw IP address for host name it is preferable to use ``ValkeyServerAddress/socketAddress(_:)``.
    public static func hostname(_ host: String, port: Int = 6379) -> Self { .init(.hostname(host, port: port)) }
    // Address defined by unxi domain socket
    public static func unixDomainSocket(path: String) -> Self { .init(.unixDomainSocket(path: path)) }
}
