//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore
import Testing
import Valkey

struct RESPTokenDecodableTests {
    @Test(arguments: [
        ("+SimpleString\r\n", "SimpleString"),
        ("$10\r\nBulkString\r\n", "BulkString"),
        ("(1234567890\r\n", "1234567890"),
        ("=14\r\ntxt:BulkString\r\n", "txt:BulkString"),  // should this ditch the text type, or store it separately
    ])
    func string(testValues: (String, String)) throws {
        var buffer = ByteBuffer(string: testValues.0)
        let token = try #require(try RESPToken(consuming: &buffer))
        let string = try String(fromRESP: token)
        #expect(string == testValues.1)
    }

    @Test(arguments: [
        (":45\r\n", 45),
        (":-1000\r\n", -1000),
    ])
    func integer(testValues: (String, Int)) throws {
        var buffer = ByteBuffer(string: testValues.0)
        let token = try #require(try RESPToken(consuming: &buffer))
        let value = try Int(fromRESP: token)
        #expect(value == testValues.1)
    }

    @Test(arguments: [
        (",45.0\r\n", 45),
        (",-1000.25\r\n", -1000.25),
    ])
    func double(testValues: (String, Double)) throws {
        var buffer = ByteBuffer(string: testValues.0)
        let token = try #require(try RESPToken(consuming: &buffer))
        let value = try Double(fromRESP: token)
        #expect(value == testValues.1)
    }

    @Test(arguments: [
        ("#t\r\n", true),
        ("#f\r\n", false),
    ])
    func boolean(testValues: (String, Bool)) throws {
        var buffer = ByteBuffer(string: testValues.0)
        let token = try #require(try RESPToken(consuming: &buffer))
        let value = try Bool(fromRESP: token)
        #expect(value == testValues.1)
    }

    @Test(arguments: [
        ("$10\r\nBulkString\r\n", "BulkString"),
        ("_\r\n", nil),
    ])
    func optional(testValues: (String, String?)) throws {
        var buffer = ByteBuffer(string: testValues.0)
        let token = try #require(try RESPToken(consuming: &buffer))
        let value = try String?(fromRESP: token)
        #expect(value == testValues.1)
    }

    @Test(arguments: [
        ("*2\r\n$1\r\na\r\n$1\r\nb\r\n", ["a", "b"]),
        ("*1\r\n$1\r\na\r\n", ["a"]),
        ("$1\r\na\r\n", ["a"]),
    ])
    func array(testValues: (String, [String])) throws {
        var buffer = ByteBuffer(string: testValues.0)
        let token = try #require(try RESPToken(consuming: &buffer))
        let value = try [String](fromRESP: token)
        #expect(value == testValues.1)
    }

    @Test(arguments: [
        ("~2\r\n$1\r\na\r\n$1\r\nb\r\n", Set(["a", "b"])),
        ("~1\r\n$1\r\na\r\n", Set(["a"])),
    ])
    func set(testValues: (String, Set<String>)) throws {
        var buffer = ByteBuffer(string: testValues.0)
        let token = try #require(try RESPToken(consuming: &buffer))
        let value = try Set<String>(fromRESP: token)
        #expect(value == testValues.1)
    }

    @Test(arguments: [
        ("%3\r\n$3\r\none\r\n:1\r\n$3\r\ntwo\r\n:2\r\n$5\r\nthree\r\n:3\r\n", ["one": 1, "two": 2, "three": 3]),
        ("%1\r\n$4\r\nfour\r\n:4\r\n", ["four": 4]),
    ])
    func dictionary(testValues: (String, [String: Int])) throws {
        var buffer = ByteBuffer(string: testValues.0)
        let token = try #require(try RESPToken(consuming: &buffer))
        let value = try [String: Int](fromRESP: token)
        #expect(value == testValues.1)
    }

    @Test
    func closedRange() throws {
        var buffer = ByteBuffer(string: "*2\r\n:1\r\n:10\r\n")
        let token = try #require(try RESPToken(consuming: &buffer))
        let value = try ClosedRange<Int>(fromRESP: token)
        #expect(value == 1...10)
    }

    @Test
    func arrayElements() async throws {
        var buffer = ByteBuffer(string: "*4\r\n:8\r\n,10.001\r\n$10\r\nBulkString\r\n*2\r\n#t\r\n#f\r\n")
        let token = try #require(try RESPToken(consuming: &buffer))
        let value = try token.decodeArrayElements(as: (Int, Double, String, [Bool]).self)
        #expect(value.0 == 8)
        #expect(value.1 == 10.001)
        #expect(value.2 == "BulkString")
        #expect(value.3 == [true, false])
    }

    @Test(arguments: [
        ("*2\r\n:1\r\n:45\r\n", [1...45]),
        ("*2\r\n*2\r\n:1\r\n:6\r\n*2\r\n:8\r\n:34\r\n", [1...6, 8...34]),
    ])
    func arrayOfRanges(testValues: (String, [ClosedRange<Int>])) throws {
        var buffer = ByteBuffer(string: testValues.0)
        let token = try #require(try RESPToken(consuming: &buffer))
        let value = try [ClosedRange<Int>](fromRESP: token)
        #expect(value == testValues.1)
    }

    @Test(arguments: [
        ("*2\r\n$3\r\none\r\n$1\r\n1\r\n", [("one", "1")]),
        ("*4\r\n$3\r\none\r\n$1\r\n1\r\n$3\r\ntwo\r\n$1\r\n2\r\n", [("one", "1"), ("two", "2")]),
    ])
    func arrayOfKeyValuePairs(testValues: (String, [(String, String)])) throws {
        var buffer = ByteBuffer(string: testValues.0)
        let token = try #require(try RESPToken(consuming: &buffer))
        switch token.value {
        case .array(let array):
            let values = try array.decodeKeyValuePairs(as: [(String, String)].self)
            #expect(values.count == testValues.1.count)
            for i in 0..<values.count {
                #expect(values[i] == testValues.1[i])
            }
        default:
            Issue.record("Token is not an array")
        }
    }
}
