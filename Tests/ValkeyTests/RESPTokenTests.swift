//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore
import NIOTestUtils
import Testing

@testable import Valkey

struct RESPTokenTests {
    @Test
    func testRESP3NullToken() throws {
        let input = ByteBuffer(string: "_\r\n")
        let respNull = RESPToken(validated: input)

        try ByteToMessageDecoderVerifier.verifyDecoder(
            inputOutputPairs: [(input, [respNull])],
            decoderFactory: { RESPTokenDecoder() }
        )

        #expect(respNull.value == .null)
    }

    @Test
    func testRESP2NullStringToken() throws {
        let input = ByteBuffer(string: "$-1\r\n")
        let respNull = RESPToken(validated: input)

        try ByteToMessageDecoderVerifier.verifyDecoder(
            inputOutputPairs: [(input, [respNull])],
            decoderFactory: { RESPTokenDecoder() }
        )

        #expect(respNull.value == .null)
    }

    @Test
    func testRESP2NullArrayToken() throws {
        let input = ByteBuffer(string: "*-1\r\n")
        let respNull = RESPToken(validated: input)

        try ByteToMessageDecoderVerifier.verifyDecoder(
            inputOutputPairs: [(input, [respNull])],
            decoderFactory: { RESPTokenDecoder() }
        )

        #expect(respNull.value == .null)
    }

    @Test
    func testRESPBool() throws {
        let inputTrue = ByteBuffer(string: "#t\r\n")
        let inputFalse = ByteBuffer(string: "#f\r\n")
        let respTrue = RESPToken(validated: inputTrue)
        let respFalse = RESPToken(validated: inputFalse)

        try ByteToMessageDecoderVerifier.verifyDecoder(
            inputOutputPairs: [
                (inputTrue, [respTrue]),
                (inputFalse, [respFalse]),
            ],
            decoderFactory: { RESPTokenDecoder() }
        )

        #expect(respTrue.value == .boolean(true))
        #expect(respFalse.value == .boolean(false))
    }

    @Test
    func testRESPNumber() throws {
        let input123123 = ByteBuffer(string: ":123123\r\n")
        let input42 = ByteBuffer(string: ":42\r\n")
        let input0 = ByteBuffer(string: ":0\r\n")
        let inputMax = ByteBuffer(string: ":\(Int64.max)\r\n")
        let inputMin = ByteBuffer(string: ":\(Int64.min)\r\n")
        let resp123123 = RESPToken(validated: input123123)
        let resp42 = RESPToken(validated: input42)
        let resp0 = RESPToken(validated: input0)
        let respMax = RESPToken(validated: inputMax)
        let respMin = RESPToken(validated: inputMin)

        try ByteToMessageDecoderVerifier.verifyDecoder(
            inputOutputPairs: [
                (input123123, [resp123123]),
                (input42, [resp42]),
                (input0, [resp0]),
                (inputMax, [respMax]),
                (inputMin, [respMin]),
            ],
            decoderFactory: { RESPTokenDecoder() }
        )

        #expect(resp123123.value == .number(123_123))
        #expect(resp42.value == .number(42))
        #expect(resp0.value == .number(0))
        #expect(respMax.value == .number(.max))
        #expect(respMin.value == .number(.min))
    }

    @Test
    func testRESPNumberInvalid() throws {
        let invalid = [
            ":\(Int.max)1\r\n",
            ":\(Int.min)1\r\n",
        ]

        for value in invalid {
            let buffer = ByteBuffer(string: value)
            #expect {
                try ByteToMessageDecoderVerifier.verifyDecoder(
                    inputOutputPairs: [
                        (buffer, [RESPToken(validated: .init())])
                    ],
                    decoderFactory: { RESPTokenDecoder() }
                )
            } throws: { error in
                let error = try #require(error as? RESPParsingError)
                #expect(error.buffer == buffer)
                #expect(error.code == .canNotParseInteger)
                return true
            }
        }
    }

    @Test
    func testRESPDouble() throws {
        let input123 = ByteBuffer(string: ",1.23\r\n")
        let input42 = ByteBuffer(string: ",42\r\n")
        let input0 = ByteBuffer(string: ",0\r\n")
        let inputInf = ByteBuffer(string: ",inf\r\n")
        let inputNegInf = ByteBuffer(string: ",-inf\r\n")
        let inputNan = ByteBuffer(string: ",nan\r\n")
        let inputPi = ByteBuffer(string: ",\(Double.pi)\r\n")
        let inputExponent = ByteBuffer(string: ",1.4E12\r\n")
        let inputLowerExponent = ByteBuffer(string: ",1.4e-12\r\n")
        let resp123 = RESPToken(validated: input123)
        let resp42 = RESPToken(validated: input42)
        let resp0 = RESPToken(validated: input0)
        let respInf = RESPToken(validated: inputInf)
        let respNegInf = RESPToken(validated: inputNegInf)
        let respNan = RESPToken(validated: inputNan)
        let respPi = RESPToken(validated: inputPi)
        let respExponent = RESPToken(validated: inputExponent)
        let respLowerExponent = RESPToken(validated: inputLowerExponent)

        try ByteToMessageDecoderVerifier.verifyDecoder(
            inputOutputPairs: [
                (input123, [resp123]),
                (input42, [resp42]),
                (input0, [resp0]),
                (inputInf, [respInf]),
                (inputNegInf, [respNegInf]),
                (inputNan, [respNan]),
                (inputPi, [respPi]),
                (inputExponent, [respExponent]),
                (inputLowerExponent, [respLowerExponent]),
            ],
            decoderFactory: { RESPTokenDecoder() }
        )

        #expect(resp123.value == .double(1.23))
        #expect(resp42.value == .double(42))
        #expect(resp0.value == .double(0))
        #expect(respInf.value == .double(.infinity))
        #expect(respNegInf.value == .double(-.infinity))
        guard case .double(let value) = respNan.value else {
            Issue.record("Expected a double")
            return
        }
        #expect(value.isNaN)
        #expect(respPi.value == .double(.pi))
    }

    #if false
    // TODO: this test currently succeeds, even though it has an invalid value
    @Test
    func testRESPDoubleInvalid() throws {
        let invalid = [
            ",.1\r\n"
        ]

        for value in invalid {
            XCTAssertThrowsError(
                try ByteToMessageDecoderVerifier.verifyDecoder(
                    inputOutputPairs: [
                        (.init(string: value), [RESPToken(validated: .init())])
                    ],
                    decoderFactory: { RESPTokenDecoder() }
                )
            ) {
                #expect($0 as? RESPError, .dataMalformed, "unexpected error: \($0)")
            }
        }
    }
    #endif

    @Test
    func testRESPBigNumber() throws {
        let valid = [
            "123"
        ]

        for value in valid {
            let tokenString = "(\(value)\r\n"
            let token = ByteBuffer(string: tokenString)
            try ByteToMessageDecoderVerifier.verifyDecoder(
                inputOutputPairs: [
                    (token, [RESPToken(validated: token)])
                ],
                decoderFactory: { RESPTokenDecoder() }
            )

            #expect(RESPToken(validated: token).value == .bigNumber(.init(string: value)))
        }
    }

    @Test(arguments: [
        "(--123\r\n",
        "(12-12\r\n",
        "(-\r\n",
        "(\r\n",

    ])
    func testRESPBigNumberInvalid(value: String) throws {
        let buffer = ByteBuffer(string: value)
        #expect {
            try ByteToMessageDecoderVerifier.verifyDecoder(
                inputOutputPairs: [
                    (buffer, [RESPToken(validated: .init())])
                ],
                decoderFactory: { RESPTokenDecoder() }
            )
        } throws: { error in
            let error = try #require(error as? RESPParsingError)
            #expect(error.buffer == buffer)
            #expect(error.code == .canNotParseBigNumber)
            return true
        }

    }

    @Test
    func testBlobString() throws {
        let inputString = ByteBuffer(string: "$12\r\naaaabbbbcccc\r\n")
        let respString = RESPToken(validated: inputString)

        let inputError = ByteBuffer(string: "!21\r\nSYNTAX invalid syntax\r\n")
        let respError = RESPToken(validated: inputError)

        let inputVerbatim = ByteBuffer(string: "=16\r\ntxt:aaaabbbbcccc\r\n")
        let respVerbatim = RESPToken(validated: inputVerbatim)

        try ByteToMessageDecoderVerifier.verifyDecoder(
            inputOutputPairs: [
                (inputString, [respString]),
                (inputError, [respError]),
                (inputString, [respString]),
            ],
            decoderFactory: { RESPTokenDecoder() }
        )

        #expect(respString.value == .bulkString(ByteBuffer(string: "aaaabbbbcccc")))
        #expect(respError.value == .bulkError(ByteBuffer(string: "SYNTAX invalid syntax")))
        #expect(respVerbatim.value == .verbatimString(ByteBuffer(string: "txt:aaaabbbbcccc")))
    }

    @Test
    func testSimpleString() throws {
        let inputString = ByteBuffer(string: "+aaaabbbbcccc\r\n")
        let respString = RESPToken(validated: inputString)
        let inputError = ByteBuffer(string: "-eeeeffffgggg\r\n")
        let respError = RESPToken(validated: inputError)

        try ByteToMessageDecoderVerifier.verifyDecoder(
            inputOutputPairs: [
                (inputString, [respString]),
                (inputError, [respError]),
            ],
            decoderFactory: { RESPTokenDecoder() }
        )

        #expect(respString.value == .simpleString(ByteBuffer(string: "aaaabbbbcccc")))
        #expect(respError.value == .simpleError(ByteBuffer(string: "eeeeffffgggg")))
    }

    @Test
    func testArray() throws {
        let emptyArrayInput = ByteBuffer(string: "*0\r\n")
        let respEmptyArray = RESPToken(validated: emptyArrayInput)

        let simpleStringArray1Input = ByteBuffer(string: "*1\r\n+aaaabbbbcccc\r\n")
        let respSimpleStringArray1 = RESPToken(validated: simpleStringArray1Input)

        let simpleStringArray2Input = ByteBuffer(string: "*2\r\n+aaaa\r\n+bbbb\r\n")
        let respSimpleStringArray2 = RESPToken(validated: simpleStringArray2Input)

        let simpleStringArray3Input = ByteBuffer(string: "*3\r\n*0\r\n+a\r\n-b\r\n")
        let respSimpleStringArray3 = RESPToken(validated: simpleStringArray3Input)

        let simpleStringPush3Input = ByteBuffer(string: ">3\r\n*0\r\n+a\r\n-b\r\n")
        let respSimpleStringPush3 = RESPToken(validated: simpleStringPush3Input)

        let simpleStringSet3Input = ByteBuffer(string: "~3\r\n*0\r\n+a\r\n#t\r\n")
        let respSimpleStringSet3 = RESPToken(validated: simpleStringSet3Input)

        try ByteToMessageDecoderVerifier.verifyDecoder(
            inputOutputPairs: [
                (emptyArrayInput, [respEmptyArray]),
                (simpleStringArray1Input, [respSimpleStringArray1]),
                (simpleStringArray2Input, [respSimpleStringArray2]),
                (simpleStringArray3Input, [respSimpleStringArray3]),
                (simpleStringPush3Input, [respSimpleStringPush3]),
                (simpleStringSet3Input, [respSimpleStringSet3]),
            ],
            decoderFactory: { RESPTokenDecoder() }
        )

        #expect(respEmptyArray.value == .array(.init(count: 0, buffer: .init())))
        #expect(
            respSimpleStringArray1.value == .array(.init(count: 1, buffer: .init(string: "+aaaabbbbcccc\r\n")))
        )
        #expect(
            respSimpleStringArray2.value == .array(.init(count: 2, buffer: .init(string: "+aaaa\r\n+bbbb\r\n")))
        )
        #expect(
            respSimpleStringArray3.value == .array(.init(count: 3, buffer: .init(string: "*0\r\n+a\r\n-b\r\n")))
        )
        #expect(respSimpleStringPush3.value == .push(.init(count: 3, buffer: .init(string: "*0\r\n+a\r\n-b\r\n"))))
        #expect(respSimpleStringSet3.value == .set(.init(count: 3, buffer: .init(string: "*0\r\n+a\r\n#t\r\n"))))

        #expect(respEmptyArray.testArray == [])
        #expect(respSimpleStringArray1.testArray == [.simpleString(.init(string: "aaaabbbbcccc"))])
        #expect(
            respSimpleStringArray2.testArray == [.simpleString(.init(string: "aaaa")), .simpleString(.init(string: "bbbb"))]
        )
        #expect(
            respSimpleStringArray3.testArray == [
                .array(.init(count: 0, buffer: .init())), .simpleString(.init(string: "a")),
                .simpleError(.init(string: "b")),
            ]
        )
        #expect(
            respSimpleStringPush3.testArray == [
                .array(.init(count: 0, buffer: .init())), .simpleString(.init(string: "a")),
                .simpleError(.init(string: "b")),
            ]
        )
        #expect(
            respSimpleStringSet3.testArray == [.array(.init(count: 0, buffer: .init())), .simpleString(.init(string: "a")), .boolean(true)]
        )
    }

    @Test(arguments: [
        ("*1\r\n", "*0\r\n"),
        (">1\r\n", ">0\r\n"),
        ("~1\r\n", "~0\r\n"),
        ("%1\r\n#t\r\n", "%0\r\n"),
        ("|1\r\n#t\r\n", "|0\r\n"),
    ])
    func testDeeplyNestedRESPCantStackOverflow(nested: String, final: String) throws {
        let tooDeeplyNested = String(repeating: nested, count: 100) + final
        var tooDeeplyNestedBuffer = ByteBuffer(string: tooDeeplyNested)

        let notDeepEnoughToThrow = String(repeating: nested, count: 99) + final
        var notDeepEnoughToThrowBuffer = ByteBuffer(string: notDeepEnoughToThrow)
        let notDeepEnoughToThrowExpected = RESPToken(validated: notDeepEnoughToThrowBuffer)

        #if true
        #expect {
            try RESPToken(consuming: &tooDeeplyNestedBuffer)
        } throws: { error in
            let error = try #require(error as? RESPParsingError)
            #expect(error.buffer == tooDeeplyNestedBuffer)
            #expect(error.code == .tooDeeplyNestedAggregatedTypes)
            return true
        }

        #expect(try RESPToken(consuming: &notDeepEnoughToThrowBuffer) == notDeepEnoughToThrowExpected)
        #else
        // this is very slow right now. Once we have faster decoding we should use this instead.
        try ByteToMessageDecoderVerifier.verifyDecoder(
            inputOutputPairs: [
                (buffer, [expected])
            ],
            decoderFactory: { RESPTokenDecoder() }
        )
        #endif
    }

    @Test
    func testMap() throws {
        let emptyMapInput = ByteBuffer(string: "%0\r\n")
        let respEmptyMap = RESPToken(validated: emptyMapInput)

        let simpleStringMap1Input = ByteBuffer(string: "%1\r\n+aaaa\r\n+bbbb\r\n")
        let respSimpleStringMap1 = RESPToken(validated: simpleStringMap1Input)

        let simpleStringAttributes1Input = ByteBuffer(string: "|1\r\n+aaaa\r\n#f\r\n")
        let respSimpleStringAttributes1 = RESPToken(validated: simpleStringAttributes1Input)

        try ByteToMessageDecoderVerifier.verifyDecoder(
            inputOutputPairs: [
                (emptyMapInput, [respEmptyMap]),
                (simpleStringMap1Input, [respSimpleStringMap1]),
                (simpleStringAttributes1Input, [respSimpleStringAttributes1]),
            ],
            decoderFactory: { RESPTokenDecoder() }
        )

        #expect(respEmptyMap.value == .map(.init(count: 0, buffer: .init())))
        #expect(respSimpleStringMap1.value == .map(.init(count: 1, buffer: .init(string: "+aaaa\r\n+bbbb\r\n"))))
        #expect(
            respSimpleStringAttributes1.value == .attribute(.init(count: 1, buffer: .init(string: "+aaaa\r\n#f\r\n")))
        )

        #expect(respEmptyMap.testDict == [:])
        #expect(
            respSimpleStringMap1.testDict == [.simpleString(.init(string: "aaaa")): .simpleString(.init(string: "bbbb"))]
        )
        #expect(respSimpleStringAttributes1.testDict == [.simpleString(.init(string: "aaaa")): .boolean(false)])
    }

    @Test
    func testArrayAsMap() throws {
        let array = RESPToken(
            .array([
                .bulkString("one"), .number(1), .bulkString("two"), .number(2), .bulkString("three"), .number(3), .bulkString("four"), .number(4),
            ])
        )
        guard case .array(let array) = array.value else { preconditionFailure() }
        let map = try array.asMap()
        var dictionary = [RESPToken.Value: RESPToken.Value]()
        dictionary.reserveCapacity(map.count)
        for (key, value) in map {
            dictionary[key.value] = value.value
        }

        #expect(
            dictionary == [
                .bulkString(.init(string: "one")): .number(1),
                .bulkString(.init(string: "two")): .number(2),
                .bulkString(.init(string: "three")): .number(3),
                .bulkString(.init(string: "four")): .number(4),
            ]
        )
    }
}

extension RESPToken {
    var testArray: [RESPToken.Value]? {
        switch value {
        case .array(let array), .push(let array), .set(let array):
            return [RESPToken.Value](array.map { $0.value })
        default:
            return nil
        }
    }

    var testDict: [RESPToken.Value: RESPToken.Value]? {
        switch value {
        case .map(let values), .attribute(let values):
            var result = [RESPToken.Value: RESPToken.Value]()
            result.reserveCapacity(values.count)
            for (key, value) in values {
                result[key.value] = value.value
            }
            return result
        default:
            return nil
        }
    }
}

@Suite("RESPToken.debugDescription")
struct DebugDescription {
    @Test
    func testNull() {
        let token = RESPToken(.null)
        #expect(token.value.debugDescription == ".null")
    }

    @Test
    func testSimpleString() {
        let token = RESPToken(.simpleString("test"))
        #expect(token.value.debugDescription == ".simpleString(\"***\")")
    }

    @Test
    func testBulkString() {
        let token = RESPToken(.bulkString("test"))
        #expect(token.value.debugDescription == ".bulkString(\"***\")")
    }

    @Test
    func testVerbatimString() {
        let token = RESPToken(.verbatimString("txt:test"))
        #expect(token.value.debugDescription == ".verbatimString(\"txt:***\")")
    }

    @Test
    func testBigNumber() {
        let token = RESPToken(.bigNumber("12345678"))
        #expect(token.value.debugDescription == ".bigNumber(\"***\")")
    }

    @Test
    func testSimpleError() {
        let token = RESPToken(.simpleError("test"))
        #expect(token.value.debugDescription == ".simpleError(\"test\")")
    }

    @Test
    func testBulkError() {
        let token = RESPToken(.bulkError("test"))
        #expect(token.value.debugDescription == ".bulkError(\"test\")")
    }

    @Test
    func testNumber() {
        let token = RESPToken(.number(1234))
        #expect(token.value.debugDescription == ".number(1234)")
    }

    @Test
    func testDouble() {
        let token = RESPToken(.double(1234.5))
        #expect(token.value.debugDescription == ".double(1234.5)")
    }

    @Test
    func testBoolean() {
        let token = RESPToken(.boolean(true))
        #expect(token.value.debugDescription == ".boolean(true)")
    }

    @Test
    func testArray() {
        let token = RESPToken(.array([.bulkString("1"), .number(2), .bulkString("3")]))
        #expect(
            token.value.debugDescription == """
                .array([
                  .bulkString("***"),
                  .number(2),
                  .bulkString("***")
                ])
                """
        )
    }

    @Test
    func testSet() {
        let token = RESPToken(.set([.bulkString("1"), .number(2), .bulkString("3")]))
        #expect(
            token.value.debugDescription == """
                .set([
                  .bulkString("***"),
                  .number(2),
                  .bulkString("***")
                ])
                """
        )
    }

    @Test
    func testMap() {
        let token = RESPToken(
            .map([
                .bulkString("1"): .number(1),
                .bulkString("2"): .number(2),
            ])
        )
        #expect(
            token.value.debugDescription == """
                .map([
                  .bulkString("1"): .number(1),
                  .bulkString("2"): .number(2)
                ])
                """
                || token.value.debugDescription == """
                    .map([
                      .bulkString("2"): .number(2),
                      .bulkString("1"): .number(1)
                    ])
                    """
        )
    }

    @Test
    func testAttributes() {
        let token = RESPToken(
            .attribute([
                .bulkString("1"): .number(1),
                .bulkString("2"): .number(2),
            ])
        )
        #expect(
            token.value.debugDescription == """
                .attribute([
                  .bulkString("1"): .number(1),
                  .bulkString("2"): .number(2)
                ])
                """
                || token.value.debugDescription == """
                    .attribute([
                      .bulkString("2"): .number(2),
                      .bulkString("1"): .number(1)
                    ])
                    """
        )
    }

    @Test
    func testPushToken() {
        let token = RESPToken(.push([.bulkString("SUBSCRIBE"), .bulkString("test"), .bulkString("3")]))
        #expect(
            token.value.debugDescription == """
                .push([
                  .bulkString("***"),
                  .bulkString("***"),
                  .bulkString("***")
                ])
                """
        )
    }
}
