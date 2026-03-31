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

@available(valkeySwift 1.0, *)
@main
struct App {
    static func usage() -> Never {
        print("Usage: ValkeyCLI <host/ip>:<port>")
        exit(-1)
    }

    static func main() async throws {
        let (host, port) = getHostAndPort()
        print("Connecting to \(host):\(port)")
        let valkeyClient = ValkeyClient(
            .hostname(host, port: port),
            configuration: .init(connectionPool: .init(circuitBreakerTripAfter: .seconds(5))),
            logger: Logger(label: "ValkeyCLI")
        )
        async let _ = valkeyClient.run()

        // check we can connect to the valkey database
        do {
            try await valkeyClient.ping()
        } catch {
            print("Failed to connect.")
            return
        }
        while true {
            print("> ", terminator: "")
            guard let input = readLine() else {
                print("")
                return
            }
            let split = input.splitWithSpeechMarks(separator: " ")
            guard let commandName = split.first else { continue }
            let command = ValkeyRawCommand(String(commandName), parameters: split.dropFirst().map { String($0) })
            do {
                let response = try await valkeyClient.execute(command)
                print(response.value.descriptionWith(redact: false))
            } catch {
                if error.errorCode == .commandError {
                    print(error.message ?? "Unknown Error")
                } else {
                    print("\(error.errorCode)\(error.message.map { ": \($0)" } ?? "")")
                    return
                }
            }
        }
    }

    static func getHostAndPort() -> (String, Int) {
        let arguments = CommandLine.arguments
        guard arguments.count > 1 else { usage() }
        let hostAndPort = arguments[1].split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        switch hostAndPort.count {
        case 1: return (String(hostAndPort[0]), 6379)
        case 2:
            guard let port = Int(hostAndPort[1]) else { usage() }
            return (String(hostAndPort[0]), port)
        default:
            usage()
        }
    }
}

extension StringProtocol {
    func splitWithSpeechMarks(separator: Character, speechMarks: Character = "\"") -> [Self.SubSequence] {
        var split: [Self.SubSequence] = []
        var position = self.startIndex
        var prevPosition = position
        var insideSpeechMarks = false
        while position != self.endIndex {
            if self[position] == separator, insideSpeechMarks == false {
                if prevPosition != position {
                    split.append(self[prevPosition..<position])
                }
                position = self.index(after: position)
                prevPosition = position
                continue
            }
            if self[position] == speechMarks {
                if !insideSpeechMarks {
                    insideSpeechMarks = true
                    // we also consider speech marks as a separator
                    if position != prevPosition {
                        split.append(self[prevPosition..<position])
                    }
                    position = self.index(after: position)
                    prevPosition = position
                    continue
                } else {
                    insideSpeechMarks = false
                    // we also consider speech marks as a separator
                    split.append(self[prevPosition..<position])
                    position = self.index(after: position)
                    prevPosition = position
                    continue
                }
            }
            position = self.index(after: position)
        }
        if prevPosition != position {
            split.append(self[prevPosition..<position])
        }
        return split
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
