//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore
import Testing

@testable import Valkey

struct RESPTokenRenderableTests {
    @Test
    func testRESPPureToken() async throws {
        var commandEncoder = ValkeyCommandEncoder()
        RESPPureToken("TEST", false).encode(into: &commandEncoder)
        #expect(commandEncoder.buffer == ByteBuffer(string: ""))

        commandEncoder.reset()
        RESPPureToken("TEST", true).encode(into: &commandEncoder)
        #expect(commandEncoder.buffer == RESPToken(.bulkString("TEST")).base)
    }

    @Test
    func testRESPWithToken() async throws {
        var commandEncoder = ValkeyCommandEncoder()
        var commandEncoder2 = ValkeyCommandEncoder()
        RESPWithToken("TEST", 5).encode(into: &commandEncoder)
        "TEST".encode(into: &commandEncoder2)
        5.encode(into: &commandEncoder2)
        #expect(commandEncoder.buffer == commandEncoder2.buffer)

        commandEncoder.reset()
        RESPWithToken("TEST", Int?(nil)).encode(into: &commandEncoder)
        #expect(commandEncoder.buffer.readableBytes == 0)
        RESPWithToken("TEST", [Int]()).encode(into: &commandEncoder)
        #expect(commandEncoder.buffer.readableBytes == 0)
    }

    @Test
    func testRESPArrayWithCount() async throws {
        var commandEncoder = ValkeyCommandEncoder()
        var commandEncoder2 = ValkeyCommandEncoder()
        RESPArrayWithCount(["john", "jane"]).encode(into: &commandEncoder)
        2.encode(into: &commandEncoder2)
        "john".encode(into: &commandEncoder2)
        "jane".encode(into: &commandEncoder2)
        #expect(commandEncoder.buffer == commandEncoder2.buffer)

        commandEncoder.reset()
        commandEncoder2.reset()
        RESPArrayWithCount([String]()).encode(into: &commandEncoder)
        0.encode(into: &commandEncoder2)
        #expect(commandEncoder.buffer == commandEncoder2.buffer)
    }
}
