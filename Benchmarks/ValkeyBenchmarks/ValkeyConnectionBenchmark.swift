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
func connectionBenchmarks() {
    makeConnectionCreateAndDropBenchmark()
    makeConnectionGETBenchmark()
    makeConnectionPipelineBenchmark()
}

@available(valkeySwift 1.0, *)
@discardableResult
func makeConnectionCreateAndDropBenchmark() -> Benchmark? {
    let serverMutex = Mutex<(any Channel)?>(nil)

    return Benchmark("Connection: Create and drop benchmark", configuration: .init(metrics: defaultMetrics, scalingFactor: .kilo)) { benchmark in
        let port = serverMutex.withLock { $0 }!.localAddress!.port!
        let logger = Logger(label: "test")
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            try await ValkeyConnection.withConnection(
                address: .hostname("127.0.0.1", port: port),
                configuration: .init(),
                logger: logger
            ) { _ in
            }
        }
        benchmark.stopMeasurement()
    } setup: {
        let server = try await makeLocalServer()
        serverMutex.withLock { $0 = server }
    } teardown: {
        try await serverMutex.withLock { $0 }?.close().get()
    }
}

@available(valkeySwift 1.0, *)
@discardableResult
func makeConnectionGETBenchmark() -> Benchmark? {
    let serverMutex = Mutex<(any Channel)?>(nil)

    return Benchmark("Connection: GET benchmark", configuration: .init(metrics: defaultMetrics, scalingFactor: .kilo)) { benchmark in
        let port = serverMutex.withLock { $0 }!.localAddress!.port!
        let logger = Logger(label: "test")
        try await ValkeyConnection.withConnection(
            address: .hostname("127.0.0.1", port: port),
            configuration: .init(),
            logger: logger
        ) { connection in
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                let foo = try await connection.get("foo")
                precondition(foo.map { String(buffer: $0) } == "Bar")
            }
            benchmark.stopMeasurement()
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
func makeConnectionPipelineBenchmark() -> Benchmark? {
    let serverMutex = Mutex<(any Channel)?>(nil)

    return Benchmark("Connection: Pipeline benchmark", configuration: .init(metrics: defaultMetrics, scalingFactor: .kilo)) { benchmark in
        let port = serverMutex.withLock { $0 }!.localAddress!.port!
        let logger = Logger(label: "test")
        try await ValkeyConnection.withConnection(
            address: .hostname("127.0.0.1", port: port),
            configuration: .init(),
            logger: logger
        ) { connection in
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                let foo = await connection.execute(
                    GET("foo"),
                    GET("foo"),
                    GET("foo")
                )
                let result = try foo.2.get().map { String(buffer: $0) }
                precondition(result == "Bar")
            }
            benchmark.stopMeasurement()
        }
    } setup: {
        let server = try await makeLocalServer()
        serverMutex.withLock { $0 = server }
    } teardown: {
        try await serverMutex.withLock { $0 }?.close().get()
    }
}
