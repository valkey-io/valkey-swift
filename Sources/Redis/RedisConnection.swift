import NIOCore
import RESP3

public final class RedisConnection {
    var inboundIterator: NIOAsyncChannelInboundStream<RESP3Token>.AsyncIterator
    let outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>

    public init(inbound: NIOAsyncChannelInboundStream<RESP3Token>, outbound: NIOAsyncChannelOutboundWriter<ByteBuffer>) {
        self.inboundIterator = inbound.makeAsyncIterator()
        self.outbound = outbound
    }

    public func send(_ command: RESPCommand) async throws -> RESP3Token {
        try await self.outbound.write(command.buffer)
        guard let response = try await self.inboundIterator.next() else { throw RedisClientError(.connectionClosed) }
        if let value = response.errorString {
            throw RedisClientError(.commandError, message: String(buffer: value))
        }
        return response
    }

    public func send<each Arg: RESPRepresentable>(_ command: repeat each Arg) async throws -> RESP3Token {
        let command = RESPCommand(repeat each command)
        try await self.outbound.write(command.buffer)
        guard let response = try await self.inboundIterator.next() else { throw RedisClientError(.connectionClosed) }
        if let value = response.errorString {
            throw RedisClientError(.commandError, message: String(buffer: value))
        }
        return response
    }

    public func pipeline(_ commands: [RESPCommand]) async throws -> [RESP3Token] {
        try await self.outbound.write(contentsOf: commands.map{ $0.buffer })
        var responses: [RESP3Token] = .init()
        for _ in 0..<commands.count {
            guard let response = try await self.inboundIterator.next() else { throw RedisClientError(.connectionClosed) }
            responses.append(response)
        }
        return responses
    }
}
