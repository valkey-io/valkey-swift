import NIOCore
import RESP3

public struct RESPCommand: Sendable {
    @usableFromInline
    let buffer: ByteBuffer

    @inlinable
    public init<each Arg: RESPRepresentable>(_ command: repeat each Arg) {
        var count = 0
        for _ in repeat each command {
            count += 1
        }
        var buffer = ByteBuffer()
        buffer.writeRESP3TypeIdentifier(.array)
        buffer.writeString(String(count))
        buffer.writeStaticString("\r\n")
        for arg in repeat each command {
            arg.writeToRESPBuffer(&buffer)
        }
        self.buffer = buffer
    }
}

