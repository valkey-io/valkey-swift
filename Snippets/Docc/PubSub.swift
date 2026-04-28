// snippet.hide
import Logging
import ServiceLifecycle
import Valkey

let logger = Logger(label: "getting-started")

@available(macOS 15.0, *)
func pubsubExamples(_ valkeyClient: ValkeyClient) async throws {
    // snippet.show
    // snippet.publish
    try await valkeyClient.publish(channel: "channel1", message: "Hello, World!")
    // snippet.hide

    // snippet.show
    // snippet.subscribe
    try await valkeyClient.subscribe(to: ["channel1", "channel2"]) { subscription in
        for try await item in subscription {
            // A subscription item includes the channel the message was published on
            // as well as the message.
            print(item.channel)
            print(String(item.message))
        }
    }
    // snippet.hide

    // snippet.show
    // snippet.resp3
    try await valkeyClient.withConnection { connection in
        try await connection.subscribe(to: ["channel1", "channel2"]) { subscription in
            for try await item in subscription {
                try await connection.set("channel1/last", value: item.message)
            }
        }
    }
    // snippet.hide

    // snippet.show
    // snippet.psubscribe
    try await valkeyClient.psubscribe(to: ["channel*"]) { subscription in
        for try await entry in subscription {
            let channel = "\(entry.channel)/last"
            try await valkeyClient.set(ValkeyKey(channel), value: entry.message)
        }
    }
    // snippet.hide

    // snippet.show
    // snippet.client-tracking
    try await valkeyClient.withConnection { connection in
        try await connection.clientTracking(status: .on)
    }
    // snippet.hide

    try await valkeyClient.withConnection { connection in
        // snippet.show
        // snippet.client-tracking-prefix
        try await connection.clientTracking(
            status: .on,
            prefixes: ["object:"],
            bcast: true
        )
        // snippet.hide

        // snippet.show
        // snippet.subscribe-invalidations
        try await connection.subscribeKeyInvalidations { keys in
            for try await key in keys {
                // invalidate key in cache
                // snippet.hide
                print(key)
                // snippet.show
            }
        }
        // snippet.hide
    }

    try await valkeyClient.withConnection { connection in
        let id = 0
        // snippet.show
        // snippet.client-tracking-redirect
        try await connection.clientTracking(status: .on, clientId: id)
        // snippet.hide
    }
}

// Run the command examples against a local Valkey instance.
// Requires:
//   container run -d --name valkey-test \
//     -p 6379:6379 docker.io/valkey/valkey:latest
// Currently these don't finish as the subscription closures run indefinitely
if #available(macOS 15.0, *) {
    let client = ValkeyClient(
        .hostname("localhost", port: 6379),
        logger: logger
    )
    try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask { await client.run() }

        try await pubsubExamples(client)
        print("All pubsub examples completed.")

        group.cancelAll()
    }
}
