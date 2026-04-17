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
- **Built-in TLS** — Enable TLS with a single configuration option instead of manually wiring NIO SSL handlers into the channel pipeline.
- **Typed commands** — Each command is a dedicated type with compile-time response type checking.
- **Service lifecycle** — Both ``ValkeyClient`` and ``ValkeyClusterClient`` conform to `Service` from swift-service-lifecycle.

## Update package dependencies

Start by replacing the RediStack dependency in your `Package.swift`.

RediStack uses the [`swift-server/RediStack`](https://github.com/swift-server/RediStack) package:

```swift
dependencies: [
    .package(
        url: "https://github.com/swift-server/RediStack.git",
        from: "1.6.0"
    ),
]
```

Replace it with the Valkey Swift package:

```swift
dependencies: [
    .package(
        url: "https://github.com/valkey-io/valkey-swift",
        from: "1.2.0"
    ),
]
```

Update the target dependency from the RediStack product:

```swift
.product(name: "RediStack", package: "RediStack"),
```

Replace it with the Valkey product:

```swift
.product(name: "Valkey", package: "valkey-swift"),
```

Replace your RediStack import:

```swift
import RediStack
```

With the Valkey import:

```swift
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

RediStack uses the `RedisConnection.make` factory method:

```swift
let connection = try RedisConnection.make(
    configuration: .init(
        hostname: "localhost",
        port: 6379,
        password: "secret"
    ),
    boundEventLoop: eventLoop
).wait()
defer { try? connection.close().wait() }
```

Valkey Swift uses async/await with a background task:

@Snippet(path: "valkey-swift/Snippets/MigratingFromRediStack", slice: "connectStandalone")

### Configure a connection pool

RediStack requires manual pool activation and teardown:

```swift
let pool = RedisConnectionPool(
    configuration: .init(
        initialServerConnectionAddresses: [
            try .makeAddressResolvingHost("localhost", port: 6379)
        ],
        maximumConnectionCount: .maximumActiveConnections(8),
        connectionFactoryConfiguration: .init(connectionPassword: "secret")
    ),
    boundEventLoop: eventLoop
)
pool.activate()
// Use pool...
pool.close()
```

Valkey Swift manages the pool automatically:

@Snippet(path: "valkey-swift/Snippets/MigratingFromRediStack", slice: "connectionPool")

### Configure TLS

RediStack has no built-in TLS support.
Enabling TLS requires manually creating an `NIOSSLContext` and injecting an `NIOSSLClientHandler` into the channel pipeline through a custom connection factory.
The Vapor Redis integration, for example, needed to explicitly build a channel pipeline with the SSL handler before adding Redis protocol handlers.

Valkey Swift integrates TLS directly into the client configuration:

@Snippet(path: "valkey-swift/Snippets/MigratingFromRediStack", slice: "tlsConfiguration")

### Integrate with service lifecycle

RediStack has no built-in service lifecycle support:

```swift
let pool = RedisConnectionPool(/* ... */)
pool.activate()
// ... manual cleanup on shutdown
```

Valkey Swift clients conform to `Service`:

@Snippet(path: "valkey-swift/Snippets/MigratingFromRediStack", slice: "serviceLifecycle")

## Migrate commands

Once your connections work, update your command call sites.
RediStack commands return `EventLoopFuture` values and use method-based APIs on the `RedisClient` protocol.
Valkey Swift provides async methods and typed command objects.

### Convert string commands

RediStack returns futures for string operations:

```swift
let future: EventLoopFuture<Void> = client.set("mykey", to: "myvalue")
let getFuture: EventLoopFuture<String?> =
    client.get("mykey", as: String.self)
```

Valkey Swift uses async/await:

@Snippet(path: "valkey-swift/Snippets/MigratingFromRediStack", slice: "stringCommandsAndTypes")

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

RediStack requires manual `RESPValue` handling:

```swift
let resp: RESPValue = try await client.get("mykey").get()
switch resp {
case .bulkString(let buffer):
    let value = buffer.map {
        String(buffer: $0)
    }
default:
    break
}
```

Valkey Swift provides typed responses directly:

@Snippet(path: "valkey-swift/Snippets/MigratingFromRediStack", slice: "stringCommandsAndTypes")

### Use explicit pipelining

RediStack has no dedicated pipelining API.
Valkey Swift provides typed pipelining with parameter packs:

@Snippet(path: "valkey-swift/Snippets/MigratingFromRediStack", slice: "pipelining")

See <doc:Pipelining>.

## Migrate transactions

If your code uses transactions, replace raw `MULTI`/`EXEC` commands with the typed transaction API.
RediStack has no equivalent.
Valkey Swift provides dedicated transaction support with typed results.

RediStack requires raw commands on a leased connection:

```swift
try await pool.leaseConnection { connection in
    connection.send(command: "MULTI")
    .flatMap { _ in
        connection.send(
            command: "SET",
            with: [
                "foo".convertedToRESPValue(),
                "100".convertedToRESPValue()
            ]
        )
    }.flatMap { _ in
        connection.send(
            command: "LPUSH",
            with: [
                "queue".convertedToRESPValue(),
                "foo".convertedToRESPValue()
            ]
        )
    }.flatMap { _ in
        connection.send(command: "EXEC")
    }
}
```

Valkey Swift provides a typed transaction API:

@Snippet(path: "valkey-swift/Snippets/MigratingFromRediStack", slice: "transactions")

Valkey Swift also supports WATCH for check-and-set operations. See <doc:Transactions>.

## Migrate pub/sub

Next, update any publish/subscribe code.
RediStack uses callback-based pub/sub.
Valkey Swift uses `AsyncSequence`.

RediStack uses callbacks for subscriptions:

```swift
client.subscribe(
    to: [RedisChannelName("updates")],
    messageReceiver: {
        channel, message in
        print("Received: \(message)")
    },
    onSubscribe: nil,
    onUnsubscribe: nil
).whenComplete { result in
    // handle subscription result
}
```

Valkey Swift uses `AsyncSequence`:

@Snippet(path: "valkey-swift/Snippets/MigratingFromRediStack", slice: "subscribe")

### Subscribe to pattern channels

RediStack uses `psubscribe` with callbacks:

```swift
client.psubscribe(
    to: ["user.*"],
    messageReceiver: {
        channel, message in
        // process messages
    },
    onSubscribe: nil,
    onUnsubscribe: nil
)
```

Valkey Swift uses `psubscribe` with `AsyncSequence`:

@Snippet(path: "valkey-swift/Snippets/MigratingFromRediStack", slice: "psubscribe")

With RESP3, Valkey Swift supports running commands on the same connection as an active subscription.
A single connection can also handle multiple subscriptions.
See <doc:Pubsub>.

## Migrate error handling

RediStack and Valkey Swift use different error types, so update your error-handling code.
Valkey Swift uses typed throws, with most functions throwing ``ValkeyClientError`` directly.
Use `catch let error as ValkeyClientError` to catch errors, which removes runtime type-checking overhead.

| RediStack | Valkey Swift | Notes |
|-----------|--------------|-------|
| `RedisError` | ``ValkeyClientError`` | Server-returned errors |
| `RedisClientError.connectionClosed` | ``ValkeyClientError`` with `.connectionClosed` | Connection state errors |
| `RedisConnectionPoolError.timedOutWaitingForConnection` | ``ValkeyClientError`` with `.connectionCreationCircuitBreakerTripped` | Connection pool unable to connect after multiple attempts |
| (no equivalent) | ``ValkeyClientError`` with `.timeout` | Command execution timeout |
| (no equivalent) | ``ValkeyClusterError`` | Cluster-specific errors |
| (no equivalent) | ``ValkeyTransactionError`` | Transaction-specific errors |

RediStack uses `RedisError` and `RedisClientError`:

```swift
do {
    try await client.get("key").get()
} catch let error as RedisClientError {
    if case .connectionClosed = error {
        // handle closed connection
    }
} catch let error as RedisError {
    print(error.message)
}
```

Valkey Swift uses ``ValkeyClientError``:

@Snippet(path: "valkey-swift/Snippets/MigratingFromRediStack", slice: "errorHandling")

## Migrate to cluster mode

Finally, if you connect to a Redis or Valkey cluster, take advantage of native cluster support.
RediStack doesn't support cluster mode.
If you connect to a single node in a cluster or use an external discovery mechanism, replace that approach with ``ValkeyClusterClient``:

@Snippet(path: "valkey-swift/Snippets/MigratingFromRediStack", slice: "clusterSetup")

``ValkeyClusterClient`` automatically handles:

- Hash slot routing — Commands route to the correct node based on the key's hash slot.
- MOVED/ASK redirection — The client follows redirects transparently.
- Topology refresh — The client periodically discovers cluster changes.
- Connection pooling per node — Each node gets its own connection pool.

### Implement custom node discovery

For environments with custom service discovery (such as cloud provider discovery endpoints), implement the ``ValkeyNodeDiscovery`` protocol:

@Snippet(path: "valkey-swift/Snippets/MigratingFromRediStack", slice: "customDiscovery")

## Verify the migration

Use this checklist to track your migration progress:

- [ ] Replace `RediStack` dependency with `valkey-swift` in `Package.swift`
- [ ] Update imports from `RediStack` to `Valkey`
- [ ] Replace `RedisConnection`/`RedisConnectionPool` setup with ``ValkeyClient``
- [ ] Add `client.run()` to your task group or service lifecycle
- [ ] Update command call sites to the new method signatures
- [ ] Replace `EventLoopFuture` chains with `async`/`await`
- [ ] Replace `RESPValue` handling with typed response decoding
- [ ] Adopt explicit pipelining where you need batched command execution
- [ ] Migrate raw `MULTI`/`EXEC` to the typed transaction API
- [ ] Replace callback-based pub/sub with `AsyncSequence`-based subscriptions
- [ ] Update error handling to use ``ValkeyClientError``, ``ValkeyClusterError``, and ``ValkeyTransactionError``
- [ ] If applicable, migrate from single-node workarounds to ``ValkeyClusterClient``
- [ ] Remove any `EventLoop` references no longer needed
- [ ] Run tests and verify behavior
