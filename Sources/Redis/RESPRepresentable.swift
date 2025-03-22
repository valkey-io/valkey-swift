import Foundation
import NIOCore
import RESP3

public protocol RESPRepresentable {
    func writeToRESPBuffer(_ buffer: inout ByteBuffer)
}

public struct RedisPureToken: RESPRepresentable {
    @usableFromInline
    let token: String?
    @inlinable
    init(_ token: String, _ value: Bool) {
        if value {
            self.token = token
        } else {
            self.token = nil
        }
    }
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
        self.token.writeToRESPBuffer(&buffer)
    }
}

public struct RESPWithToken<Value : RESPRepresentable>: RESPRepresentable {
    @usableFromInline
    let value: Value?
    @usableFromInline
    let token: String

    @inlinable
    public init(_ token: String, _ value: Value?) {
        self.value = value
        self.token = token
    }
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
        if let value {
            self.token.writeToRESPBuffer(&buffer)
            value.writeToRESPBuffer(&buffer)
        }
    }
}

extension Optional: RESPRepresentable where Wrapped: RESPRepresentable {
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
        switch self {
        case .some(let wrapped):
            wrapped.writeToRESPBuffer(&buffer)
        case .none:
            break
        }
    }
}

extension Array: RESPRepresentable where Element: RESPRepresentable {
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
        for element in self {
            element.writeToRESPBuffer(&buffer)
        }
    }
}

extension Bool: RESPRepresentable {
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
        if self {
            buffer.writeBulkString("TRUE")
        }
    }
}

extension String: RESPRepresentable {
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
        buffer.writeBulkString(self)
    }
}

extension Int: RESPRepresentable {
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
        buffer.writeBulkString(String(self))
    }
}

extension Double: RESPRepresentable {
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
        buffer.writeBulkString(String(self))
    }
}

extension Date: RESPRepresentable {
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
        buffer.writeBulkString(String(self.timeIntervalSince1970))
    }
}

extension RedisKey: RESPRepresentable {
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
        buffer.writeBulkString(self.rawValue)
    }
}

extension ByteBuffer {
    @usableFromInline
    mutating func writeRESP3TypeIdentifier(_ identifier: RESP3TypeIdentifier) {
        self.writeInteger(identifier.rawValue)
    }

    @usableFromInline
    mutating func writeBulkString(_ string: String) {
        self.writeRESP3TypeIdentifier(.blobString)
        self.writeString(String(string.utf8.count))
        self.writeStaticString("\r\n")
        self.writeString(string)
        self.writeStaticString("\r\n")
    }
}
