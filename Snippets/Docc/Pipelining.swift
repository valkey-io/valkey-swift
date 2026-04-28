// snippet.hide
import Logging
import ServiceLifecycle
import Valkey

let logger = Logger(label: "getting-started")

@available(macOS 15.0, *)
func pipeliningExamples(_ valkeyClient: ValkeyClient) async throws {
    // snippet.show
    // snippet.pipelining
    let (_, _, getResult) = await valkeyClient.execute(
        SET("foo", value: "100"),
        INCR("foo"),
        GET("foo")
    )
    // get returns an optional RESPBulkString
    if let result = try getResult.get() {
        print(String(result))  // should print 101
    }
    // snippet.hide

    // snippet.show
    // snippet.dynamic
    // Create command array.
    var commands: [any ValkeyCommand] = []
    commands.append(SET("foo", value: "100"))
    commands.append(INCR("foo"))
    commands.append(GET("foo"))
    // execute commands
    let results = await valkeyClient.execute(commands)
    // Get the result of the GET command and decode it as an optional String
    // to avoid an error being thrown if the response is a null token.
    if let value = try results[2].get().decode(as: String?.self) {
        print(value)
    }
    // snippet.hide

    // snippet.show
    // snippet.concurrency
    try await valkeyClient.withConnection { connection in
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await connection.lpush("fooList", elements: ["bar"])
            }
            group.addTask {
                try await connection.rpush("fooList2", elements: ["baz"])
            }
            try await group.waitForAll()
        }
    }
    // snippet.hide
    try await valkeyClient.withConnection { connection in
        // snippet.show
        // snippet.async-let
        async let asyncResult = connection.lpush("fooList", elements: ["bar"])
        async let asyncResult2 = connection.lpush("fooList2", elements: ["baz"])
        // do something else
        let result = try await asyncResult
        let result2 = try await asyncResult2
        print("\(result), \(result2)")
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

        try await pipeliningExamples(client)
        print("All pipelining examples completed.")

        group.cancelAll()
    }
}
