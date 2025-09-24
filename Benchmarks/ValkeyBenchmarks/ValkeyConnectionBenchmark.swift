//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import Benchmark
import Foundation
import Logging
import NIOCore
import NIOPosix
import Synchronization
import Valkey

#if DistributedTracingSupport
import Tracing
#endif

@available(valkeySwift 1.0, *)
func connectionBenchmarks() {
    makeConnectionCreateAndDropBenchmark()
    makeConnectionGETBenchmark()
    #if DistributedTracingSupport
    makeConnectionGETNoOpTracerBenchmark()
    #endif
    makeConnectionPipelineBenchmark()
    makeConnectionPipelineArrayExistentialsBenchmark()
}

@available(valkeySwift 1.0, *)
@discardableResult
func makeConnectionCreateAndDropBenchmark() -> Benchmark? {
    let serverMutex = Mutex<(any Channel)?>(nil)

    // don't run this benchmark in CI it is too erratic
    guard ProcessInfo.processInfo.environment["CI"] == nil else { return nil }

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
        #if DistributedTracingSupport
        // explicitly set tracer to nil, if trait is enabled
        var configuration = ValkeyConnectionConfiguration()
        configuration.tracing.tracer = nil
        #else
        let configuration = ValkeyConnectionConfiguration()
        #endif
        try await ValkeyConnection.withConnection(
            address: .hostname("127.0.0.1", port: port),
            configuration: configuration,
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

#if DistributedTracingSupport
@available(valkeySwift 1.0, *)
@discardableResult
func makeConnectionGETNoOpTracerBenchmark() -> Benchmark? {
    let serverMutex = Mutex<(any Channel)?>(nil)

    return Benchmark("Connection: GET benchmark – NoOpTracer", configuration: .init(metrics: defaultMetrics, scalingFactor: .kilo)) { benchmark in
        let port = serverMutex.withLock { $0 }!.localAddress!.port!
        let logger = Logger(label: "test")
        var configuration = ValkeyConnectionConfiguration()
        configuration.tracing.tracer = NoOpTracer()
        try await ValkeyConnection.withConnection(
            address: .hostname("127.0.0.1", port: port),
            configuration: configuration,
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
#endif

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

@available(valkeySwift 1.0, *)
@discardableResult
func makeConnectionPipelineArrayExistentialsBenchmark() -> Benchmark? {
    let serverMutex = Mutex<(any Channel)?>(nil)

    return Benchmark("Connection: Pipeline array benchmark", configuration: .init(metrics: defaultMetrics, scalingFactor: .kilo)) { benchmark in
        let port = serverMutex.withLock { $0 }!.localAddress!.port!
        let logger = Logger(label: "test")
        try await ValkeyConnection.withConnection(
            address: .hostname("127.0.0.1", port: port),
            configuration: .init(),
            logger: logger
        ) { connection in
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                let commands: [any ValkeyCommand] = .init(repeating: GET("foo"), count: 3)
                let foo = await connection.execute(commands)
                let result = try foo[2].get().decode(as: String.self)
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
