//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore
import Testing

@testable import Valkey

@Suite("ValkeyMovedError")
struct ValkeyRedirectionErrorTests {

    @Test("parseMovedError parses valid MOVED error")
    func testParseValidMovedError() async throws {
        // Parse the moved error
        let movedError = ValkeyClusterRedirectionError("MOVED 1234 valkey.example.com:6379")

        // Verify the moved error is parsed correctly
        #expect(movedError != nil)
        #expect(movedError?.slot.rawValue == 1234)
        #expect(movedError?.endpoint == "valkey.example.com")
        #expect(movedError?.port == 6379)
        #expect(movedError?.redirection == .move)
    }

    @Test("parseMovedError parses valid ASK error")
    func testParseValidAskError() async throws {
        // Parse the ask error
        let movedError = ValkeyClusterRedirectionError("ASK 1234 valkey.example.com:6379")

        // Verify the moved error is parsed correctly
        #expect(movedError != nil)
        #expect(movedError?.slot.rawValue == 1234)
        #expect(movedError?.endpoint == "valkey.example.com")
        #expect(movedError?.port == 6379)
        #expect(movedError?.redirection == .ask)
    }

    @Test("parseMovedError parses valid MOVED error with IPv4")
    func testParseValidMovedErrorWithIPv4() async throws {
        // Create a RESPToken with a MOVED error
        let errorMessage = "MOVED 5000 10.0.0.1:6380"

        // Parse the moved error
        let movedError = ValkeyClusterRedirectionError(errorMessage)

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
        let movedError = ValkeyClusterRedirectionError(errorMessage)

        // Verify the moved error is parsed correctly
        #expect(movedError != nil)
        #expect(movedError?.slot.rawValue == 5000)
        #expect(movedError?.endpoint == "::1")
        #expect(movedError?.port == 9000)
    }

    @Test("parseMovedError returns nil for error tokens without MOVED prefix")
    func testParseNonMovedError() async throws {
        #expect(ValkeyClusterRedirectionError("ERR unknown command") == nil)
    }

    @Test("parseMovedError returns nil for invalid MOVED format")
    func testParseInvalidMovedFormat() async throws {
        // Test with various invalid MOVED formats

        // Missing slot number
        #expect(ValkeyClusterRedirectionError("MOVED valkey.example.com:6379") == nil)

        // Missing port number
        let missingPort = "MOVED 1234 valkey.example.com"
        #expect(ValkeyClusterRedirectionError(missingPort) == nil)

        // Invalid slot number
        let invalidSlot = "MOVED abc valkey.example.com:6379"
        #expect(ValkeyClusterRedirectionError(invalidSlot) == nil)

        // Invalid port number
        let invalidPort = "MOVED 1234 valkey.example.com:port"
        #expect(ValkeyClusterRedirectionError(invalidPort) == nil)

        // Slot number out of range
        let outOfRangeSlot = "MOVED 999999 valkey.example.com:6379"
        #expect(ValkeyClusterRedirectionError(outOfRangeSlot) == nil)
    }

    @Test("ValkeyMovedError is Hashable")
    func testHashable() async throws {
        let error1 = ValkeyClusterRedirectionError(request: .move, slot: 1234, endpoint: "redis1.example.com", port: 6379)
        let error2 = ValkeyClusterRedirectionError(request: .move, slot: 1234, endpoint: "redis1.example.com", port: 6379)
        let error3 = ValkeyClusterRedirectionError(request: .move, slot: 5678, endpoint: "redis2.example.com", port: 6380)
        let error4 = ValkeyClusterRedirectionError(request: .ask, slot: 5678, endpoint: "redis2.example.com", port: 6380)

        #expect(error1 == error2)
        #expect(error1 != error3)
        #expect(error3 != error4)

        var set = Set<ValkeyClusterRedirectionError>()
        set.insert(error1)
        set.insert(error2)  // This should not increase the size as it's equal to error1
        set.insert(error3)
        set.insert(error4)

        #expect(set.count == 3)
        #expect(set.contains(error1))
        #expect(set.contains(error3))
        #expect(set.contains(error4))
    }
}
