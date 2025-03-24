import NIOCore
import RESP3

/// Type that can represented by a RESP3Token
public protocol RESP3TokenRepresentable {
    init(from: RESP3Token) throws
}

extension RESP3Token: RESP3TokenRepresentable {
    /// Convert RESP3Token to a value
    /// - Parameter type: Type to convert to
    /// - Throws: RedisClientError.unexpectedType
    /// - Returns: Value
    func converting<Value: RESP3TokenRepresentable>(to type: Value.Type = Value.self) throws -> Value {
        try Value(from: self)
    }

    public init(from token: RESP3Token) throws {
        self = token
    }
}

extension ByteBuffer: RESP3TokenRepresentable {
    public init(from token: RESP3Token) throws {
        switch token.value {
        case .simpleString(let buffer), .blobString(let buffer), .verbatimString(let buffer), .bigNumber(let buffer):
            self = buffer
        default:
            throw RedisClientError(.unexpectedType)
        }
    }
}

extension String: RESP3TokenRepresentable {
    public init(from token: RESP3Token) throws {
        let buffer = try ByteBuffer(from: token)
        self.init(buffer: buffer)
    }
}

extension Int: RESP3TokenRepresentable {
    public init(from token: RESP3Token) throws {
        switch token.value {
        case .number(let value):
            self = numericCast(value)
        default:
            throw RedisClientError(.unexpectedType)
        }
    }
}

extension Double: RESP3TokenRepresentable {
    public init(from token: RESP3Token) throws {
        switch token.value {
        case .double(let value):
            self = value
        default:
            throw RedisClientError(.unexpectedType)
        }
    }
}

extension Bool: RESP3TokenRepresentable {
    public init(from token: RESP3Token) throws {
        switch token.value {
        case .boolean(let value):
            self = value
        default:
            throw RedisClientError(.unexpectedType)
        }
    }
}

extension Optional: RESP3TokenRepresentable where Wrapped: RESP3TokenRepresentable {
    public init(from token: RESP3Token) throws {
        switch token.value {
        case .null:
            self = nil
        default:
            self = try Wrapped(from: token)
        }
    }
}

extension Array: RESP3TokenRepresentable where Element: RESP3TokenRepresentable {
    public init(from token: RESP3Token) throws {
        switch token.value {
        case .array(let respArray), .push(let respArray):
            var array: [Element] = []
            for respElement in respArray {
                let element = try Element(from: respElement)
                array.append(element)
            }
            self = array
        default:
            throw RedisClientError(.unexpectedType)
        }
    }
}

extension Set: RESP3TokenRepresentable where Element: RESP3TokenRepresentable {
    public init(from token: RESP3Token) throws {
        switch token.value {
        case .set(let respSet):
            var set: Set<Element> = .init()
            for respElement in respSet {
                let element = try Element(from: respElement)
                set.insert(element)
            }
            self = set
        default:
            throw RedisClientError(.unexpectedType)
        }
    }
}

extension Dictionary: RESP3TokenRepresentable where Value: RESP3TokenRepresentable, Key: RESP3TokenRepresentable {
    public init(from token: RESP3Token) throws {
        switch token.value {
        case .map(let respMap), .attribute(let respMap):
            var array: [(Key, Value)] = []
            for respElement in respMap {
                let key = try Key(from: respElement.key)
                let value = try Value(from: respElement.value)
                array.append((key, value))
            }
            self = .init(array) { first, _ in first }
        default:
            throw RedisClientError(.unexpectedType)
        }
    }
}
