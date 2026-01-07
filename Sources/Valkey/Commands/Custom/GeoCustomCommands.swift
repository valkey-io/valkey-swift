//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
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

    public init(_ token: RESPToken) throws {
        (self.longitude, self.latitude) = try token.decodeArrayElements()
    }
}

/// A type that represents a coordinate value for a geographic location.
@_documentation(visibility: internal)
public typealias GEODISTResponse = Double?
extension GEODIST {
    public typealias Response = GEODISTResponse
}

extension GEOPOS {
    public typealias Response = [GeoCoordinates?]
}

extension GEORADIUS {
    public typealias Response = GeoRadiusEntries
}

extension GEORADIUSBYMEMBER {
    public typealias Response = GeoRadiusEntries
}

extension GEORADIUSBYMEMBERRO {
    public typealias Response = GeoRadiusEntries
}

extension GEORADIUSRO {
    public typealias Response = GeoRadiusEntries
}

extension GEOSEARCH {
    /// Search entry for GEOSEARCH command.
    ///
    /// Given the response for GEOSEARCH is dependent on which `with` attributes flags
    /// are set in the command it is not possible to know the structure of the response
    /// beforehand. The order the attributes are in the array, if relevant with flag is
    /// set, is distance, hash and coordinates. These can be decoded respectively as a
    /// `Double`, `String` and ``GeoCoordinates``
    public struct SearchEntry: RESPTokenDecodable, Sendable {
        public let member: String
        public let attributes: [RESPToken]

        public init(_ token: RESPToken) throws {
            switch token.value {
            case .array(let array):
                var arrayIterator = array.makeIterator()
                guard let member = arrayIterator.next() else {
                    throw RESPDecodeError.invalidArraySize(array, expectedSize: 1)
                }
                self.member = try String(member)
                self.attributes = array.dropFirst().map { $0 }

            case .bulkString(let buffer):
                self.member = String(buffer: buffer)
                self.attributes = []

            default:
                throw RESPDecodeError.tokenMismatch(expected: [.array, .bulkString], token: token)
            }
        }
    }
    public typealias Response = [SearchEntry]
}


public struct GeoRadiusEntries: RESPTokenDecodable, Sendable {

    private let token: RESPToken

    public init(_ token: RESPToken) throws {
        self.token = token
    }

    /// Decode the GEORADIUS response entries based on the options used in the command.
    ///
    /// - Parameter options: The set of options (WITHDIST, WITHHASH, WITHCOORD) that were used in the GEORADIUS command.
    /// - Returns: An array of decoded ``GeoRadiusEntry`` objects.
    /// - Throws: ``RESPDecodeError`` if the response cannot be decoded.
    public func get(options: Set<Option>) throws -> [GeoRadiusEntry] {
        switch token.value {
        case .array(let array):
            return try array.map { try GeoRadiusEntry.decode($0, options: options) }
        default:
            throw RESPDecodeError.tokenMismatch(expected: [.array], token: token)
        }
    }

    /// Options for GEORADIUS command that affect the response structure.
    public enum Option: String, Sendable, Hashable, CaseIterable {
        case WITHDIST
        case WITHHASH
        case WITHCOORD
    }

}

/// A search entry result from a GEORADIUS command.
///
/// The structure of this entry depends on which options were provided to the GEORADIUS command.
/// Attributes are returned in a specific order when present: distance, hash, coordinates.
public struct GeoRadiusEntry: Sendable {

    /// The member name from the sorted set.
    public let member: String

    /// The distance from the center (present if WITHDIST option was used).
    public let distance: Double?

    /// The geohash integer (present if WITHHASH option was used).
    public let hash: Int64?

    /// The coordinates as [longitude, latitude] (present if WITHCOORD option was used).
    public let coordinates: GeoCoordinates?

    /// Create a new GeoRadiusEntry.
    ///
    /// - Parameters:
    ///   - member: The member name.
    ///   - distance: Optional distance from center.
    ///   - hash: Optional geohash integer.
    ///   - coordinates: Optional coordinates.
    public init(
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

    /// Decode a GEORADIUS entry token based on the options used in the command.
    ///
    /// - Parameters:
    ///   - token: The RESP token to decode.
    ///   - options: The options that were used in the GEORADIUS command.
    /// - Returns: A decoded ``GeoRadiusEntry``.
    /// - Throws: ``RESPDecodeError`` if the token cannot be decoded.
    fileprivate static func decode(_ token: RESPToken, options: Set<GeoRadiusEntries.Option> = []) throws -> GeoRadiusEntry {
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
            if options.contains(.WITHDIST) {
                guard let distToken = iterator.next() else {
                    throw RESPDecodeError.invalidArraySize(array, expectedSize: 2)
                }
                distance = try Double(distToken)
            }

            if options.contains(.WITHHASH) {
                guard let hashToken = iterator.next() else {
                    let expectedSize = 2 + (options.contains(.WITHDIST) ? 1 : 0)
                    throw RESPDecodeError.invalidArraySize(array, expectedSize: expectedSize)
                }
                hash = try Int64(hashToken)
            }

            if options.contains(.WITHCOORD) {
                guard let coordToken = iterator.next() else {
                    let expectedSize = 2 + (options.contains(.WITHDIST) ? 1 : 0) + (options.contains(.WITHHASH) ? 1 : 0)
                    throw RESPDecodeError.invalidArraySize(array, expectedSize: expectedSize)
                }
                coordinates = try GeoCoordinates(coordToken)
            }

            // Validate that all elements in the array have been consumed
            if iterator.next() != nil {
                let expectedSize = 1 + (options.contains(.WITHDIST) ? 1 : 0) + (options.contains(.WITHHASH) ? 1 : 0) + (options.contains(.WITHCOORD) ? 1 : 0)
                throw RESPDecodeError.invalidArraySize(array, expectedSize: expectedSize)
            }

            return GeoRadiusEntry(
                member: member,
                distance: distance,
                hash: hash,
                coordinates: coordinates
            )

        case .bulkString(let buffer):
            // Simple response without any options - just the member name
            return GeoRadiusEntry(member: String(buffer: buffer))

        default:
            throw RESPDecodeError.tokenMismatch(expected: [.array, .bulkString], token: token)
        }
    }

}
