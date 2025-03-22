import Foundation
import NIOCore
import RESP3

/// Type that can be rendered into a RESP buffer
public protocol RESPRenderable {
    func writeToRESPBuffer(_ buffer: inout ByteBuffer)
}

public struct RedisPureToken: RESPRenderable {
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

public struct RESPWithToken<Value: RESPRenderable>: RESPRenderable {
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

extension Optional: RESPRenderable where Wrapped: RESPRenderable {
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

extension Array: RESPRenderable where Element: RESPRenderable {
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
        for element in self {
            element.writeToRESPBuffer(&buffer)
        }
    }
}

extension Bool: RESPRenderable {
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
        if self {
            buffer.writeBulkString("TRUE")
        }
    }
}

extension String: RESPRenderable {
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
        buffer.writeBulkString(self)
    }
}

extension Int: RESPRenderable {
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
        buffer.writeBulkString(String(self))
    }
}

extension Double: RESPRenderable {
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
        buffer.writeBulkString(String(self))
    }
}

extension Date: RESPRenderable {
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
        buffer.writeBulkString(String(self.timeIntervalSince1970))
    }
}

extension RedisKey: RESPRenderable {
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
