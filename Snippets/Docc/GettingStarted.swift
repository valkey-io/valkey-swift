// snippet.hide
import Logging
import NIOSSL
import ServiceLifecycle
import Valkey

let logger = Logger(label: "getting-started")

@available(macOS 15.0, *)
func connectTaskGroupExample() async throws {
    // snippet.show
    // snippet.client-taskgroup

    let valkeyClient = ValkeyClient(.hostname("localhost", port: 6379), logger: logger)
    await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask {
            // run connection pool in the background
            await valkeyClient.run()
        }
        // use valkey client
        // ...
        group.cancelAll()
    }
    // snippet.hide
}

@available(macOS 15.0, *)
func connectServiceLifecycleExample() async throws {
    struct WebServer: Service {
        func run() async throws {
            try? await gracefulShutdown()
            print("webserver done")
        }
    }
    let webserver = WebServer()
    // snippet.show
    // snippet.client-servicelifecycle

    let valkeyClient = ValkeyClient(.hostname("localhost", port: 6379), logger: logger)

    let services: [Service] = [valkeyClient, webserver]
    let serviceGroup = ServiceGroup(
        services: services,
        gracefulShutdownSignals: [.sigint, .sigterm],
        logger: logger
    )
    try await serviceGroup.run()
    // snippet.hide
}

@available(macOS 15.0, *)
func commandExamples(_ valkeyClient: ValkeyClient) async throws {
    // snippet.show
    // snippet.execute
    try await valkeyClient.set("foo", value: "bar")
    let value = try await valkeyClient.get("foo")
    // snippet.hide
    if let value = value {
        print(value)
    }

    // snippet.show
    // snippet.with-connection
    try await valkeyClient.withConnection { connection in
        try await connection.set("foo", value: "bar")
        let value = try await connection.get("foo")
        // snippet.hide
        if let value = value {
            print(value)
        }
        // snippet.show
    }
    // snippet.hide
}

// Run the command examples against a local Valkey instance.
// Requires:
//   container run -d --name valkey-test \
//     -p 6379:6379 docker.io/valkey/valkey:latest
if #available(macOS 15.0, *) {
    try await connectTaskGroupExample()

    let client = ValkeyClient(
        .hostname("localhost", port: 6379),
        logger: logger
    )
    try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask { await client.run() }

        try await commandExamples(client)
        print("All getting started examples completed.")

        group.cancelAll()
    }
}
