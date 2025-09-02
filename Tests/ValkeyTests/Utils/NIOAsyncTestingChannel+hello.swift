//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import NIOCore
import NIOEmbedded
import Testing

@testable import Valkey

extension NIOAsyncTestingChannel {
    func processHello() async throws {
        let hello = try await self.waitForOutboundWrite(as: ByteBuffer.self)
        var expectedBuffer = ByteBuffer()
        expectedBuffer.writeImmutableBuffer(RESPToken(.array([.bulkString("HELLO"), .bulkString("3")])).base)
        expectedBuffer.writeImmutableBuffer(
            RESPToken(.array([.bulkString("CLIENT"), .bulkString("SETINFO"), .bulkString("lib-name"), .bulkString(valkeySwiftLibraryName)])).base
        )
        expectedBuffer.writeImmutableBuffer(
            RESPToken(.array([.bulkString("CLIENT"), .bulkString("SETINFO"), .bulkString("lib-ver"), .bulkString(valkeySwiftLibraryVersion)])).base
        )
        #expect(hello == expectedBuffer)
        try await self.writeInbound(
            RESPToken(
                .map([
                    .bulkString("server"): .bulkString("valkey"),
                    .bulkString("version"): .bulkString("8.0.2"),
                    .bulkString("proto"): .number(3),
                    .bulkString("id"): .number(1117),
                    .bulkString("mode"): .bulkString("standalone"),
                    .bulkString("role"): .bulkString("master"),
                    .bulkString("modules"): .array([]),
                ])
            ).base
        )
        try await self.writeInbound(RESPToken.ok.base)
        try await self.writeInbound(RESPToken.ok.base)
    }
}
