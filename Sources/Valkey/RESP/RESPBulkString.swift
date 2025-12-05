//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore

/// Bulk string response from Valkey command
///
/// Bulk strings can store bytes, text, serialized objects and binary arrays.
/// RESPBulkString conforms to `RandomAccessCollection where Element == UInt8` allowing
/// readonly access to the contents of the bulk string.
///
/// You can also create a Swift String from a RESPBulkString using `String(_:)`.
/// ```
/// let bulkString = valkeyClient.get("myKey")
/// let string = bulkString.map { String($0) }
/// ```
///
/// Similarly if you want the bulk string bytes in the form of a SwiftNIO ByteBuffer
/// you can use the initializer `ByteBuffer(_:)`. This method returns the internal
/// buffer used by `RESPBulkString` so does not perform any copies.
/// ```
/// let bulkString = valkeyClient.get("myKey")
/// let buffer = bulkString.map { ByteBuffer($0) }
/// ```
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

    // These are implemented as no-ops for performance reasons. The range check will be performed
    // when the slice is indexed with an index and not a range.
    // See https://github.com/swiftlang/swift/blob/153dd02cd8709f8c6afcda5f173237320a3eec87/stdlib/public/core/Collection.swift#L638
    @inlinable
    public func _failEarlyRangeCheck(_ index: Index, bounds: Range<Index>) {}

    @inlinable
    public func _failEarlyRangeCheck(_ index: Index, bounds: ClosedRange<Index>) {}

    @inlinable
    public func _failEarlyRangeCheck(_ range: Range<Index>, bounds: Range<Index>) {}
}

#if compiler(>=6.2)
extension RESPBulkString {
    /// Provides high performance read only access to the contents of the RESPBulkString
    public var bytes: RawSpan {
        @_lifetime(borrow self)
        borrowing get {
            let span = self.buffer.readableBytesSpan
            return _overrideLifetime(span, borrowing: self)
        }
    }
}
#endif

extension RESPBulkString: RESPTokenDecodable {
    @inlinable
    public init(_ token: RESPToken) throws {
        self.buffer = try .init(token)
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
    /// Create String from `RESPBulkString`
    /// - Parameter bulkString: Source bulk string
    @inlinable
    public init(_ bulkString: RESPBulkString) {
        self.init(buffer: bulkString.buffer)
    }
}

extension ByteBuffer {
    /// Create ByteBuffer from `RESPBulkString`
    ///
    /// This method returns the internal buffer used by `RESPBulkString` so does not perform any copies.
    ///
    /// - Parameter bulkString: Source bulk string
    @inlinable
    public init(_ bulkString: RESPBulkString) {
        self = bulkString.buffer
    }
}
