//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore
import Valkey

enum RESP3Value: Hashable, Sendable {
    case simpleString(ByteBuffer)
    case simpleError(ByteBuffer)
    case bulkString(ByteBuffer)
    case bulkError(ByteBuffer)
    case verbatimString(ByteBuffer)
    case number(Int64)
    case double(Double)
    case boolean(Bool)
    case null
    case bigNumber(ByteBuffer)
    case array([RESP3Value])
    case attribute([RESP3Value: RESP3Value])
    case map([RESP3Value: RESP3Value])
    case set([RESP3Value])
    case push([RESP3Value])

    static func bulkString(_ value: String) -> RESP3Value {
        .bulkString(ByteBuffer(string: value))
    }

    static func simpleString(_ value: String) -> RESP3Value {
        .simpleString(ByteBuffer(string: value))
    }

    static func simpleError(_ value: String) -> RESP3Value {
        .simpleError(ByteBuffer(string: value))
    }

    static func verbatimString(_ value: String) -> RESP3Value {
        .verbatimString(ByteBuffer(string: value))
    }

    static func bigNumber(_ value: String) -> RESP3Value {
        .bigNumber(ByteBuffer(string: value))
    }

    static func bulkError(_ value: String) -> RESP3Value {
        .bulkError(ByteBuffer(string: value))
    }

    static func command(_ values: [String]) -> RESP3Value {
        .array(values.map { .bulkString($0) })
    }

    fileprivate func writeTo(_ buffer: inout ByteBuffer) {

        func writeLengthPrefixedBytes(_ bytes: ByteBuffer, into buffer: inout ByteBuffer) {
            buffer.writeBytes("\(bytes.readableBytes)".utf8)
            buffer.writeCRLF()
            buffer.writeBytes(bytes.readableBytesView)
            buffer.writeCRLF()
        }

        func writeSequence(_ values: [RESP3Value], into buffer: inout ByteBuffer) {
            buffer.writeBytes("\(values.count)".utf8)
            buffer.writeCRLF()
            for value in values { value.writeTo(&buffer) }
        }

        func writeMap(_ map: [RESP3Value: RESP3Value], into buffer: inout ByteBuffer) {
            buffer.writeBytes("\(map.count)".utf8)
            buffer.writeCRLF()
            for (key, value) in map {
                key.writeTo(&buffer)
                value.writeTo(&buffer)
            }
        }

        switch self {
        case .simpleError(let value):
            buffer.writeBytes("-".utf8)
            buffer.writeBytes(value.readableBytesView)
            buffer.writeCRLF()

        case .simpleString(let value):
            buffer.writeBytes("+".utf8)
            buffer.writeBytes(value.readableBytesView)
            buffer.writeCRLF()

        case .bulkString(let value):
            buffer.writeBytes("$".utf8)
            writeLengthPrefixedBytes(value, into: &buffer)

        case .bulkError(let value):
            buffer.writeBytes("!".utf8)
            writeLengthPrefixedBytes(value, into: &buffer)

        case .verbatimString(let value):
            buffer.writeBytes("=".utf8)
            writeLengthPrefixedBytes(value, into: &buffer)

        case .number(let number):
            buffer.writeBytes(":".utf8)
            buffer.writeBytes(String(number).utf8)
            buffer.writeCRLF()

        case .double(let value):
            buffer.writeBytes(",".utf8)
            buffer.writeBytes(String(value).utf8)
            buffer.writeCRLF()

        case .null:
            buffer.writeBytes("_".utf8)
            buffer.writeCRLF()

        case .boolean(let value):
            buffer.writeBytes("#".utf8)
            if value {
                buffer.writeBytes("t".utf8)
            } else {
                buffer.writeBytes("f".utf8)
            }
            buffer.writeCRLF()

        case .bigNumber(let number):
            buffer.writeBytes("(".utf8)
            buffer.writeBytes(number.readableBytesView)
            buffer.writeCRLF()

        case .array(let values):
            buffer.writeBytes("*".utf8)
            writeSequence(values, into: &buffer)

        case .attribute(let values):
            buffer.writeBytes("|".utf8)
            writeMap(values, into: &buffer)

        case .map(let values):
            buffer.writeBytes("%".utf8)
            writeMap(values, into: &buffer)

        case .set(let values):
            buffer.writeBytes("~".utf8)
            writeSequence(values, into: &buffer)

        case .push(let values):
            buffer.writeBytes(">".utf8)
            writeSequence(values, into: &buffer)
        }
    }
}

extension RESPToken {
    init(_ value: RESP3Value) {
        var buffer = ByteBuffer()
        value.writeTo(&buffer)
        try! self.init(consuming: &buffer)!
    }
}

extension ByteBuffer {
    mutating func writeCRLF() {
        self.writeBytes("\r\n".utf8)
    }
}

extension ByteBuffer {
    init(_ respValue: RESP3Value) {
        var buffer = ByteBuffer()
        respValue.writeTo(&buffer)
        self = buffer
    }
}
