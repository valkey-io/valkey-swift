# Getting started with Valkey

Add Valkey to your project, manage connections, and send commands.

## Overview

### Add Valkey as a dependency

Add Valkey Swift as a dependency to your project and targets that use it.

You can use the `add-dependency` command:

```bash
swift package add-dependency \
    https://github.com/valkey-io/valkey-swift --from: 0.3.0
```

Or edit Package.swift directly:
```swift
dependencies: [
    .package(url: "https://github.com/valkey-io/valkey-swift",
             from: "0.3.0"),
]
```

Add Valkey to the relevant target or targets as well.
For example, to add Valkey as a dependency to the target `MyApp`:

```bash
swift package add-target-dependency \
    Valkey MyApp --package valkey-swift
```

You can also edit the dependencies for that target directly in Package.swift:
```swift
dependencies: [
    .product(name: "Valkey", package: "valkey-swift"),
]
```

> Note: If you're building an executable for macOS, Valkey requires a minimum platform version.
> For example, add a minimum platform requirement to your project:
>
> ```swift
> platforms: [.macOS(.v15)],
> ```

Import Valkey in your Swift files:

```swift
import Valkey
```

### Enable connections to a Valkey server

``ValkeyClient`` and ``ValkeyClusterClient`` use a connection pool that requires a background root task to run all the maintenance work required to establish connections and maintain the cluster state.
You can run them using a task group, for example:

```swift
let valkeyClient = ValkeyClient(.hostname("localhost", port: 6379), logger: logger)
try await withThrowingTaskGroup(of: Void.self) { group in
    group.addTask {
        // run connection pool in the background
        await valkeyClient.run()
    }
    // use valkey client
}
```

You can also use [swift-service-lifecycle](https://github.com/swift-server/swift-service-lifecycle) to manage the Valkey client alongside other services.

```swift
let valkeyClient = ValkeyClient(.hostname("localhost", port: 6379), logger: logger)

let services: [Service] = [valkeyClient, webserver, other-service]
let serviceGroup = ServiceGroup(
    services: services,
    gracefulShutdownSignals: [.sigint, .sigterm],
    logger: logger
)
try await serviceGroup.run()
```

### Send commands

Once your connection pool is running, you can call commands on the client.
`ValkeyClient` uses a connection from the connection pool for each call:

```swift
try await valkeyClient.set(key: "foo", value: "bar")
let value = try await valkeyClient.get(key: "foo")
```

To run multiple commands on the same connection:

```swift
try await valkeyClient.withConnection { connection in
    try await connection.set(key: "foo", value: "bar")
    let value = try await connection.get(key: "foo")
}
```
