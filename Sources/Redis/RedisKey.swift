import NIOCore
import RESP3

public struct RedisKey: RawRepresentable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension RedisKey: RESP3TokenRepresentable {
    public init?(from token: RESP3Token) {
        switch token.value {
        case .simpleString(let buffer), .blobString(let buffer):
            self.rawValue = String(buffer: buffer)
        default:
            return nil
        }
    }
}

extension RedisKey: CustomStringConvertible {
    public var description: String { rawValue.description }
}
