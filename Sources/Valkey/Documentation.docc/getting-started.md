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

@Snippet(path: "valkey-swift/Snippets/Docc/GettingStarted", slice: "client-taskgroup")

You can also use [swift-service-lifecycle](https://github.com/swift-server/swift-service-lifecycle) to manage the Valkey client alongside other services.

@Snippet(path: "valkey-swift/Snippets/Docc/GettingStarted", slice: "client-servicelifecycle")

### Send commands

Once your connection pool is running, you can call commands from the client.
`ValkeyClient` uses a connection from the connection pool for each call:

@Snippet(path: "valkey-swift/Snippets/Docc/GettingStarted", slice: "execute")

To run multiple commands on the same connection:

@Snippet(path: "valkey-swift/Snippets/Docc/GettingStarted", slice: "with-connection")
