//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-redis open source project
//
// Copyright (c) 2023 Apple Inc. and the swift-redis project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-redis project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore
import NIOTestUtils
import XCTest

@testable import RESP

final class RESPCommandTests: XCTestCase {
    func decode(command: RESPCommand) throws -> [String] {
        struct DecodeError: Error, CustomStringConvertible {
            var description: String { "Decoding command failed" }
        }
        var buffer = command.buffer
        guard let token = try RESPToken(consuming: &buffer) else { throw DecodeError() }
        return try token.converting(to: [String].self)
    }

    func testStrings() throws {
        let command = RESPCommand("test", "this")
        let decodedCommand = try decode(command: command)
        XCTAssertEqual(decodedCommand, ["test", "this"])
    }

    func testIntegers() throws {
        let command = RESPCommand("test", 1, -1)
        let decodedCommand = try decode(command: command)
        XCTAssertEqual(decodedCommand, ["test", "1", "-1"])
    }

    func testStringArray() throws {
        let command = RESPCommand("test", ["this", "and", "that"])
        let decodedCommand = try decode(command: command)
        XCTAssertEqual(decodedCommand, ["test", "this", "and", "that"])
    }

    func testOptionalString() throws {
        let string: String? = "this"
        let command = RESPCommand("test", string)
        let decodedCommand = try decode(command: command)
        XCTAssertEqual(decodedCommand, ["test", "this"])
    }

    func testNullOptionalString() throws {
        let string: String? = nil
        let command = RESPCommand("test", string)
        let decodedCommand = try decode(command: command)
        XCTAssertEqual(decodedCommand, ["test"])
    }
}
