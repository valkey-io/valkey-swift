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

/// A type that represents geographic coordinates.
public struct GeoCoordinates: RESPTokenDecodable, Sendable {
    public let longitude: Double
    public let latitude: Double

    public init(fromRESP token: RESPToken) throws {
        (self.longitude, self.latitude) = try token.decodeArrayElements()
    }
}

/// A type that represents a coordinate value for a geographic location.
public typealias GEODISTResponse = Double?
extension GEODIST {
    public typealias Response = GEODISTResponse
}

extension GEOPOS {
    public typealias Response = [GeoCoordinates?]
}

extension GEOSEARCH {
    /// Search entry for GEOSEARCH command.
    ///
    /// Given the response for GEOSEARCH is dependent on which `with` attributes flags
    /// are set in the command it is not possible to know the structure of the response
    /// beforehand. The order the attributes are in the array, if relevant with flag is
    /// set, is distance, hash and coordinates. These can be decoded respectively as a
    /// `Double`, `String` and ``GeoCoordinate``
    public struct SearchEntry: RESPTokenDecodable, Sendable {
        public let member: String
        public let attributes: [RESPToken]

        public init(fromRESP token: RESPToken) throws {
            switch token.value {
            case .array(let array):
                var arrayIterator = array.makeIterator()
                guard let member = arrayIterator.next() else {
                    throw RESPParsingError(code: .unexpectedType, buffer: token.base)
                }
                self.member = try String(fromRESP: member)
                self.attributes = array.dropFirst().map { $0 }

            case .bulkString(let buffer):
                self.member = String(buffer: buffer)
                self.attributes = []

            default:
                throw RESPParsingError(code: .unexpectedType, buffer: token.base)
            }
        }
    }
    public typealias Response = [SearchEntry]
}
