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
                        let rt = try #require(try await client.lmove(source: key, destination: key2, wherefrom: .right, whereto: .left))
                        let value = String(rt)
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
    func testGEOSEARCH() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            try await withKey(connection: client) { key in
                let count = try await client.geoadd(
                    key,
                    data: [.init(longitude: 1.0, latitude: 53.0, member: "Edinburgh"), .init(longitude: 1.4, latitude: 53.5, member: "Glasgow")]
                )
                #expect(count == 2)
                let geoSearchEntries = try await client.geosearch(
                    key,
                    from: .fromlonlat(.init(longitude: 0.0, latitude: 53.0)),
                    by: .circle(.init(radius: 10000, unit: .mi)),
                    withcoord: true,
                    withdist: true,
                    withhash: true
                )

                for entry in try geoSearchEntries.get(options: [.withDist, .withHash, .withCoord]) {
                    #expect(!entry.member.isEmpty)
                    #expect(entry.distance != nil && entry.distance! > 0)
                    #expect(entry.hash != nil && entry.hash! > 0)
                    #expect(entry.coordinates != nil)
                    #expect(entry.coordinates!.latitude > 0)
                    #expect(entry.coordinates!.longitude > 0)
                }
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

                    redis.register_function('valkey_swift_test_set', test_set)
                    redis.register_function('valkey_swift_test_get', test_get)
                    """
            )
            let list = try await client.functionList(libraryNamePattern: "_valkey_swift_tests", withcode: true)
            let library = try #require(list.first)
            #expect(library.libraryName == "_valkey_swift_tests")
            #expect(library.engine == "LUA")
            #expect(library.libraryCode?.hasPrefix("#!lua name=_valkey_swift_tests") == true)
            #expect(library.functions.count == 2)
            #expect(library.functions.contains { $0.name == "valkey_swift_test_set" })
            #expect(library.functions.contains { $0.name == "valkey_swift_test_get" })

            try await client.functionDelete(libraryName: "_valkey_swift_tests")
        }
    }

    @available(valkeySwift 1.0, *)
    @Test
    func testSCRIPTfunctions() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .trace
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            let helloResponse = try await client.hello()
            let serverNameValue = try #require(helloResponse.first { $0.key.value == .bulkString(ByteBuffer(string: "server")) }?.value.value)
            let serverName: String? =
                if case .bulkString(let nameBuffer) = serverNameValue {
                    String(buffer: nameBuffer)
                } else {
                    nil
                }
            guard serverName == "valkey" else { return }

            let sha1 = try await client.scriptLoad(
                script: "return redis.call(\"GET\", KEYS[1])"
            )
            let script = try await client.scriptShow(sha1: sha1)
            #expect(script == "return redis.call(\"GET\", KEYS[1])")
            _ = try await client.scriptExists(sha1s: [sha1])
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func testHrandfield() async throws {
        var logger = Logger(label: "Valkey")
        logger.logLevel = .debug
        try await withValkeyClient(.hostname(valkeyHostname, port: 6379), logger: logger) { client in
            try await withKey(connection: client) { key in

                // Non-existent hash
                var response = try await client.hrandfield(key)
                var singleField = try response.singleField()
                #expect(singleField == nil)
                var multipleFields = try response.multipleFields()
                #expect(multipleFields == nil)
                var fieldValuePairs = try response.multipleFieldsWithValues()
                #expect(fieldValuePairs == nil)

                // Hash with multiple fields
                _ = try await client.hset(
                    key,
                    data: [
                        HSET.Data(field: "field1", value: "value1"),
                        HSET.Data(field: "field2", value: "value2"),
                        HSET.Data(field: "field3", value: "value3"),
                    ]
                )

                // Get Single Field
                response = try await client.hrandfield(key)
                singleField = try response.singleField()
                #expect(singleField != nil)
                let fieldName = String(singleField!)
                #expect(["field1", "field2", "field3"].contains(fieldName))

                // Get multiple fields
                var options = HRANDFIELD.Options(count: 2, withvalues: false)
                response = try await client.hrandfield(key, options: options)
                multipleFields = try response.multipleFields()
                #expect(multipleFields != nil)
                if let unwrappedFields = multipleFields {
                    #expect(unwrappedFields.count == 2)
                    let fieldNames = unwrappedFields.map { String($0) }
                    for fieldName in fieldNames {
                        #expect(["field1", "field2", "field3"].contains(fieldName))
                    }
                    // Ensure we got unique fields
                    let uniqueFieldNames = Set(fieldNames)
                    #expect(uniqueFieldNames.count == fieldNames.count)
                }

                // Get multiple fields with values
                options = HRANDFIELD.Options(count: 3, withvalues: true)
                response = try await client.hrandfield(key, options: options)
                fieldValuePairs = try response.multipleFieldsWithValues()
                #expect(fieldValuePairs != nil)
                if let unwrappedFieldValuePairs = fieldValuePairs {
                    #expect(unwrappedFieldValuePairs.count == 3)
                    var expectedPairs: [String: String] = [:]
                    for pair in unwrappedFieldValuePairs {
                        expectedPairs[String(pair.field)] = String(pair.value)
                    }
                    #expect(expectedPairs["field1"] == "value1")
                    #expect(expectedPairs["field2"] == "value2")
                    #expect(expectedPairs["field3"] == "value3")
                }
            }
        }
    }

}
