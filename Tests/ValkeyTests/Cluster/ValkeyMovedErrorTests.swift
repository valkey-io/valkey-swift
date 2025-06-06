//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift project
//
// Copyright (c) 2025 the valkey-swift authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See valkey-swift/CONTRIBUTORS.txt for the list of valkey-swift authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore
import Testing

@testable import Valkey

@Suite("ValkeyMovedError")
struct ValkeyMovedErrorTests {

    @Test("parseMovedError parses valid MOVED error")
    func testParseValidMovedError() async throws {
        // Create a RESPToken with a MOVED error
        let token = RESPToken(.simpleError("MOVED 1234 redis.example.com:6379"))

        // Parse the moved error
        let movedError = token.parseMovedError()

        // Verify the moved error is parsed correctly
        #expect(movedError != nil)
        #expect(movedError?.slot.rawValue == 1234)
        #expect(movedError?.endpoint == "redis.example.com")
        #expect(movedError?.port == 6379)
    }

    @Test("parseMovedError parses valid MOVED error from bulkError")
    func testParseValidMovedErrorFromBulkError() async throws {
        // Create a RESPToken with a MOVED error
        let errorMessage = "MOVED 5000 10.0.0.1:6380"
        let byteBuffer = ByteBuffer(string: errorMessage)
        let token = RESPToken(.bulkError(byteBuffer))

        // Parse the moved error
        let movedError = token.parseMovedError()

        // Verify the moved error is parsed correctly
        #expect(movedError != nil)
        #expect(movedError?.slot.rawValue == 5000)
        #expect(movedError?.endpoint == "10.0.0.1")
        #expect(movedError?.port == 6380)
    }

    @Test("parseMovedError returns nil for non-error tokens")
    func testParseNonErrorToken() async throws {
        // Test with various non-error token types
        let nullToken = RESPToken(.null)
        #expect(nullToken.parseMovedError() == nil)

        let stringToken = RESPToken(.simpleString("OK"))
        #expect(stringToken.parseMovedError() == nil)

        let numberToken = RESPToken(.number(42))
        #expect(numberToken.parseMovedError() == nil)

        let arrayToken = RESPToken(.array([.number(1), .number(2)]))
        #expect(arrayToken.parseMovedError() == nil)
    }

    @Test("parseMovedError returns nil for error tokens without MOVED prefix")
    func testParseNonMovedError() async throws {
        let errorMessage = "ERR unknown command"
        let byteBuffer = ByteBuffer(string: errorMessage)
        let token = RESPToken(.simpleError(byteBuffer))

        #expect(token.parseMovedError() == nil)
    }

    @Test("parseMovedError returns nil for invalid MOVED format")
    func testParseInvalidMovedFormat() async throws {
        // Test with various invalid MOVED formats

        // Missing slot number
        let missingSlot = RESPToken(.simpleError("MOVED redis.example.com:6379"))
        #expect(missingSlot.parseMovedError() == nil)

        // Missing port number
        let missingPort = RESPToken(.simpleError("MOVED 1234 redis.example.com"))
        #expect(missingPort.parseMovedError() == nil)

        // Invalid slot number
        let invalidSlot = RESPToken(.simpleError("MOVED abc redis.example.com:6379"))
        #expect(invalidSlot.parseMovedError() == nil)

        // Invalid port number
        let invalidPort = RESPToken(.simpleError("MOVED 1234 redis.example.com:port"))
        #expect(invalidPort.parseMovedError() == nil)

        // Slot number out of range
        let outOfRangeSlot = RESPToken(.simpleError("MOVED 999999 redis.example.com:6379"))
        #expect(outOfRangeSlot.parseMovedError() == nil)
    }

    @Test("ValkeyMovedError is Hashable")
    func testHashable() async throws {
        let error1 = ValkeyMovedError(slot: 1234, endpoint: "redis1.example.com", port: 6379)
        let error2 = ValkeyMovedError(slot: 1234, endpoint: "redis1.example.com", port: 6379)
        let error3 = ValkeyMovedError(slot: 5678, endpoint: "redis2.example.com", port: 6380)

        #expect(error1 == error2)
        #expect(error1 != error3)

        var set = Set<ValkeyMovedError>()
        set.insert(error1)
        set.insert(error2)  // This should not increase the size as it's equal to error1
        set.insert(error3)

        #expect(set.count == 2)
        #expect(set.contains(error1))
        #expect(set.contains(error3))
    }
}
