# Subscribing to channels

Use the PUBLISH, SUBSCRIBE, and UNSUBSCRIBE commands to implement pub/sub messaging.

## Overview

Valkey provides publish and subscribe (pub/sub) messaging support using the `PUBLISH`, `SUBSCRIBE`, and `UNSUBSCRIBE` commands.
Clients can publish to named channels and subscribe to them.
The server forwards any message published to a channel to all subscribed clients.
Valkey doesn't persist channels; if you publish a message to a channel with no subscribers, the message is lost.

### Publish to a channel

Use ``ValkeyClientProtocol/publish(channel:message:)`` to publish to a channel.
It's available on all types that conform to ``ValkeyClientProtocol``, including ``ValkeyConnection``, ``ValkeyClient``, and ``ValkeyClusterClient``.

```swift
try await valkeyClient.publish(channel: "channel1", message: "Hello, World!")
```

### Subscribe to channels

Use ``ValkeyConnection/subscribe(to:process:)-(String...,_)`` to subscribe to one or more channels and receive every message published to those channels as an `AsyncSequence`. When you exit the closure, the Valkey client sends the relevant `UNSUBSCRIBE` messages.

```swift
try await valkeyClient.withConnection { connection in
    try await connection.subscribe(to: ["channel1", "channel2"]) { subscription in
        for try await item in subscription {
            // A subscription item includes the channel the message was published on
            // as well as the message.
            print(item.channel)
            print(String(item.message))
        }
    }
}
```

Valkey uses the RESP3 protocol, which lets you run commands on the same connection as the subscription, as the following example shows:

```swift
try await connection.subscribe(to: ["channel1"]) { subscription in
    for try await entry in subscription {
        try await connection.set("channel1/last", value: entry.message)
    }
}
```

### Subscribe to channels using patterns

Valkey lets you use glob-style patterns to subscribe to a range of channels.
Call ``ValkeyConnection/psubscribe(to:process:)-([String],_)`` to subscribe using patterns; the format is the same as regular subscriptions.

```swift
try await connection.psubscribe(to: ["channel*"]) { subscription in
    for try await entry in subscription {
        let channel = "\(entry.channel)/last"
        try await connection.set(channel, value: entry.message)
    }
}
```

This example receives all messages sent to channels prefixed with the string "channel".

For more information about Valkey pub/sub, see the [Valkey documentation](https://valkey.io/topics/pubsub/).

### Implement client-side caching

Client-side caching improves the performance of services that use Valkey.
Caching specific key values locally reduces pressure on your Valkey server.
For a client-side cache to work, you need to know when to invalidate the local data.
Valkey provides two ways to do this, both using pub/sub:

1. The server remembers the keys a connection has accessed and publishes events to the invalidation channel whenever another client modifies those keys.
2. Broadcasting: The server doesn't track which keys clients have accessed. The client provides a key prefix, and the server sends events to the invalidation channel whenever another client modifies a key matching that prefix.

#### Enable tracking

Connections start without invalidation tracking enabled.
To enable receiving invalidation events on a connection, call ``ValkeyConnection/clientTracking(status:clientId:prefixes:bcast:optin:optout:noloop:)``. For example:

```swift
try await connection.clientTracking(status: .on)
```

This tells the server to use the first invalidation method, where the server remembers the keys a connection has accessed.
To track changes to all keys with a specific prefix, use:

```swift
try await connection.clientTracking(
    status: .on,
    prefixes: ["object:"],
    bcast: true
)
```

#### Subscribe to invalidation events

Once tracking is enabled, you can subscribe to invalidation events using ``ValkeyConnection/subscribeKeyInvalidations(process:)``.
The `AsyncSequence` passed to the `process` closure contains the keys that Valkey has invalidated.

```swift
try await connection.subscribeKeyInvalidations { keys in
    for try await key in keys {
        myCache.invalidate(key)
    }
}
```

#### Redirect invalidation events

With RESP3, you can perform data operations and receive invalidation events on the same connection, but Valkey client tracking also lets you redirect invalidation events to another connection.
Because the Valkey client uses a persistent connection pool, prefer using a single dedicated connection for invalidation messages to implement a system-wide cache.

For this to work, you need the ID of the connection subscribed to the key invalidation events.
Get the connection ID using ``ValkeyConnection/clientId()`` and use it when you set up tracking.

```swift
try await connection.clientTracking(status: .on, clientId: id)
```

For more information about Valkey client-side caching, see the [Valkey documentation](https://valkey.io/topics/client-side-caching/).
