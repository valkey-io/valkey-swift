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

extension CLIENT.LIST {
    /// Field name in a CLIENT LIST response.
    ///
    /// Represents a field name from the CLIENT LIST output. Uses raw representable pattern
    /// to handle both known and unknown fields gracefully, allowing version-safe parsing.
    public struct Field: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public var description: String { self.rawValue }

        /// The unique client ID
        public static var id: Field { .init(rawValue: "id") }
        /// The address and port of the client (format: ip:port)
        public static var addr: Field { .init(rawValue: "addr") }
        /// The address and port of the local address client connected to (bind address)
        public static var laddr: Field { .init(rawValue: "laddr") }
        /// The file descriptor corresponding to the socket
        public static var fd: Field { .init(rawValue: "fd") }
        /// The connection name
        public static var name: Field { .init(rawValue: "name") }
        /// The total duration of the connection in seconds
        public static var age: Field { .init(rawValue: "age") }
        /// The idle time of the connection in seconds
        public static var idle: Field { .init(rawValue: "idle") }
        /// The client flags (see documentation for flag meanings)
        public static var flags: Field { .init(rawValue: "flags") }
        /// The current database ID
        public static var db: Field { .init(rawValue: "db") }
        /// The number of channel subscriptions
        public static var sub: Field { .init(rawValue: "sub") }
        /// The number of pattern matching subscriptions
        public static var psub: Field { .init(rawValue: "psub") }
        /// The number of shard channel subscriptions
        public static var ssub: Field { .init(rawValue: "ssub") }
        /// The number of commands in a MULTI/EXEC context
        public static var multi: Field { .init(rawValue: "multi") }
        /// The query buffer length (0 means no query pending)
        public static var qbuf: Field { .init(rawValue: "qbuf") }
        /// The free space of the query buffer (0 means the buffer is full)
        public static var qbufFree: Field { .init(rawValue: "qbuf-free") }
        /// The incomplete arguments for the next command (already extracted from query buffer)
        public static var argvMem: Field { .init(rawValue: "argv-mem") }
        /// The memory used by buffered multi commands
        public static var multiMem: Field { .init(rawValue: "multi-mem") }
        /// The output buffer length
        public static var obl: Field { .init(rawValue: "obl") }
        /// The output list length (replies that are queued)
        public static var oll: Field { .init(rawValue: "oll") }
        /// The output buffer memory usage
        public static var omem: Field { .init(rawValue: "omem") }
        /// The total memory consumed by this client
        public static var totMem: Field { .init(rawValue: "tot-mem") }
        /// The file descriptor events (r/w)
        public static var events: Field { .init(rawValue: "events") }
        /// The last command played
        public static var cmd: Field { .init(rawValue: "cmd") }
        /// The authenticated username of the client
        public static var user: Field { .init(rawValue: "user") }
        /// The client ID of current client tracking redirection
        public static var redir: Field { .init(rawValue: "redir") }
        /// The RESP protocol version used by the client
        public static var resp: Field { .init(rawValue: "resp") }
        /// The client library name
        public static var libName: Field { .init(rawValue: "lib-name") }
        /// The client library version
        public static var libVer: Field { .init(rawValue: "lib-ver") }
        /// The read buffer size
        public static var rbs: Field { .init(rawValue: "rbs") }
        /// The read buffer peak
        public static var rbp: Field { .init(rawValue: "rbp") }
    }

    /// Response type for CLIENT LIST command.
    ///
    /// Returns an array of client information dictionaries, where each dictionary
    /// maps field names to their RESP token values. This approach gracefully handles
    /// new fields that may be added in future Valkey versions.
    public struct Response: RESPTokenDecodable, Sendable {
        /// Array of client information dictionaries
        public let clients: [[Field: RESPToken]]

        /// Creates a CLIENT LIST response from the response token you provide.
        ///
        /// Parses the bulk string response from CLIENT LIST, which contains one line
        /// per client connection with space-separated key=value pairs.
        ///
        /// - Parameter token: The response token containing CLIENT LIST data.
        public init(_ token: RESPToken) throws(RESPDecodeError) {
            switch token.value {
                 case .verbatimString, .bulkString:
                    var string = try String(token)

                print (string)

                if let colonIndex = string.firstIndex(of: ":"), colonIndex.utf16Offset(in: string) < 10 {
                    // Check if this looks like an encoding prefix (short prefix before colon)
                    let prefix = string[..<colonIndex]
                    if prefix.count <= 5 && prefix.allSatisfy({ $0.isLetter }) {
                        string = String(string[string.index(after: colonIndex)...])
                    }
                }

                print (string)

                let lines = string.split(separator: "\n").map(String.init).filter { !$0.isEmpty }

                var clients: [[Field: RESPToken]] = []

                for line in lines {
                    var client: [Field: RESPToken] = [:]

                    // Split by spaces and parse key=value pairs
                    let components = line.split(separator: " ").map(String.init)
                    for component in components {
                        let parts = component.split(separator: "=", maxSplits: 1).map(String.init)
                        var buffer = ByteBuffer()
                        if parts.count == 2 {
                            let field = Field(rawValue: parts[0])
                            // Create a proper RESP bulk string token
                            let value = parts[1]
                            buffer.writeString("$\(value.utf8.count)\r\n\(value)\r\n")
                            client[field] = RESPToken(validated: buffer)
                        } else if parts.count == 1 && component.contains("=") {
                            // Handle edge case where value is empty (e.g., "name=")
                            let field = Field(rawValue: parts[0])
                            buffer.writeString("$0\r\n\r\n")
                            client[field] = RESPToken(validated: buffer)
                        }
                    }

                    clients.append(client)
                }

                self.clients = clients
            default:
                throw RESPDecodeError.tokenMismatch(expected: [.bulkString, .verbatimString, .array], token: token)
            }
        }
    }
}
