//===----------------------------------------------------------------------===//
//
// This source file is part of the RediStack open source project
//
// Copyright (c) 2023 the RediStack project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of RediStack project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// This is a derived version from:
// https://github.com/swift-server/RediStack/blob/2df32390e2366b58cc15c2612bb324b3fc37a190/Tests/RediStackTests/RedisHashSlotTests.swift

//===----------------------------------------------------------------------===//
//
// This source file is part of the RediStack open source project
//
// Copyright (c) 2023 the RediStack project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of RediStack project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Testing
import Valkey
import Foundation

@Suite
struct HashSlotTests {

    @Test
    func computesHashSlot() {
        #expect(HashSlot(key: "foo") == 12182)
        
    }

    @Test
    func edgeValues() {
        #expect(HashSlot.min.rawValue == 0)
        #expect(HashSlot.max.rawValue == UInt16(pow(2.0, 14.0)) - 1)
        #expect(HashSlot.unknown.rawValue == UInt16.max)
    }

    @Test
    func isExpressibleByIntegerLiteral() {
        let value: HashSlot = 123
        #expect(value.rawValue == 123)
    }

    @Test
    func isStridable() {
        let value: HashSlot = 123
        #expect(value.advanced(by: 12) == 135)
    }

    @Test
    func isComparable() {
        let value: HashSlot = 123
        #expect(value.advanced(by: 1) > value)
        #expect(value.advanced(by: -1) < value)
    }

    @Test
    func crc16() {
        #expect(HashSlot.crc16("123456789".utf8) == 0x31C3)

        // test cases generated here: https://crccalc.com
        #expect(HashSlot.crc16("Peter".utf8) == 0x5E67)
        #expect(HashSlot.crc16("Fabian".utf8) == 0x504F)
        #expect(HashSlot.crc16("Inverness".utf8) == 0x7619)
        #expect(HashSlot.crc16("Redis is awesome".utf8) == 0x345C)
        #expect(HashSlot.crc16([0xFF, 0xFF, 0x00, 0x00]) == 0x84C0)
        #expect(HashSlot.crc16([0x00, 0x00]) == 0x0000)
    }

    @Test
    func hashTagComputation() {
        #expect(
            HashSlot.hashTag(forKey: "{user1000}.following").elementsEqual(
                HashSlot.hashTag(forKey: "{user1000}.followers")
            )
        )
        #expect(HashSlot.hashTag(forKey: "{user1000}.following").elementsEqual("user1000".utf8))
        #expect(HashSlot.hashTag(forKey: "{user1000}.followers").elementsEqual("user1000".utf8))

        #expect(HashSlot.hashTag(forKey: "foo{}{bar}").elementsEqual("foo{}{bar}".utf8))
        #expect(HashSlot.hashTag(forKey: "foo{{bar}}zap").elementsEqual("{bar".utf8))
        #expect(HashSlot.hashTag(forKey: "foo{bar}{zap}").elementsEqual("bar".utf8))
        #expect(HashSlot.hashTag(forKey: "{}foo{bar}{zap}").elementsEqual("{}foo{bar}{zap}".utf8))
        #expect(HashSlot.hashTag(forKey: "foo").elementsEqual("foo".utf8))
        #expect(HashSlot.hashTag(forKey: "foo}").elementsEqual("foo}".utf8))
        #expect(HashSlot.hashTag(forKey: "{foo}").elementsEqual("foo".utf8))
        #expect(HashSlot.hashTag(forKey: "bar{foo}").elementsEqual("foo".utf8))
        #expect(HashSlot.hashTag(forKey: "bar{}").elementsEqual("bar{}".utf8))
        #expect(HashSlot.hashTag(forKey: "{}").elementsEqual("{}".utf8))
        #expect(HashSlot.hashTag(forKey: "{}bar").elementsEqual("{}bar".utf8))
    }

    @Test
    func description() {
        #expect("\(HashSlot.min)" == "0")
        #expect("\(HashSlot.max)" == "16383")
        #expect("\(HashSlot.unknown)" == "unknown")
        #expect("\(HashSlot(rawValue: 3000)!)" == "3000")
        #expect("\(HashSlot(rawValue: 20)!)" == "20")
    }
}
