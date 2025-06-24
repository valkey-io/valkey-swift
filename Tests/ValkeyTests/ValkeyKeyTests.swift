//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 Apple Inc. and the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of valkey-swift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore
import Testing
import Valkey

struct ValkeyKeyTests {
    @Test
    func testValkeyString() {
        let key = ValkeyKey("TestString")
        let valkeyKeyString = String(valkeyKey: key)
        #expect(key == "TestString")
        #expect("TestString" == key)
        #expect(valkeyKeyString == "TestString")
    }

    @Test
    func testValkeyByteBuffer() {
        let buffer = ByteBuffer(repeating: 1, count: 16)
        let key = ValkeyKey(buffer)
        let valkeyKeyByteBuffer = ByteBuffer(valkeyKey: key)
        #expect(buffer == valkeyKeyByteBuffer)
    }

    @Test
    func testValkeyStringAndByteBufferAreEqual() {
        let string = "TestString"
        let buffer = ByteBuffer(string: string)

        let key1 = ValkeyKey(string)
        let key2 = ValkeyKey(buffer)
        #expect(key1 == key2)
        #expect(key2 == key1)
    }

}
