# Migrating from RediStack

Migrate your project from RediStack to Valkey Swift.

## Overview

RediStack is deprecated.
Valkey Swift replaces RediStack for all Redis and Valkey workloads in the Swift server ecosystem.
Follow these steps to migrate an existing project from RediStack to Valkey Swift.

Valkey Swift offers several advantages over RediStack:

- **Async/await** — All APIs use structured concurrency instead of `EventLoopFuture`.
- **Connection pooling** — A built-in connection pool provides persistent connections with automatic management.
- **Cluster support** — The client natively supports cluster mode with automatic routing, MOVED/ASK redirection, and topology refresh.
- **RESP3 protocol** — The client fully supports RESP3, enabling features like client-side caching and multiple subscriptions on a single connection.
- **Typed commands** — Each command is a dedicated type with compile-time response type checking.
- **Service lifecycle** — Both ``ValkeyClient`` and ``ValkeyClusterClient`` conform to `Service` from swift-service-lifecycle.

## Update package dependencies

Start by replacing the RediStack dependency in your `Package.swift`:

```swift
// Before (RediStack)
dependencies: [
    .package(url: "https://github.com/swift-server/RediStack.git",
             from: "1.6.0"),
]

// After (Valkey Swift)
dependencies: [
    .package(url: "https://github.com/valkey-io/valkey-swift",
             from: "1.2.0"),
]
```

Update target dependencies:

```swift
// Before
.product(name: "RediStack", package: "RediStack"),

// After
.product(name: "Valkey", package: "valkey-swift"),
```

Replace your imports:

```swift
// Before
import RediStack

// After
import Valkey
```

> Note: If you build an executable for macOS, Valkey requires a minimum platform version.
> Add a platform requirement to your project:
>
> ```swift
> platforms: [.macOS(.v15)],
> ```

## Migrate connection setup

After updating your dependencies, replace your connection creation and management code.
RediStack requires manual connection lifecycle management with `EventLoop` binding.
Valkey Swift uses a connection pool that runs as a background task.

### Connect to a standalone server

```swift
// Before (RediStack) — EventLoopFuture-based
let connection = try RedisConnection.make(
    configuration: .init(hostname: "localhost", port: 6379, password: "secret"),
    boundEventLoop: eventLoop
).wait()
defer { try? connection.close().wait() }

// After (Valkey Swift) — async/await with background task
let client = ValkeyClient(
    .hostname("localhost", port: 6379),
    configuration: .init(authentication: .init(password: "secret")),
    logger: logger
)

try await withThrowingTaskGroup(of: Void.self) { group in
    group.addTask { await client.run() }
    // Use client here
    group.cancelAll()
}
```

### Configure a connection pool

```swift
// Before (RediStack) — manual activate/close
let pool = RedisConnectionPool(
    configuration: .init(
        initialServerConnectionAddresses: [try .makeAddressResolvingHost("localhost", port: 6379)],
        maximumConnectionCount: .maximumActiveConnections(8),
        connectionFactoryConfiguration: .init(connectionPassword: "secret")
    ),
    boundEventLoop: eventLoop
)
pool.activate()
// Use pool...
pool.close()

// After (Valkey Swift) — automatic pool management
let client = ValkeyClient(
    .hostname("localhost", port: 6379),
    configuration: .init(
        authentication: .init(password: "secret"),
        connectionPool: .init(minimumConnectionCount: 1, softConnectionLimit: 8, hardConnectionLimit: 16)
    ),
    logger: logger
)
// Pool starts when you call client.run() and stops on cancellation
```

### Integrate with service lifecycle

RediStack has no built-in service lifecycle support.
Valkey Swift clients conform to `Service`:

```swift
// Before (RediStack) — manual lifecycle
let pool = RedisConnectionPool(/* ... */)
pool.activate()
// ... manual cleanup on shutdown

// After (Valkey Swift)
let client = ValkeyClient(.hostname("localhost", port: 6379), logger: logger)
let serviceGroup = ServiceGroup(
    services: [client, webserver],
    gracefulShutdownSignals: [.sigint, .sigterm],
    logger: logger
)
try await serviceGroup.run()
```

## Migrate commands

Once your connections work, update your command call sites.
RediStack commands return `EventLoopFuture` values and use method-based APIs on the `RedisClient` protocol.
Valkey Swift provides async methods and typed command objects.

### Convert string commands

```swift
// Before (RediStack)
let future: EventLoopFuture<Void> = client.set("mykey", to: "myvalue")
let getFuture: EventLoopFuture<String?> = client.get("mykey", as: String.self)

// After (Valkey Swift)
try await client.set(key: "mykey", value: "myvalue")
let value: RESPBulkString? = try await client.get(key: "mykey")
```

### Review command signature differences

| Operation | RediStack | Valkey Swift |
|-----------|-----------|--------------|
| SET     | `client.set("key", to: value)`       | `client.set("key", value: value)` |
| GET     | `client.get("key", as: String.self)` | `client.get("key")` |
| DEL     | `client.delete("key1", "key2")`      | `client.del(keys: ["key1", "key2"])` |
| EXISTS  | `client.exists("key")`               | `client.exists(keys: ["key"])` |
| EXPIRE  | `client.expire("key", after: .seconds(60))` | `client.expire("key", seconds: 60)` |
| LPUSH   | `client.lpush(values, into: "list")` | `client.lpush("list", elements: values)` |
| ZADD    | `client.zadd([(element: "a", score: 1.0)], to: "set")` | `client.zadd("set", members: [.init(score: 1.0, member: "a")])` |
| INCR    | `client.increment("counter")`        | `client.incr("counter")` |
| PUBLISH | `client.publish(msg, to: "chan")`    | `client.publish(channel: "chan", message: msg)` |

### Handle typed return values

RediStack returns `RESPValue`, an enum you destructure manually.
Valkey Swift commands declare typed ``ValkeyCommand/Response`` types, so you get typed results without manual decoding.

```swift
// Before (RediStack) — manual RESPValue handling
let resp: RESPValue = try await client.get("mykey").get()
switch resp {
case .bulkString(let buffer):
    let value = buffer.map { String(buffer: $0) }
default:
    break
}

// After (Valkey Swift) — typed responses
let value: RESPBulkString? = try await client.get(key: "mykey")
if let value {
    print(String(value))
}
```

### Use explicit pipelining

RediStack has no dedicated pipelining API.
Valkey Swift provides typed pipelining with parameter packs:

```swift
// Before (RediStack) — implicit pipelining through concurrent futures
let setFuture = client.set("foo", to: "100")
let incrFuture = client.increment("foo")
let getFuture = client.get("foo")
try setFuture.wait(); try incrFuture.wait()
let result = try getFuture.wait()

// After (Valkey Swift) — explicit pipeline
let (_, _, getResult) = await client.execute(
    SET(key: "foo", value: "100"),
    INCR(key: "foo"),
    GET(key: "foo")
)
if let result = try getResult.get() {
    print(String(result))
}
```

See <doc:Pipelining>.

## Migrate transactions

If your code uses transactions, replace raw `MULTI`/`EXEC` commands with the typed transaction API.
RediStack has no equivalent.
Valkey Swift provides dedicated transaction support with typed results.

```swift
// Before (RediStack) — raw commands on a leased connection
try await pool.leaseConnection { connection in
    connection.send(command: "MULTI").flatMap { _ in
        connection.send(command: "SET", with: ["foo".convertedToRESPValue(), "100".convertedToRESPValue()])
    }.flatMap { _ in
        connection.send(command: "LPUSH", with: ["queue".convertedToRESPValue(), "foo".convertedToRESPValue()])
    }.flatMap { _ in
        connection.send(command: "EXEC")
    }
}

// After (Valkey Swift)
try await client.withConnection { connection in
    let results = try await connection.transaction(
        SET("foo", value: "100"),
        LPUSH("queue", elements: ["foo"])
    )
    let lpushResponse = try results.1.get()
}
```

Valkey Swift also supports WATCH for check-and-set operations. See <doc:Transactions>.

## Migrate pub/sub

Next, update any publish/subscribe code.
RediStack uses callback-based pub/sub.
Valkey Swift uses `AsyncSequence`.

```swift
// Before (RediStack) — callback-based
client.subscribe(
    to: [RedisChannelName("updates")],
    messageReceiver: { channel, message in
        print("Received on \(channel): \(message)")
    },
    onSubscribe: nil,
    onUnsubscribe: nil
).whenComplete { result in
    // handle subscription result
}

// After (Valkey Swift) — AsyncSequence-based
try await client.withConnection { connection in
    try await connection.subscribe(to: ["updates"]) { subscription in
        for try await item in subscription {
            print("Received on \(item.channel): \(String(item.message))")
        }
    }
}
```

### Subscribe to pattern channels

```swift
// Before (RediStack)
client.psubscribe(
    to: ["user.*"],
    messageReceiver: { channel, message in /* ... */ },
    onSubscribe: nil,
    onUnsubscribe: nil
)

// After (Valkey Swift)
try await client.withConnection { connection in
    try await connection.psubscribe(to: ["user.*"]) { subscription in
        for try await item in subscription {
            // process messages
        }
    }
}
```

With RESP3, Valkey Swift supports running commands on the same connection as an active subscription.
A single connection can also handle multiple subscriptions.
See <doc:Pubsub>.

## Migrate error handling

RediStack and Valkey Swift use different error types, so update your error-handling code.

| RediStack | Valkey Swift | Notes |
|-----------|--------------|-------|
| `RedisError` | ``ValkeyClientError`` | Server-returned errors |
| `RedisClientError.connectionClosed` | ``ValkeyClientError`` with `.connectionClosed` | Connection state errors |
| `RedisConnectionPoolError.timedOutWaitingForConnection` | ``ValkeyClientError`` with `.timeout` | Pool timeout |
| (no equivalent) | ``ValkeyClusterError`` | Cluster-specific errors |
| (no equivalent) | ``ValkeyTransactionError`` | Transaction-specific errors |

```swift
// Before (RediStack)
do {
    try await client.get("key").get()
} catch let error as RedisClientError {
    if case .connectionClosed = error { /* ... */ }
} catch let error as RedisError {
    print(error.message)
}

// After (Valkey Swift)
do {
    let _: RESPBulkString? = try await client.get(key: "key")
} catch let error as ValkeyClientError {
    switch error.errorCode {
    case .connectionClosed:
        // handle closed connection
        break
    case .timeout:
        // handle timeout
        break
    default:
        break
    }
}
```

## Migrate to cluster mode

Finally, if you connect to a Redis or Valkey cluster, take advantage of native cluster support.
RediStack doesn't support cluster mode.
If you connect to a single node in a cluster or use an external discovery mechanism, replace that approach with ``ValkeyClusterClient``:

```swift
let clusterClient = ValkeyClusterClient(
    .hostname("node1.example.com", port: 6379),
    configuration: .init(
        client: .init(authentication: .init(password: "secret")),
        clusterRefreshInterval: .seconds(30)
    ),
    logger: logger
)

let serviceGroup = ServiceGroup(
    services: [clusterClient],
    gracefulShutdownSignals: [.sigint, .sigterm],
    logger: logger
)
try await serviceGroup.run()
```

``ValkeyClusterClient`` automatically handles:

- Hash slot routing — Commands route to the correct node based on the key's hash slot.
- MOVED/ASK redirection — The client follows redirects transparently.
- Topology refresh — The client periodically discovers cluster changes.
- Connection pooling per node — Each node gets its own connection pool.

### Implement custom node discovery

For environments with custom service discovery (such as cloud provider discovery endpoints), implement the ``ValkeyNodeDiscovery`` protocol:

```swift
struct MyCloudDiscovery: ValkeyNodeDiscovery {
    func discoverNodes() async throws -> [any ValkeyNodeDescriptionProtocol] {
        // Query your discovery endpoint
        // Return node descriptions
    }
}

let clusterClient = ValkeyClusterClient(
    clientConfiguration: .init(authentication: .init(password: "secret")),
    nodeDiscovery: MyCloudDiscovery(),
    logger: logger
)
```

## Verify the migration

Use this checklist to track your migration progress:

- [ ] Replace `RediStack` dependency with `valkey-swift` in `Package.swift`
- [ ] Update imports from `RediStack` to `Valkey`
- [ ] Replace `RedisConnection`/`RedisConnectionPool` setup with ``ValkeyClient``
- [ ] Add `client.run()` to your task group or service lifecycle
- [ ] Update command call sites to the new method signatures
- [ ] Replace `EventLoopFuture` chains with `async`/`await`
- [ ] Replace `RESPValue` handling with typed response decoding
- [ ] Migrate raw `MULTI`/`EXEC` to the typed transaction API
- [ ] Replace callback-based pub/sub with `AsyncSequence`-based subscriptions
- [ ] Update error handling to use ``ValkeyClientError`` and ``ValkeyClusterError``
- [ ] If applicable, migrate from single-node workarounds to ``ValkeyClusterClient``
- [ ] Remove any `EventLoop` references no longer needed
- [ ] Run tests and verify behavior
