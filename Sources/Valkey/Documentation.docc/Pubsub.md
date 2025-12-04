# Subscriptions

Implementing Pub/Sub using valkey-swift

## Overview

Valkey provides publish and subscribe (Pub/Sub) messaging support using the `PUBLISH`, `SUBSCRIBE` and `UNSUBSCRIBE` commands. It has the concept of a channel that a client can both publish to and subscribe to. The server sends any messages published to a channel to clients subscribed to that channel. Valkey channels are not persisted, for instance if a message is published to a channel that has no subscribers, that message is lost. 

### Publishing

Valkey has one function for publishing to a channel ``ValkeyClientProtocol/publish(channel:message:)``. As a member function of ``ValkeyClientProtocol``, it is available from the types that conform to it which include ``ValkeyConnection``, ``ValkeyClient`` and ``ValkeyClusterClient``.

```swift
try await valkeyClient.publish(channel: "channel1", message: "Hello, World!")
```

### Subscribing

Use ``ValkeyConnection/subscribe(to:process:)-(String...,_,_)`` to subscribe to a single or multiple channels and receive every message published to the channel via an AsyncSequence. When you exit the closure provided, the Valkey client sends the relevant `UNSUBSCRIBE` messages.

```swift
try await valkeyClient.withConnection { connection in
    try await connection.subscribe(to: ["channel1", "channel2"]) { subscription in
        for try await item in subscription {
            // a subscription item includes the channel the message was published on
            // as well as the message
            print(item.channel)
            print(String(item.message))
        }
    }
}
```

Valkey-swift uses the RESP3 protocol, which allows for commands to be run on the same connection as subsciption. This allows you to call `SET` with the same connection as the subscription, as the next example illustrates: 

```swift
try await connection.subscribe(to: ["channel1"]) { subscription in
    for try await entry in subscription {
        try await connection.set("channel1/last", value: entry.message)
    }
}
```

### Patterns

Valkey allows you to use glob style patterns to subscribe to a range of channels. These are available with the function ``ValkeyConnection/psubscribe(to:process:)-([String],_,_)``. This is formatted in a similar manner to normal subscriptions.

```swift
try await connection.subscribe(to: ["channel*"]) { subscription in
    for try await entry in subscription {
        let channel = "\(entry.channel)/last"
        try await connection.set(channel, value: entry.message)
    }
}
```

The code above receives all messages sent to channels prefixed with the string "channel".

More can be found out about Valkey pub/sub in the [Valkey documentation](https://valkey.io/topics/pubsub/).

### Support for Client Side Caching

Client side caching is a way to improve performance of a service using Valkey. Caching the values of specific keys locally avoids putting pressure on your Valkey server unnecessarily. For a client side cache to work, you need to know when to invalidate the local data. Valkey provides two different ways to do this, both using pub/sub:

1) The server remembers the keys a connection has accessed and publishes events to the invalidation channel whenever those keys are modified.
2) Broadcasting, where the server doesn't keep a record of what keys have been accessed. The client provides a prefix of the keys they are interested in and the server sends events to the invalidation channel whenever any key that matches that prefix is modified.

#### Enabling Tracking

Connections start without invalidation tracking enabled. To enable receiving invalidation events on a connection, call ``ValkeyConnection/clientTracking(status:clientId:prefixes:bcast:optin:optout:noloop:)``. For example:

```swift
try await connection.clientTracking(status: .on)
```

This tells the server to use the first invalidation method where it remembers the keys accessed by a connection. If you would like to track changes to all keys with a prefix, use:

```swift
try await connection.clientTracking(
    status: .on,
    prefixes: ["object:"],
    bcast: true
)
```

#### Subscribing to Invalidation Events

Once tracking is enabled you can subscribe to invalidation events using ``ValkeyConnection/subscribeKeyInvalidations(isolation:process:)``. The AsyncSequence passed to the `process` closure is a list of keys that have been invalidated.

```swift
try await connection.subscribeKeyInvalidations { keys in
    for try await key in keys {
        myCache.invalidate(key)
    }
}
```

#### Redirecting Invalidation Events

With RESP3 it is possible to perform data operations and receive the invalidation events on the same connection, but Valkey client tracking also allows you to redirect invalidation events to another connection. Given that the Valkey client uses a persistent connection pool, it is preferable to use a single connection for receiving invalidation messages to implement a system wide cache.

For this to work you need to know the id of the connection that is subscribed to the key invalidation events. Get the connection id using ``ValkeyConnection/clientId()`` and use it when you set up tracking. 

```swift
try await connection.clientTracking(status: .on, clientId: id)
```

More can be found out about Valkey client side caching in the [Valkey documentation](https://valkey.io/topics/client-side-caching/).
