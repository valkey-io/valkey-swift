//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import Testing
import Valkey

struct RESPDecodeErrorTests {
    @Test
    func testTokenMismatchWith() {
        let resp = RESPToken(.null)
        let error = #expect(throws: RESPDecodeError.self) {
            _ = try Bool(resp)
        }
        #expect(error?.errorCode == .tokenMismatch)
        #expect(error?.message == #"Expected to find a boolean"#)
    }

    @Test
    func testTokenMismatchWithMultipleMatches() {
        let resp = RESPToken(.null)
        let error = #expect(throws: RESPDecodeError.self) {
            _ = try Double(resp)
        }
        #expect(error?.errorCode == .tokenMismatch)
        #expect(error?.message == #"Expected to find a double, integer or bulkString token"#)
        print(error!)
    }

    @Test
    func testInvalidArraySize() {
        struct Test: RESPTokenDecodable {
            let number: Double
            let number2: Double
            init(_ token: RESPToken) throws(RESPDecodeError) {
                (self.number, self.number2) = try token.decodeArrayElements()
            }
        }
        let resp = RESPToken(.array([.double(1.0)]))
        let error = #expect(throws: RESPDecodeError.self) {
            _ = try Test(resp)
        }
        #expect(error?.errorCode == .invalidArraySize)
        #expect(error?.message == "Expected array of size 2 but got an array of size 1")
    }

    @Test
    func testCannotParseInt() {
        let resp = RESPToken(.bulkString("1.0"))
        let error = #expect(throws: RESPDecodeError.self) {
            _ = try Int(resp)
        }
        #expect(error?.errorCode == .cannotParseInteger)
        print(error!)
    }

    @Test
    func testCannotParseDouble() {
        let resp = RESPToken(.bulkString("1.0a"))
        let error = #expect(throws: RESPDecodeError.self) {
            _ = try Double(resp)
        }
        #expect(error?.errorCode == .cannotParseDouble)
    }
}
