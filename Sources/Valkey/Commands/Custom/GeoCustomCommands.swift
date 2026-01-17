//
// This source file is part of the valkey-swift project
// Copyright (c) 2025-2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore

/// A type that represents geographic coordinates.
@_documentation(visibility: internal)
public struct GeoCoordinates: RESPTokenDecodable, Sendable {
    public let longitude: Double
    public let latitude: Double

    public init(_ token: RESPToken) throws(RESPDecodeError) {
        (self.longitude, self.latitude) = try token.decodeArrayElements()
    }
}

extension GEOPOS {
    public typealias Response = [GeoCoordinates?]
}

extension GEOSEARCH {
    public typealias Response = GeoSearchEntries
}

extension GEORADIUS {
    public typealias Response = GeoSearchEntries
}

extension GEORADIUSRO {
    public typealias Response = GeoSearchEntries
}

@_documentation(visibility: internal)
public struct GeoSearchEntries: RESPTokenDecodable, Sendable {

    private let array: RESPToken.Array

    public init(_ token: RESPToken) throws(RESPDecodeError) {
        switch token.value {
        case .array(let array):
            self.array = array
        default:
            throw RESPDecodeError.tokenMismatch(expected: [.array], token: token)
        }
    }

    /// Number of entries
    public var count: Int { self.array.count }

    /// Decode the GEOSEARCH / GEORADIUS response entries based on the options used in the command.
    ///
    /// - Parameter options: The set of options (withDist, withHash, withCoord) that were used in the GEOSEARCH / GEORADIUS command.
    /// - Returns: An array of decoded ``Entry`` objects.
    /// - Throws: ``RESPDecodeError`` if the response cannot be decoded.
    public func decode(options: Set<Option>) throws -> [Entry] {
        try self.array.map { try Entry.decode($0, options: options) }
    }

    /// Options for GEOSEARCH / GEORADIUS command that affect the response structure.
    public enum Option: String, Sendable, Hashable, CaseIterable {
        case withDist
        case withHash
        case withCoord
    }

    /// A search entry result from a GEOSEARCH / GEORADIUS commands.
    ///
    /// The structure of this entry depends on which options were provided to the GEOSEARCH / GEORADIUS commands.
    /// Attributes are returned in a specific order when present: distance, hash, coordinates.
    public struct Entry: Sendable {

        public let member: String
        public let distance: Double?
        public let hash: Int64?
        public let coordinates: GeoCoordinates?

        /// Create a new Entry.
        ///
        /// - Parameters:
        ///   - member: The member name.
        ///   - distance: Optional distance from center.
        ///   - hash: Optional geohash integer.
        ///   - coordinates: Optional coordinates.
        init(
            member: String,
            distance: Double? = nil,
            hash: Int64? = nil,
            coordinates: GeoCoordinates? = nil
        ) {
            self.member = member
            self.distance = distance
            self.hash = hash
            self.coordinates = coordinates
        }

        /// Decode a GEOSEARCH / GEORADIUS entry token based on the options used in the command.
        ///
        /// - Parameters:
        ///   - token: The RESP token to decode.
        ///   - options: The options that were used in the GEORADIUS command.
        /// - Returns: A decoded ``Entry``.
        /// - Throws: ``RESPDecodeError`` if the token cannot be decoded.
        fileprivate static func decode(_ token: RESPToken, options: Set<GeoSearchEntries.Option> = []) throws -> Entry {
            switch token.value {
            case .array(let array):
                var iterator = array.makeIterator()

                // First element is always the member name
                guard let memberToken = iterator.next() else {
                    throw RESPDecodeError.invalidArraySize(array, expectedSize: 1)
                }
                let member = try String(memberToken)

                var distance: Double? = nil
                var hash: Int64? = nil
                var coordinates: GeoCoordinates? = nil

                // Parse attributes in order: distance, hash, coordinates
                if options.contains(.withDist) {
                    guard let distToken = iterator.next() else {
                        throw RESPDecodeError.invalidArraySize(array, expectedSize: 2)
                    }
                    distance = try Double(distToken)
                }

                if options.contains(.withHash) {
                    guard let hashToken = iterator.next() else {
                        let expectedSize = 2 + (options.contains(.withDist) ? 1 : 0)
                        throw RESPDecodeError.invalidArraySize(array, expectedSize: expectedSize)
                    }
                    hash = try Int64(hashToken)
                }

                if options.contains(.withCoord) {
                    guard let coordToken = iterator.next() else {
                        let expectedSize = 2 + (options.contains(.withDist) ? 1 : 0) + (options.contains(.withHash) ? 1 : 0)
                        throw RESPDecodeError.invalidArraySize(array, expectedSize: expectedSize)
                    }
                    coordinates = try GeoCoordinates(coordToken)
                }

                return Entry(
                    member: member,
                    distance: distance,
                    hash: hash,
                    coordinates: coordinates
                )

            case .bulkString(let buffer):
                // Simple response without any options - just the member name
                return Entry(member: String(buffer: buffer))

            default:
                throw RESPDecodeError.tokenMismatch(expected: [.array, .bulkString], token: token)
            }
        }
    }
}
