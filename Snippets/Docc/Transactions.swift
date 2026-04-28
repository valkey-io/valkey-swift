// snippet.hide
import Logging
import NIOCore
import ServiceLifecycle
import Valkey

let logger = Logger(label: "getting-started")

@available(macOS 15.0, *)
func tranactionExamples(_ valkeyClient: ValkeyClient) async throws {
    do {
        // snippet.show
        // snippet.transaction
        let results = try await valkeyClient.transaction(
            SET("foo", value: "100"),
            LPUSH("queue", elements: ["foo"])
        )
        let lpushResponse = try results.1.get()
        // snippet.hide
        print(lpushResponse)
    }

    do {
        // snippet.show
        // snippet.incr-simple
        let value = try await valkeyClient.get("counter").flatMap { Int(String($0)) } ?? 0
        try await valkeyClient.set("counter", value: String(value + 1))
        // snippet.hide
    }

    do {
        _ = try await valkeyClient.withConnection { connection in
            // snippet.show
            // snippet.incr-transaction
            while true {
                try await connection.watch(keys: ["counter"])
                let value = try await connection.get("counter").flatMap { Int(String($0)) } ?? 0
                do {
                    return try await connection.transaction(
                        SET("counter", value: String(value + 1))
                    )
                } catch ValkeyTransactionError.transactionAborted {
                    // Canceled SET because "counter" was edited after WATCH, try again
                }
            }
            // snippet.hide
        }
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

        try await tranactionExamples(client)
        print("All RESPToken decoding examples completed.")

        group.cancelAll()
    }
}
