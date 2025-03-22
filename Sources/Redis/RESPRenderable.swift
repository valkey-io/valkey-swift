import Foundation
import NIOCore
import RESP3

/// Type that can be rendered into a RESP buffer
public protocol RESPRenderable {
    func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int
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
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
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
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
        if let value {
            let writerIndex = buffer.writerIndex
            _ = self.token.writeToRESPBuffer(&buffer)
            let count = value.writeToRESPBuffer(&buffer)
            if count == 0 {
                buffer.moveWriterIndex(to: writerIndex)
                return 0
            }
            return count + 1
        } else {
            return 0
        }
    }
}

extension Optional: RESPRenderable where Wrapped: RESPRenderable {
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
        switch self {
        case .some(let wrapped):
            return wrapped.writeToRESPBuffer(&buffer)
        case .none:
            return 0
        }
    }
}

extension Array: RESPRenderable where Element: RESPRenderable {
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
        var count = 0
        for element in self {
            count += element.writeToRESPBuffer(&buffer)
        }
        return count
    }
}

extension String: RESPRenderable {
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
        buffer.writeBulkString(self)
        return 1
    }
}

extension Int: RESPRenderable {
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
        buffer.writeBulkString(String(self))
        return 1
    }
}

extension Double: RESPRenderable {
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
        buffer.writeBulkString(String(self))
        return 1
    }
}

extension Date: RESPRenderable {
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
        buffer.writeBulkString(String(self.timeIntervalSince1970))
        return 1
    }
}

extension RedisKey: RESPRenderable {
    @inlinable
    public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
        buffer.writeBulkString(self.rawValue)
        return 1
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
