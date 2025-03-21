import NIOCore

public protocol RESP3TokenRepresentable {
    init?(from: RESP3Token)
}

extension ByteBuffer: RESP3TokenRepresentable {
    public init?(from token: RESP3Token) {
        switch token.value {
        case .simpleString(let buffer), .blobString(let buffer), .verbatimString(let buffer), .bigNumber(let buffer):
            self = buffer
        default:
            return nil
        }
    }
}

extension String: RESP3TokenRepresentable {
    public init?(from token: RESP3Token) {
        guard let buffer = ByteBuffer(from: token) else { return nil }
        self.init(buffer: buffer)
    }
}

extension Int: RESP3TokenRepresentable {
    public init?(from token: RESP3Token) {
        switch token.value {
        case .number(let value):
            self = numericCast(value)
        default:
            return nil
        }
    }
}

extension Double: RESP3TokenRepresentable {
    public init?(from token: RESP3Token) {
        switch token.value {
        case .double(let value):
            self = value
        default:
            return nil
        }
    }
}

extension Bool: RESP3TokenRepresentable {
    public init?(from token: RESP3Token) {
        switch token.value {
        case .boolean(let value):
            self = value
        default:
            return nil
        }
    }
}

extension Array where Element: RESP3TokenRepresentable {
    public init?(from token: RESP3Token) {
        switch token.value {
        case .array(let respArray), .push(let respArray):
            var array: [Element] = []
            for respElement in respArray {
                guard let element = Element(from: respElement) else { return nil }
                array.append(element)
            }
            self = array
        default:
            return nil
        }
    }
}

extension Set where Element: RESP3TokenRepresentable {
    public init?(from token: RESP3Token) {
        switch token.value {
        case .set(let respSet):
            var set: Set<Element> = .init()
            for respElement in respSet {
                guard let element = Element(from: respElement) else { return nil }
                set.insert(element)
            }
            self = set
        default:
            return nil
        }
    }
}

extension Dictionary where Value: RESP3TokenRepresentable, Key: RESP3TokenRepresentable {
    public init?(from token: RESP3Token) {
        switch token.value {
        case .map(let respMap), .attribute(let respMap):
            var array: [(Key, Value)] = []
            for respElement in respMap {
                guard let key = Key(from: respElement.key) else { return nil }
                guard let value = Value(from: respElement.value) else { return nil }
                array.append((key, value))
            }
            self = .init(array) { first, _ in first }
        default:
            return nil
        }
    }
}
