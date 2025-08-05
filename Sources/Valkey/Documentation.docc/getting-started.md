# Getting started using Valkey

Add Valkey to your project, manage the connections, and send commands.

## Overview

### Adding Valkey as a dependency

Add Valkey-Swift as a dependency to your project and targets that use it.

You can use the `add-dependency` command:

```bash
swift package add-dependency \
    https://github.com/valkey-io/valkey-swift --from: 0.1.0
```

or edit Package.swift directly:
```swift
dependencies: [
    .package(url: "https://github.com/valkey-io/valkey-swift",
             from: "0.1.0"),
]
```

And for the relevant target or targets.
The following example shows how to add to Valkey as a dependency to the target `MyApp`:

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

> Note: If you are building an executable for macOS, Valkey has a minimum platform dependency you need to accomodate.
> For example, you may want to add a minimum platform requirement to your project:
>
> ```swift
> platforms: [.macOS(.v15)],
> ```

Import Valkey in the swift files to use it:

```swift
import Valkey
```

### Enabling connections to a Valkey server

``ValkeyClient`` and ``ValkeyClusterClient`` use a connection pool that requires a background root task to run all the maintenance work required to establish connections and maintain the cluster state.
You can either run them using a Task group, for example:

```swift
let valkeyClient = ValkeyClient(.hostname("localhost", port: 6379), logger: logger)
try await withThrowingTaskgroup(of: Void.self) { group in
    group.addTask {
        // run connection pool in the background
        try await valkeyClient.run()
    }
    // use valkey client
}
```

Or you can use [swift-service-lifecycle](https://github.com/swift-server/swift-service-lifecycle) to manage the connection manager.

```swift
let valkeyClient = ValkeyClient(.hostname("localhost", port: 6379), logger: logger)

let services: [Service] = [valkeyClient, webserver, other-service]
let serviceGroup = ServiceGroup(
    services: services,
    gracefulShutdownSignals: [.sigint],
    cancellationSignals: [.sigterm],
    logger: logger
)
try await serviceGroup.run()
```

### Sending commands

Once you have your connection pool up and running the client is ready to use, you can call commands on the client.
Valkey-client uses a connection from the connection pool for each call:

```swift
try await valkeyClient.set(key: "foo", value: "bar")
let value = try await valkeyClient.get(key: "foo")
```

You can ask for a single connection and run multiple commands using it:

```swift
try await valkeyClient.withConnection { connection in
    try await connection.set(key: "foo", value: "bar")
    let value = try await connection.get(key: "foo")
}
```
