//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore

/// Bulk string response from Valkey command
public struct RESPBulkString: Sendable, Equatable, Hashable, RandomAccessCollection {
    @usableFromInline
    let buffer: ByteBuffer
    @usableFromInline
    let range: Range<Index>

    @usableFromInline
    init(buffer: ByteBuffer, range: Range<Index>) {
        self.buffer = buffer
        self.range = range
    }

    /// Creates a `RESPBulkString` from the readable bytes of the given `buffer`.
    @usableFromInline
    init(_ buffer: ByteBuffer) {
        self = RESPBulkString(buffer: buffer, range: buffer.readerIndex..<buffer.writerIndex)
    }

    public typealias Element = UInt8
    public typealias Index = Int
    public typealias SubSequence = RESPBulkString

    @inlinable
    public var startIndex: Index {
        self.range.lowerBound
    }

    @inlinable
    public var endIndex: Index {
        self.range.upperBound
    }

    @inlinable
    public func index(after i: Index) -> Index {
        i + 1
    }

    @inlinable
    public var count: Int {
        // Unchecked is safe here: Range enforces that upperBound is strictly greater than
        // lower bound, and we guarantee that _range.lowerBound >= 0.
        self.range.upperBound &- self.range.lowerBound
    }

    @inlinable
    public subscript(position: Index) -> UInt8 {
        guard position >= self.range.lowerBound && position < self.range.upperBound else {
            preconditionFailure("index \(position) out of range")
        }
        return self.buffer.getInteger(at: position)!  // range check above

    }

    @inlinable
    public subscript(range: Range<Index>) -> RESPBulkString {
        RESPBulkString(buffer: self.buffer, range: range)
    }

    #if compiler(>=6.2)
    /// Provides safe high-performance read-only access to the readable bytes of this buffer.
    @inlinable
    @available(macOS 10.14.4, iOS 12.2, watchOS 5.2, tvOS 12.2, visionOS 1.0, *)
    public var bytes: RawSpan {
        @_lifetime(borrow self)
        get {
            self.buffer.readableBytesSpan
        }
    }
    #endif

    // These are implemented as no-ops for performance reasons.
    @inlinable
    public func _failEarlyRangeCheck(_ index: Index, bounds: Range<Index>) {}

    @inlinable
    public func _failEarlyRangeCheck(_ index: Index, bounds: ClosedRange<Index>) {}

    @inlinable
    public func _failEarlyRangeCheck(_ range: Range<Index>, bounds: Range<Index>) {}
}

extension RESPBulkString: RESPTokenDecodable {
    @inlinable
    public init(fromRESP token: RESPToken) throws {
        self.buffer = try .init(fromRESP: token)
        self.range = buffer.readerIndex..<buffer.writerIndex
    }
}

extension RESPBulkString: RESPStringRenderable {
    @inlinable
    public func encode(into commandEncoder: inout ValkeyCommandEncoder) {
        commandEncoder.encodeBulkString(self)
    }
}

extension String {
    @inlinable
    public init(fromBulkString bulkString: RESPBulkString) {
        self.init(buffer: bulkString.buffer)
    }
}

extension ByteBuffer {
    @inlinable
    public init(fromBulkString bulkString: RESPBulkString) {
        self = bulkString.buffer
    }
}
