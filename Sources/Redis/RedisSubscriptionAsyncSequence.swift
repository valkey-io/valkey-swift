import RESP3

struct RedisSubscriptionAsyncSequence<Base: AsyncSequence>: AsyncSequence where Base.Element == RESP3Token {
    typealias Element = Base.Element
    typealias AsyncIterator = Base.AsyncIterator
    let baseIterator: Base.AsyncIterator

    func makeAsyncIterator() -> Base.AsyncIterator {
        self.baseIterator
    }
}

@available(*, unavailable)
extension RedisSubscriptionAsyncSequence: Sendable {
}
