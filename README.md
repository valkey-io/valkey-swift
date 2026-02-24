# valkey-swift

A Swift client library for Valkey.

## Usage

valkey-swift provides two clients depending on your deployment:
- **`ValkeyClient`**: For single-node or primary-replica deployments
- **`ValkeyClusterClient`**: For [Cluster Mode](https://valkey.io/topics/cluster-tutorial/) deployments with automatic sharding

### ValkeyClient

For single-node Valkey instances or primary-replica setups.

#### Setup

Create a client with server connection details:

```swift
import Valkey

let valkeyClient = ValkeyClient(
    .hostname("127.0.0.1", port: 6379),
    logger: logger
)
```

#### Running the Client

The client uses a connection pool that requires a background process. There are two approaches:

##### Option 1: Using Swift concurrency

You can run the background process using `async let`. When you leave the scope of the function your async let variable is declared the client will be shutdown.

```swift
async let _ = valkeyClient.run()

// Use client
try await valkeyClient.set(key: "foo", value: "bar")
let value = try await valkeyClient.get(key: "foo")
// Client continues running in background
```

Alternatively you could also use a TaskGroup

```swift
try await withThrowingTaskGroup(of: Void.self) { group in
    group.addTask {
        await valkeyClient.run()
    }

    // All operations happen in the closure body
    try await valkeyClient.set(key: "foo", value: "bar")
    let value = try await valkeyClient.get(key: "foo")

    // When done, cancel the run() task
    group.cancelAll()
}
// Client is shut down when task group exits
```

##### Option 2: Using ServiceLifecycle

Or use with [swift-service-lifecycle](https://github.com/swift-server/swift-service-lifecycle) for long-running services.

```swift
let services: [Service] = [myApp, valkeyClient]
let serviceGroup = ServiceGroup(
    services: services,
    gracefulShutdownSignals: [.sigint, .sigterm],
    logger: logger
)
try await serviceGroup.run()
```

#### Command Execution

Execute commands directly from the client (connection is managed automatically):

```swift
try await valkeyClient.set(key: "user:123", value: "alice")
let value = try await valkeyClient.get(key: "user:123")
```

#### Pipelining

Send multiple commands at once without waiting for each response:

```swift
let (setResponse, getResponse) = await valkeyClient.execute(
    SET(key: "MyKey", value: "TestString"),
    GET(key: "MyKey")
)
let value = try getResponse.get()
```

#### Transactions

Execute commands atomically using MULTI/EXEC:

```swift
let results = try await valkeyClient.transaction(
    SET(key: "order:123:status", value: "pending"),
    SET(key: "order:123:timestamp", value: "2025-01-15"),
    INCR(key: "order:123:attempts")
)
```

#### Connection Management

Get a dedicated connection when multiple commands need to run on the same connection:

```swift
try await valkeyClient.withConnection { connection in
    try await connection.set(key: "foo1", value: "bar")
    try await connection.set(key: "foo2", value: "baz")
    let value = try await connection.get(key: "foo1")
}
```

### ValkeyClusterClient

For [Cluster Mode](https://valkey.io/topics/cluster-tutorial/) Valkey deployments with automatic command routing, topology discovery, and live cluster topology changes.

#### Setup

Configure node discovery to provide initial cluster endpoints. The client will automatically discover the full cluster topology:

```swift
import Valkey

let discovery = ValkeyStaticNodeDiscovery([
    .init(endpoint: "node1.example.com", port: 6379),
    .init(endpoint: "node2.example.com", port: 6379),
    .init(endpoint: "node3.example.com", port: 6379)
])

let configuration = ValkeyClusterClientConfiguration(
    client: ValkeyClientConfiguration(
        commandTimeout: .seconds(5)
    ),
    maximumRedirects: 3,
    clusterRefreshInterval: .seconds(300)
)

let clusterClient = ValkeyClusterClient(
    nodeDiscovery: discovery,
    configuration: configuration,
    logger: logger
)
```

#### Running the Client

In a similar way that `ValkeyClient` requires a background process the cluster client also requires a background process to manage all its connection pools and perform regular cluster topology updates. You can use all the same methods to run the `ValkeyClusterClient` background process: ([Swift Concurrency](#option-1-using-swift-concurrency), [ServiceLifecycle](#option-2-using-servicelifecycle)).

#### Command Execution

The cluster client automatically routes commands to the correct node based on key hash slots. Note a command cannot reference two keys in different hash slots.

```swift
// Automatically routed to the node owning the "user:123" hash slot
try await clusterClient.set(key: "user:123", value: "alice")
let value = try await clusterClient.get(key: "user:123")
```

#### Pipelining Across Nodes

Commands affecting different hash slots are automatically split and executed concurrently across nodes:

```swift
let results = await clusterClient.execute(
    SET(key: "user:1", value: "alice"),
    SET(key: "user:2", value: "bob"),
    GET(key: "user:1"),
    GET(key: "user:2")
)
```

To ensure commands target the same hash slot, use hash tags (substring between `{}`):

```swift
// Both keys guaranteed to be on the same node
try await clusterClient.set(key: "user:{123}:profile", value: "data")
try await clusterClient.set(key: "user:{123}:settings", value: "prefs")
```

#### Transactions

Transactions require all keys to be in the same hash slot:

```swift
let results = try await clusterClient.transaction(
    SET(key: "order:{456}:status", value: "pending"),
    SET(key: "order:{456}:timestamp", value: "2025-01-15"),
    INCR(key: "order:{456}:attempts")
)
```

#### Connection Management

Get a connection for specific keys when multiple commands need to run on the same node:

```swift
try await clusterClient.withConnection(forKeys: ["user:{123}"], readOnly: false) { connection in
    try await connection.set(key: "user:{123}:profile", value: "data")
    try await connection.set(key: "user:{123}:email", value: "alice@example.com")
}
```

## Commands

All Valkey commands are available in the Commands folder, generated from [Valkey's command specifications](https://github.com/valkey-io/valkey/tree/unstable/src/commands). Commands return typed responses where possible, or `RESPToken` for manual conversion when needed.

## Redis compatibility

As Valkey is a fork of Redis v7.2.4, valkey-swift is compatible with Redis databases up to v7.2.4. There is a chance that v7.2.4 features will still be compatible in later versions of Redis, but these are now considered two different projects and they will diverge. valkey-swift uses the RESP3 protocol.

## Documentation

User guides and reference documentation for valkey-swift can be found on the [Swift Package Index](https://swiftpackageindex.com/valkey-io/valkey-swift/documentation/valkey).
