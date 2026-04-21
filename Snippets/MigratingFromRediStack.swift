// To verify these examples against a running Valkey instance:
//   container run -d --name valkey-test \
//     -p 6379:6379 docker.io/valkey/valkey:latest
//   swift run MigratingFromRediStack
//   container stop valkey-test && container rm valkey-test

// snippet.hide
import Logging
import NIOSSL
import ServiceLifecycle
import Valkey

let logger = Logger(label: "migration-example")

@available(macOS 15.0, *)
func connectStandaloneExample() async throws {
    // snippet.show

    // snippet.connectStandalone
    let client = ValkeyClient(
        .hostname("localhost", port: 6379),
        configuration: .init(
            authentication: .init(
                username: "default",
                password: "secret"
            )
        ),
        logger: logger
    )

    try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask { await client.run() }
        // Use client here
        group.cancelAll()
    }
    //snippet.end

    // snippet.hide
}

@available(macOS 15.0, *)
func connectionPoolExample() async {
    // snippet.show

    // snippet.connectionPool
    let client = ValkeyClient(
        .hostname("localhost", port: 6379),
        configuration: .init(
            authentication: .init(
                username: "default",
                password: "secret"
            ),
            connectionPool: .init(
                minimumConnectionCount: 1,
                maximumConnectionSoftLimit: 8,
                maximumConnectionHardLimit: 16
            )
        ),
        logger: logger
    )
    // Pool starts when you call client.run() and stops on cancellation
    async let _ = client.run()
    // Use client here
    //snippet.end

    // snippet.hide
}

@available(macOS 15.0, *)
func tlsConfigurationExample() async throws {
    // snippet.show

    // snippet.tlsConfiguration
    let tlsConfiguration = TLSConfiguration.makeClientConfiguration()
    let client = ValkeyClient(
        .hostname("valkey.example.com", port: 6380),
        configuration: try .init(
            tls: .enable(tlsConfiguration, tlsServerName: "valkey.example.com")
        ),
        logger: logger
    )
    //snippet.end

    // snippet.hide
    _ = client
}

struct FakeWebServer: Service {
    func run() async throws {}
}

@available(macOS 15.0, *)
func serviceLifecycleExample() async throws {
    let webserver = FakeWebServer()
    // snippet.show

    // snippet.serviceLifecycle
    let client = ValkeyClient(
        .hostname("localhost", port: 6379),
        logger: logger
    )
    let serviceGroup = ServiceGroup(
        services: [client, webserver],
        gracefulShutdownSignals: [.sigint, .sigterm],
        logger: logger
    )
    try await serviceGroup.run()
    //snippet.end

    // snippet.hide
}

@available(macOS 15.0, *)
func commandExamples(_ client: ValkeyClient) async throws {
    // snippet.show

    // snippet.stringCommandsAndTypes
    try await client.set("mykey", value: "myvalue")
    let value: RESPBulkString? = try await client.get("mykey")
    if let value {
        print(String(value))
    }
    //snippet.end

    // snippet.pipelining
    let (_, _, getResult) = await client.execute(
        SET("foo", value: "100"),
        INCR("foo"),
        GET("foo")
    )
    if let result = try getResult.get() {
        print(String(result))
    }
    //snippet.end

    // snippet.transactions
    try await client.withConnection { connection in
        let results = try await connection.transaction(
            SET("foo", value: "100"),
            LPUSH("queue", elements: ["foo"])
        )
        let lpushResponse = try results.1.get()
        _ = lpushResponse
    }
    //snippet.end

    // snippet.hide
    _ = value
}

@available(macOS 15.0, *)
func subscribeExamples(_ client: ValkeyClient) async throws {
    // snippet.show

    // snippet.subscribe
    try await client.subscribe(to: "updates") { subscription in
        for try await item in subscription {
            print("Received on \(item.channel): \(String(item.message))")
        }
    }
    //snippet.end

    // snippet.psubscribe
    try await client.psubscribe(to: "user.*") { subscription in
        for try await item in subscription {
            // process messages
        }
    }
    //snippet.end

    // snippet.hide
}

@available(macOS 15.0, *)
func errorHandlingExample(_ client: ValkeyClient) async throws {
    // snippet.show

    // snippet.errorHandling
    do {
        let _: RESPBulkString? = try await client.get("key")
    } catch let error as ValkeyClientError {
        switch error.errorCode {
        case .connectionClosed:
            // handle closed connection
            break
        case .connectionCreationCircuitBreakerTripped:
            // pool unable to connect
            break
        case .timeout:
            // command execution timed out
            break
        default:
            break
        }
    }
    //snippet.end

    // snippet.hide
}

@available(macOS 15.0, *)
func clusterExamples() async throws {
    // snippet.show

    // snippet.clusterSetup
    let clusterClient = ValkeyClusterClient(
        nodeDiscovery: ValkeyStaticNodeDiscovery([
            .init(endpoint: "node1.example.com", port: 6379)
        ]),
        configuration: .init(
            client: .init(
                authentication: .init(
                    username: "default",
                    password: "secret"
                )
            ),
            clusterRefreshInterval: .seconds(30)
        ),
        logger: logger
    )

    let clusterServiceGroup = ServiceGroup(
        services: [clusterClient],
        gracefulShutdownSignals: [.sigint, .sigterm],
        logger: logger
    )
    try await clusterServiceGroup.run()
    //snippet.end

    // snippet.hide
}
// snippet.show

// snippet.customDiscovery
struct MyCloudDiscovery: ValkeyNodeDiscovery {
    struct NodeDescription: ValkeyNodeDescriptionProtocol {
        var endpoint: String
        var port: Int
    }

    func lookupNodes() async throws -> [NodeDescription] {
        // Query your discovery endpoint
        // Return node descriptions
        []
    }
}

// snippet.hide
@available(macOS 15.0, *)
func customDiscoveryExample() async throws {
    // snippet.show
    let clusterClient = ValkeyClusterClient(
        nodeDiscovery: MyCloudDiscovery(),
        configuration: .init(
            client: .init(
                authentication: .init(
                    username: "default",
                    password: "secret"
                )
            )
        ),
        logger: logger
    )
    //snippet.end

    // snippet.hide
    _ = clusterClient
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

        try await commandExamples(client)
        try await errorHandlingExample(client)
        print("All migration examples completed.")

        group.cancelAll()
    }
}
