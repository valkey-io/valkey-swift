import NIOCore
import RESP3

public final class RedisConnection {
    var inboundIterator: NIOAsyncChannelInboundStream<RESP3Token>.AsyncIterator
    let outbound: NIOAsyncChannelOutboundWriter<RESP3Command>

    public init(inbound: NIOAsyncChannelInboundStream<RESP3Token>, outbound: NIOAsyncChannelOutboundWriter<RESP3Command>) {
        self.inboundIterator = inbound.makeAsyncIterator()
        self.outbound = outbound
    }

    public func send(_ command: RESP3Command) async throws -> RESP3Token {
        try await self.outbound.write(command)
        guard let response = try await self.inboundIterator.next() else { throw RedisClientError(.connectionClosed) }
        if let value = response.errorString {
            throw RedisClientError(.commandError, message: String(buffer: value))
        }
        return response
    }

    public func pipeline(_ commands: [RESP3Command]) async throws -> [RESP3Token] {
        try await self.outbound.write(contentsOf: commands)
        var responses: [RESP3Token] = .init()
        for _ in 0..<commands.count {
            guard let response = try await self.inboundIterator.next() else { throw RedisClientError(.connectionClosed) }
            responses.append(response)
        }
        return responses
    }
}
