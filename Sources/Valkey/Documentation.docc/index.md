# ``Valkey``

@Metadata { @TechnologyRoot }

Swift client for Valkey

## Overview

Valkey-swift is a swift based client for Valkey, the high-performance key/value datastore. It supports all the Valkey commands, pipelining, transactions, subscriptions and Valkey clusters.

### Setup

Before you start you need to setup a connection pool. This requires a background process to manage it. You can either run it using a Task group

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

### Sending commands

Once you have your connection pool up and running the client is ready to use. Commands can be called straight from the client. Each call will ask for a connection from the connection pool

```swift
try await valkeyClient.set(key: "MyKey", value: "TestString")
let value = try await valkeyClient.get(key: "MyKey").decode(as: String.self)
```

Or you can ask for a single connection and run multiple commands using that one connection
```swift
try await valkeyClient.withConnection { connection in
    try await connection.set(key: "MyKey", value: "TestString")
    let value = try await connection.get(key: "MyKey").decode(as: String.self)
}
```

## Topics

### Client

- ``ValkeyClient``
- ``ValkeyClientConfiguration``
- ``ValkeyServerAddress``
- ``ValkeyConnection``
- ``ValkeyConnectionProtocol``

### Commands

- ``ValkeyCommand``
- ``ValkeyCommandEncoder``
- ``ValkeyKey``

### RESP Protocol

- ``RESPToken``
- ``RESPRenderable``
- ``RESPStringRenderable``
- ``RESPTokenDecodable``
- ``RESPTypeIdentifier``

### Subscriptions

- ``ValkeySubscription``
- ``ValkeySubscriptionMessage``

### Errors

- ``ValkeyClientError``
- ``RESPParsingError``

### Cluster

- ``ValkeyClusterClient``
- ``ValkeyNodeDiscovery``
- ``ValkeyNodeDescriptionProtocol``
- ``ValkeyStaticNodeDiscovery``
- ``ValkeyClusterDescription``
- ``HashSlot``
- ``HashSlots``

