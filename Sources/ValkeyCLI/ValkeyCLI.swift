//
// This source file is part of the valkey-swift project
// Copyright (c) 2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
import Logging
import Valkey

#if canImport(Darwin)
import Darwin
#elseif os(Windows)
import ucrt
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#else
#error("Platform not supported")
#endif

@main
struct App {
    static func usage() -> Never {
        print("ValkeyCLI <host/ip> <port>")
        exit(-1)
    }

    static func main() async throws {
        let arguments = CommandLine.arguments
        guard arguments.count > 2 else { usage() }
        guard let port = Int(arguments[2]) else { usage() }
        print("Connecting to \(arguments[1]):\(port)")
        let valkeyClient = ValkeyClient(.hostname(arguments[1], port: port), logger: Logger(label: "ValkeyCLI"))
        async let _ = valkeyClient.run()
        while true {
            print("> ", terminator: "")
            guard let input = readLine() else {
                print("")
                return
            }
            let split = input.split(separator: " ")
            guard let commandName = split.first else { continue }
            let command = ValkeyRawCommand(String(commandName), parameters: split.dropFirst().map { String($0) })
            do {
                let response = try await valkeyClient.execute(command)
                print(response.value.descriptionWith(redact: false))
            } catch {
                if error.errorCode == .commandError {
                    print(error.message ?? "Unknown Error")
                } else {
                    throw error
                }
            }
        }
    }
}

/// Wrapper for Valkey command that returns the response as a `RESPToken`
@usableFromInline
struct ValkeyRawCommand: ValkeyCommand {
    @usableFromInline
    let command: String
    @usableFromInline
    let parameters: [String]

    @inlinable
    static var name: String { "RAW" }

    @inlinable
    init(_ command: String, parameters: [String]) {
        self.command = command
        self.parameters = parameters
    }

    @usableFromInline
    var keysAffected: [ValkeyKey] { [] }

    @inlinable
    func encode(into commandEncoder: inout ValkeyCommandEncoder) {
        commandEncoder.encodeArray(command, parameters)
    }
}
