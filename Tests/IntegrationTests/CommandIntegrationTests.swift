//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
import Logging
import NIOCore
import Testing
import Valkey

@testable import Valkey

@Suite("Command Integration Tests")
struct CommandIntegratedTests {
    let valkeyHostname = ProcessInfo.processInfo.environment["VALKEY_HOSTNAME"] ?? "localhost"

    @available(valkeySwift 1.0, *)
    func withKey<Value>(connection: some ValkeyClientProtocol, _ operation: (ValkeyKey) async throws -> Value) async throws -> Value {
        let key = ValkeyKey(UUID().uuidString)
        let value: Value
        do {
            value = try await operation(key)
        } catch {
            _ = try? await connection.del(keys: [key])
            throw error
        }
        _ = try await connection.del(keys: [key])
        return value
    }

    @available(valkeySwift 1.0, *)
    func withValkeyClient(
        _ address: ValkeyServerAddress,
        configuration: ValkeyClientConfiguration = .init(),
        logger: Logger,
        operation: @escaping @Sendable (ValkeyClient) async throws -> Void
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            let client = ValkeyClient(address, configuration: configuration, logger: logger)
            group.addTask {
                await client.run()
            }
            group.addTask {
                try await operation(client)
            }
            try await group.next()
            group.cancelAll()
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testRole() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            let role = try await client.role()
            switch role {
            case .primary:
                break
            case .replica, .sentinel:
                Issue.record()
            }
        }
    }

    @available(valkeySwift 1.0, *)
    @Test("Array with count using LMPOP")
    func testArrayWithCount() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            try await withKey(connection: client) { key in
                try await withKey(connection: client) { key2 in
                    try await client.lpush(key, elements: ["a"])
                    try await client.lpush(key2, elements: ["b"])
                    try await client.lpush(key2, elements: ["c"])
                    try await client.lpush(key2, elements: ["d"])
                    let rt1 = try await client.lmpop(keys: [key, key2], where: .right)
                    let (element) = try rt1?.values.decodeElements(as: (String).self)
                    #expect(rt1?.key == key)
                    #expect(element == "a")
                    let rt2 = try await client.lmpop(keys: [key, key2], where: .right)
                    let elements2 = try rt2?.values.decode(as: [String].self)
                    #expect(rt2?.key == key2)
                    #expect(elements2 == ["b"])
                    let rt3 = try await client.lmpop(keys: [key, key2], where: .right, count: 2)
                    let elements3 = try rt3?.values.decode(as: [String].self)
                    #expect(rt3?.key == key2)
                    #expect(elements3 == ["c", "d"])
                }
            }
        }
    }

    @available(valkeySwift 1.0, *)
    @Test
    func testLMOVE() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            try await withKey(connection: client) { key in
                try await withKey(connection: client) { key2 in
                    let rtEmpty = try await client.lmove(source: key, destination: key2, wherefrom: .right, whereto: .left)
                    #expect(rtEmpty == nil)
                    try await client.lpush(key, elements: ["a"])
                    try await client.lpush(key, elements: ["b"])
                    try await client.lpush(key, elements: ["c"])
                    try await client.lpush(key, elements: ["d"])
                    let list1Before = try await client.lrange(key, start: 0, stop: -1).decode(as: [String].self)
                    #expect(list1Before == ["d", "c", "b", "a"])
                    let list2Before = try await client.lrange(key2, start: 0, stop: -1).decode(as: [String].self)
                    #expect(list2Before == [])
                    for expectedValue in ["a", "b", "c", "d"] {
                        var rt = try #require(try await client.lmove(source: key, destination: key2, wherefrom: .right, whereto: .left))
                        let value = rt.readString(length: 1)
                        #expect(value == expectedValue)
                    }
                    let list1After = try await client.lrange(key, start: 0, stop: -1).decode(as: [String].self)
                    #expect(list1After == [])
                    let list2After = try await client.lrange(key2, start: 0, stop: -1).decode(as: [String].self)
                    #expect(list2After == ["d", "c", "b", "a"])
                }
            }
        }
    }

    @available(valkeySwift 1.0, *)
    @Test
    func testGEOPOS() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            try await withKey(connection: client) { key in
                let count = try await client.geoadd(
                    key,
                    data: [.init(longitude: 1.0, latitude: 53.0, member: "Edinburgh"), .init(longitude: 1.4, latitude: 53.5, member: "Glasgow")]
                )
                #expect(count == 2)
                let search = try await client.geosearch(
                    key,
                    from: .fromlonlat(.init(longitude: 0.0, latitude: 53.0)),
                    by: .circle(.init(radius: 10000, unit: .mi)),
                    withcoord: true,
                    withdist: true,
                    withhash: true
                )
                print(search.map { $0.member })
                try print(search.map { try $0.attributes[0].decode(as: Double.self) })
                try print(search.map { try $0.attributes[1].decode(as: String.self) })
                try print(search.map { try $0.attributes[2].decode(as: GeoCoordinates.self) })
            }
        }
    }

    @available(valkeySwift 1.0, *)
    @Test
    func testFUNCTIONLIST() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            try await client.functionLoad(
                replace: true,
                functionCode: """
                    #!lua name=_valkey_swift_tests

                    local function test_get(keys, args)
                        return redis.call("GET", keys[1])
                    end

                    local function test_set(keys, args)
                        return redis.call("SET", keys[1], args[1])
                    end

                    server.register_function('valkey_swift_test_set', test_set)
                    server.register_function('valkey_swift_test_get', test_get)
                    """
            )
            let list = try await client.functionList(libraryNamePattern: "_valkey_swift_tests", withcode: true)
            let library = try #require(list.first)
            #expect(library.libraryName == "_valkey_swift_tests")
            #expect(library.engine == "LUA")
            #expect(library.libraryCode?.hasPrefix("#!lua name=_valkey_swift_tests") == true)
            #expect(library.functions.count == 2)
            #expect(library.functions[0].name == "valkey_swift_test_set")
            #expect(library.functions[1].name == "valkey_swift_test_get")

            try await client.functionDelete(libraryName: "_valkey_swift_tests")
        }
    }

    @available(valkeySwift 1.0, *)
    @Test
    func testSCRIPTfunctions() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            let sha1 = try await client.scriptLoad(
                script: "return redis.call(\"GET\", KEYS[1])"
            )
            let script = try await client.scriptShow(sha1: sha1)
            #expect(script == "return redis.call(\"GET\", KEYS[1])")
            _ = try await client.scriptExists(sha1s: [sha1])
        }
    }
}
