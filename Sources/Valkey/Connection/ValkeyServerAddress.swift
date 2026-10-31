//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore

/// A Valkey server address to connect to.
public struct ValkeyServerAddress: Sendable, Equatable, Hashable {
    enum _Internal: Equatable, Hashable {
        case hostname(_ host: String, port: Int)
        case unixDomainSocket(path: String)
        case sentinel(name: String)
    }

    let value: _Internal
    init(_ value: _Internal) {
        self.value = value
    }

    // Address define by host and port
    public static func hostname(_ host: String, port: Int = 6379) -> Self { .init(.hostname(host, port: port)) }
    // Address defined by unix domain socket
    public static func unixDomainSocket(path: String) -> Self { .init(.unixDomainSocket(path: path)) }
    // Address defined by sentinel primary name
    package static func sentinel(name: String) -> Self { .init(.sentinel(name: name)) }
}

extension ValkeyServerAddress: CustomStringConvertible {
    public var description: String {
        switch self.value {
        case .hostname(let host, let port): "\(host):\(port)"
        case .unixDomainSocket(let path): path
        case .sentinel(let name): name
        }
    }
}
