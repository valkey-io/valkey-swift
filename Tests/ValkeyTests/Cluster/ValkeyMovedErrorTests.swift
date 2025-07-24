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
        // Parse the moved error
        let movedError = ValkeyMovedError("MOVED 1234 redis.example.com:6379")

        // Verify the moved error is parsed correctly
        #expect(movedError != nil)
        #expect(movedError?.slot.rawValue == 1234)
        #expect(movedError?.endpoint == "redis.example.com")
        #expect(movedError?.port == 6379)
    }

    @Test("parseMovedError parses valid MOVED error with IPv4")
    func testParseValidMovedErrorWithIPv4() async throws {
        // Create a RESPToken with a MOVED error
        let errorMessage = "MOVED 5000 10.0.0.1:6380"

        // Parse the moved error
        let movedError = ValkeyMovedError(errorMessage)

        // Verify the moved error is parsed correctly
        #expect(movedError != nil)
        #expect(movedError?.slot.rawValue == 5000)
        #expect(movedError?.endpoint == "10.0.0.1")
        #expect(movedError?.port == 6380)
    }

    @Test("parseMovedError parses valid MOVED error with IPv6")
    func testParseValidMovedErrorWithIPv6() async throws {
        // Create a RESPToken with a MOVED error
        let errorMessage = "MOVED 5000 ::1:9000"

        // Parse the moved error
        let movedError = ValkeyMovedError(errorMessage)

        // Verify the moved error is parsed correctly
        #expect(movedError != nil)
        #expect(movedError?.slot.rawValue == 5000)
        #expect(movedError?.endpoint == "::1")
        #expect(movedError?.port == 9000)
    }

    @Test("parseMovedError returns nil for error tokens without MOVED prefix")
    func testParseNonMovedError() async throws {
        #expect(ValkeyMovedError("ERR unknown command") == nil)
    }

    @Test("parseMovedError returns nil for invalid MOVED format")
    func testParseInvalidMovedFormat() async throws {
        // Test with various invalid MOVED formats

        // Missing slot number
        #expect(ValkeyMovedError("MOVED redis.example.com:6379") == nil)

        // Missing port number
        let missingPort = "MOVED 1234 redis.example.com"
        #expect(ValkeyMovedError(missingPort) == nil)

        // Invalid slot number
        let invalidSlot = "MOVED abc redis.example.com:6379"
        #expect(ValkeyMovedError(invalidSlot) == nil)

        // Invalid port number
        let invalidPort = "MOVED 1234 redis.example.com:port"
        #expect(ValkeyMovedError(invalidPort) == nil)

        // Slot number out of range
        let outOfRangeSlot = "MOVED 999999 redis.example.com:6379"
        #expect(ValkeyMovedError(outOfRangeSlot) == nil)
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
