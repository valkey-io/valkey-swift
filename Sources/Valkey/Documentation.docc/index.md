# ``Valkey``

A Swift client library for Valkey.

## Overview

Valkey-swift is a swift based client for Valkey, the high-performance key/value datastore. It supports all the Valkey commands, pipelining, transactions, subscriptions and Valkey clusters.

### Setup

``ValkeyClient`` and ``ValkeyClusterClient`` use a connection pool that requires a background root task to run all the maintenance work required to establish connections and maintain the cluster state. You can either run it using a Task group

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
try await valkeyClient.set(key: "foo", value: "bar")
let value = try await valkeyClient.get(key: "foo")
```

Or you can ask for a single connection and run multiple commands using that one connection
```swift
try await valkeyClient.withConnection { connection in
    try await connection.set(key: "foo", value: "bar")
    let value = try await connection.get(key: "foo")
}
```

## Topics

### Articles

- <doc:Pipelining>

### Client

- ``ValkeyClient``
- ``ValkeyClientConfiguration``
- ``ValkeyConnectionProtocol``
- ``ValkeyServerAddress``
- ``ValkeyConnection``
- ``ValkeyConnectionConfiguration``

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

