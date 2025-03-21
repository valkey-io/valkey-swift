import NIOCore
import RESP3

public struct RESP3Command: Sendable {
    let command: String
    let arguments: [String]

    public init(_ command: String, arguments: [String]) {
        self.command = command
        self.arguments = arguments
    }
}

extension ByteBuffer {
    mutating func writeRESP3TypeIdentifier(_ identifier: RESP3TypeIdentifier) {
        self.writeInteger(identifier.rawValue)
    }
    mutating func writeRESP3Command(_ command: RESP3Command) {
        self.writeRESP3TypeIdentifier(.array)
        self.writeString(String(command.arguments.count + 1))
        self.writeStaticString("\r\n")
        self.writeRESP3TypeIdentifier(.blobString)
        self.writeString(String(command.command.count))
        self.writeStaticString("\r\n")
        self.writeString(command.command)
        self.writeStaticString("\r\n")
        for arg in command.arguments {
            self.writeRESP3TypeIdentifier(.blobString)
            self.writeString(String(arg.utf8.count))
            self.writeStaticString("\r\n")
            self.writeString(arg)
            self.writeStaticString("\r\n")
        }
    }
}
