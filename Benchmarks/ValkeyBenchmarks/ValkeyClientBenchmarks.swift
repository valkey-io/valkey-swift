//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of valkey-swift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Benchmark
import Logging
import NIOCore
import NIOPosix
import Synchronization
import Valkey

@available(valkeySwift 1.0, *)
func clientBenchmarks() {
    makeClientGETSequentialBenchmark()
    makeClient20ConcurrentGETBenchmark()
    makeClient50Concurrent20ConnectionGETBenchmark()
}

@available(valkeySwift 1.0, *)
@discardableResult
func makeClientGETSequentialBenchmark() -> Benchmark? {
    let serverMutex = Mutex<(any Channel)?>(nil)

    return Benchmark("Client: GET benchmark", configuration: .init(metrics: defaultMetrics, scalingFactor: .kilo)) { benchmark in
        let port = serverMutex.withLock { $0 }!.localAddress!.port!
        let logger = Logger(label: "test")
        let client = ValkeyClient(.hostname("127.0.0.1", port: port), logger: logger)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                await client.run()
            }
            await Task.yield()

            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                let foo = try await client.get("foo")
                precondition(foo.map { String(buffer: $0) } == "Bar")
            }
            benchmark.stopMeasurement()

            group.cancelAll()
        }
    } setup: {
        let server = try await makeLocalServer()
        serverMutex.withLock { $0 = server }
    } teardown: {
        try await serverMutex.withLock { $0 }?.close().get()
    }
}

@available(valkeySwift 1.0, *)
@discardableResult
func makeClient20ConcurrentGETBenchmark() -> Benchmark? {
    let serverMutex = Mutex<(any Channel)?>(nil)

    let concurrency = 20
    return Benchmark(
        "Client: GET benchmark | parallel 20 | 20 concurrent connections",
        configuration: .init(metrics: defaultMetrics, scalingFactor: .kilo)
    ) { benchmark in
        let port = serverMutex.withLock { $0 }!.localAddress!.port!
        let logger = Logger(label: "test")
        let client = ValkeyClient(
            .hostname("127.0.0.1", port: port),
            configuration: .init(connectionPool: .init(minimumConnectionCount: 0, maximumConnectionCount: 20)),
            logger: logger
        )

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                await client.run()
            }
            await Task.yield()

            let iterationsPerConnection = benchmark.scaledIterations.upperBound / concurrency

            benchmark.startMeasurement()
            for _ in 0..<concurrency {
                group.addTask {
                    for _ in 0..<iterationsPerConnection {
                        let foo = try await client.get("foo")
                        precondition(foo.map { String(buffer: $0) } == "Bar")
                    }
                }
            }

            for _ in 0..<concurrency {
                _ = try await group.next()!
            }
            benchmark.stopMeasurement()

            group.cancelAll()
        }
    } setup: {
        let server = try await makeLocalServer()
        serverMutex.withLock { $0 = server }
    } teardown: {
        try await serverMutex.withLock { $0 }?.close().get()
    }
}

@available(valkeySwift 1.0, *)
@discardableResult
func makeClient50Concurrent20ConnectionGETBenchmark() -> Benchmark? {
    let serverMutex = Mutex<(any Channel)?>(nil)

    let concurrency = 50
    return Benchmark(
        "Client: GET benchmark | parallel 50 | 20 concurrent connections",
        configuration: .init(metrics: defaultMetrics, scalingFactor: .kilo)
    ) { benchmark in
        let port = serverMutex.withLock { $0 }!.localAddress!.port!
        let logger = Logger(label: "test")
        let client = ValkeyClient(
            .hostname("127.0.0.1", port: port),
            configuration: .init(connectionPool: .init(minimumConnectionCount: 0, maximumConnectionCount: 20)),
            logger: logger
        )

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                await client.run()
            }
            await Task.yield()

            let iterationsPerConnection = benchmark.scaledIterations.upperBound / concurrency

            benchmark.startMeasurement()
            for _ in 0..<concurrency {
                group.addTask {
                    for _ in 0..<iterationsPerConnection {
                        let foo = try await client.get("foo")
                        precondition(foo.map { String(buffer: $0) } == "Bar")
                    }
                }
            }

            for _ in 0..<concurrency {
                _ = try await group.next()!
            }
            benchmark.stopMeasurement()

            group.cancelAll()
        }
    } setup: {
        let server = try await makeLocalServer()
        serverMutex.withLock { $0 = server }
    } teardown: {
        try await serverMutex.withLock { $0 }?.close().get()
    }
}
