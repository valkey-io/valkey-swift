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
import Foundation
import Logging
import NIOCore
import NIOPosix
import Valkey

let benchmarks: @Sendable () -> Void = {
    if #available(valkeySwift 1.0, *) {
        connectionBenchmarks()

        clientBenchmarks()

        Benchmark("ValkeyCommandEncoder – Simple GET", configuration: .init(metrics: defaultMetrics, scalingFactor: .kilo)) { benchmark in
            let command = GET("foo")
            benchmark.startMeasurement()

            var encoder = ValkeyCommandEncoder()
            for _ in benchmark.scaledIterations {
                encoder.reset()
                command.encode(into: &encoder)
            }

            benchmark.stopMeasurement()
        }

        Benchmark("ValkeyCommandEncoder – Simple MGET 15 keys", configuration: .init(metrics: defaultMetrics, scalingFactor: .kilo)) { benchmark in
            let keys = (0..<15).map { ValkeyKey("foo-\($0)") }
            let command = MGET(keys: keys)
            benchmark.startMeasurement()

            var encoder = ValkeyCommandEncoder()
            for _ in benchmark.scaledIterations {
                encoder.reset()
                command.encode(into: &encoder)
            }

            benchmark.stopMeasurement()
        }

        Benchmark("ValkeyCommandEncoder – Command with 7 words", configuration: .init(metrics: defaultMetrics, scalingFactor: .kilo)) { benchmark in
            let string = "string"
            let optionalString: String? = "optionalString"
            let array = ["array", "of", "strings"]
            let number = 456
            let token = RESPPureToken("TOKEN", true)
            benchmark.startMeasurement()

            var encoder = ValkeyCommandEncoder()
            for _ in benchmark.scaledIterations {
                encoder.reset()
                encoder.encodeArray(string, optionalString, array, number, token)
            }

            benchmark.stopMeasurement()
        }

        Benchmark("HashSlot – {user}.whatever", configuration: .init(metrics: defaultMetrics, scalingFactor: .mega)) { benchmark in
            let key: ValkeyKey = "{user}.whatever"
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                blackHole(HashSlot(key: key))
            }
        }
    }
}
