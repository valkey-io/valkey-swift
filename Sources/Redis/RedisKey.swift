import NIOCore
import RESP

/// Type representing a RedisKey
public struct RedisKey: RawRepresentable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension RedisKey: RESP3TokenRepresentable {
    public init(from token: RESPToken) throws {
        switch token.value {
        case .simpleString(let buffer), .blobString(let buffer):
            self.rawValue = String(buffer: buffer)
        default:
            throw RedisClientError(.unexpectedType)
        }
    }
}

extension RedisKey: CustomStringConvertible {
    public var description: String { rawValue.description }
}
