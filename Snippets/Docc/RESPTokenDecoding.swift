// snippet.hide
import Logging
import NIOCore
import ServiceLifecycle
import Valkey

let logger = Logger(label: "getting-started")

@available(macOS 15.0, *)
func respTokenDecodingExamples(_ valkeyClient: ValkeyClient) async throws {
    try await valkeyClient.lpush("myList", elements: ["one", "two"])
    let respToken = try await valkeyClient.rpop("myList")!
    do {
        // snippet.show
        // snippet.decode-string
        let string = try String(respToken)
        // snippet.hide
        print(string)
    }

    do {
        // snippet.show
        // snippet.rpop
        let string = try await valkeyClient.rpop("myList")?.decode(as: String.self)
        // snippet.hide
        print(string ?? "")
    }

    do {
        // snippet.show
        // snippet.decode-array
        let values = try await valkeyClient.smembers("mySet")
        for value in values {
            let string = try value.decode(as: String.self)
            print(string)
        }
        // snippet.hide
    }

    do {
        // snippet.show
        // snippet.decode-array2
        let values = try await valkeyClient.smembers("mySet").decode(as: [String].self)
        // snippet.hide
        print(values)
    }

    do {
        // snippet.show
        // snippet.decode-array-elements
        let (member, score) = try respToken.decodeArrayElements(as: (String, Int).self)
        // snippet.hide
        print("\(member), \(score)")
    } catch {}

    do {
        // snippet.show
        // snippet.decode-map
        let values = try await valkeyClient.hgetall("hashKey")
        for (keyToken, valueToken) in values {
            let key = try keyToken.decode(as: String.self)
            let value = try valueToken.decode(as: String.self)
            print("\(key): \(value)")
        }
        // snippet.hide
    }

    do {
        // snippet.show
        // snippet.decode-map2
        let values = try await valkeyClient.hgetall("hashKey")
            .decode(as: [String: String].self)
        // snippet.hide
        print(values)
    }

    do {
        // snippet.show
        // snippet.decode-map-elements
        let (member, score) = try respToken.decodeMapValues("member", "score", as: (String, Int).self)
        // snippet.hide
        print("\(member), \(score)")
    } catch {}

    do {
        // snippet.show
        // snippet.bulk-string
        // Get value as a String
        let string = try await valkeyClient.get("key").map { String($0) }
        // Get value as a ByteBuffer
        let bytes = try await valkeyClient.get("key").map { ByteBuffer($0) }
        // snippet.hide
        print("\(string ?? "") \(bytes ?? ByteBuffer())")
    }

    do {
        // snippet.show
        // snippet.random-access
        if let response = try await valkeyClient.get("key") {
            print("\(response[0]), \(response[1])")
        }
        // snippet.hide
    }

    do {
        // snippet.show
        // snippet.span
        if let response = try await valkeyClient.get("key") {
            let span = response.span
            print("\(span[0]), \(span[1])")
        }
        // snippet.hide
    }
}

// Run the command examples against a local Valkey instance.
// Requires:
//   container run -d --name valkey-test \
//     -p 6379:6379 docker.io/valkey/valkey:latest
if #available(macOS 15.0, *) {
    let client = ValkeyClient(
        .hostname("localhost", port: 6379),
        logger: logger
    )
    try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask { await client.run() }

        try await respTokenDecodingExamples(client)
        print("All RESPToken decoding examples completed.")

        group.cancelAll()
    }
}
