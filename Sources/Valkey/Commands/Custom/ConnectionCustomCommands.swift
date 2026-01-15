//
// This source file is part of the valkey-swift project
// Copyright (c) 2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore

extension CLIENT.TRACKINGINFO {
    public struct Response: RESPTokenDecodable, Sendable {
        public struct Flag: Hashable, RawRepresentable, RESPTokenDecodable, CustomStringConvertible, Sendable {
            public let rawValue: String

            public init(rawValue: String) {
                self.rawValue = rawValue
            }

            public init(_ token: RESPToken) throws(RESPDecodeError) {
                let string = try String(token)
                self = .init(rawValue: string)
            }

            public var description: String { self.rawValue }

            /// The connection isn't using server assisted client side caching.
            public static var off: Flag { .init(rawValue: "off") }
            /// Server assisted client side caching is enabled for the connection.
            public static var on: Flag { .init(rawValue: "on") }
            /// The client uses broadcasting mode.
            public static var broadcast: Flag { .init(rawValue: "bcast") }
            /// The client does not cache keys by default.
            public static var optIn: Flag { .init(rawValue: "optin") }
            /// The client caches keys by default.
            public static var optOut: Flag { .init(rawValue: "optout") }
            /// The next command will cache keys (exists only together with `.optIn`).
            public static var cachingYes: Flag { .init(rawValue: "caching-yes") }
            /// The next command won't cache keys (exists only together with `.optOut``).
            public static var cachingNo: Flag { .init(rawValue: "caching-no") }
            /// The client isn't notified about keys modified by itself.
            public static var noLoop: Flag { .init(rawValue: "noloop") }
            /// The client ID used for redirection isn't valid anymore.
            public static var brokenRedirect: Flag { .init(rawValue: "broken-redirect") }
        }

        public let flags: Set<Flag>
        public let redirect: Int
        public let prefixes: [String]

        public init(_ token: RESPToken) throws(RESPDecodeError) {
            (self.flags, self.redirect, self.prefixes) = try token.decodeMapValues("flags", "redirect", "prefixes")
        }
    }

}
