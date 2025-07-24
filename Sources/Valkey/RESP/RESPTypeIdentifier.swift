//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of valkey-swift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A value that represents the response type.
public enum RESPTypeIdentifier: UInt8 {
    /// An integer
    case integer = 58  // UInt8(ascii: ":")
    /// A double
    case double = 44  // UInt8.comma
    /// A simple string
    case simpleString = 43  // UInt8.plus
    /// A simple error
    case simpleError = 45  // UInt8.min
    /// A bulk string
    case bulkString = 36  // UInt8.dollar
    /// A bulk error
    case bulkError = 33  // UInt8.exclamationMark
    /// A verbatim string
    case verbatimString = 61  // UInt8.equals
    /// A Boolean value
    case boolean = 35  // UInt8.pound
    /// A null
    case null = 95  // UInt8.underscore
    /// A big number
    case bigNumber = 40  // UInt8.leftRoundBracket
    /// An array
    case array = 42  // UInt8.asterisk
    /// A map
    case map = 37  // UInt8.percent
    /// A set
    case set = 126  // UInt8.tilde
    /// An attribute
    case attribute = 124  // UInt8.pipe
    /// A push
    case push = 62  // UInt8.rightAngledBracket
}

extension UInt8 {
    static let newline = UInt8(ascii: "\n")
    static let carriageReturn = UInt8(ascii: "\r")
    static let colon = UInt8(ascii: ":")
    static let pound = UInt8(ascii: "#")
    static let t = UInt8(ascii: "t")
    static let f = UInt8(ascii: "f")
}
