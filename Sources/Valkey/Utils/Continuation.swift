
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
@frozen
public struct Continuation<Success, Failure: Error>: ~Copyable, Sendable {

    @usableFromInline
    let unsafeContinuation: UnsafeContinuation<Success, Failure>

    @inlinable
    init(_ unsafeContinuation: UnsafeContinuation<Success, Failure>) {
        self.unsafeContinuation = unsafeContinuation
    }

    deinit {
        fatalError("This continuation was dropped.")
    }

    @inlinable
    consuming public func resume() where Success == Void {
        self.unsafeContinuation.resume()
        discard self // prevent deinit
    }

    @inlinable
    consuming public func resume(returning value: sending Success) {
        self.unsafeContinuation.resume(returning: value)
        discard self // prevent deinit
    }

    @inlinable
    consuming public func resume(throwing error: consuming Failure) {
        self.unsafeContinuation.resume(throwing: error)
        discard self // prevent deinit
    }

    @inlinable
    consuming public func resume(with result: sending Result<Success, Failure>) {
        self.unsafeContinuation.resume(with: result)
    }
}

@inlinable
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public func withContinuation<Success>(of: Success.Type, _ body: (consuming Continuation<Success, Never>) -> Void) async -> Success {
    await withUnsafeContinuation { (continuation: UnsafeContinuation<Success, Never>) in
        body(Continuation(continuation))
    }
}

@inlinable
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public func withThrowingContinuation<Success>(of: Success.Type = Success.self, _ body: (consuming Continuation<Success, any Error>) -> Void) async throws -> Success {
    try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<Success, any Error>) in
        body(Continuation(continuation))
    }
}
