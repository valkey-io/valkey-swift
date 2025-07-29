# Subscriptions

Implementing Pub/Sub using valkey-swift

## Overview

Valkey provides publish/subscribe messaging support via the PUBLISH, SUBSCRIBE and UNSUBSCRIBE commands. It has a concept of a channel that a client can either publish to or subscribe to. Any messages published to a channel are then sent to the current list of clients subscribed to that channel. Valkey pub/sub channels are not persisted. If a message is published to a channel and no one is subscribed to the channel, that message is lost. 

### Publishing

Valkey has one function for publishing to a channel ``ValkeyClientProtocol/publish(channel:message:)``. As this is a member function of ``ValkeyClientProtocol`` it is available from ``ValkeyConnection``, ``ValkeyClient`` and ``ValkeyClusterClient``.

```swift
try await valkeyClient.publish(channel: "channel1", message: "Hello, World!")
```

### Subscribing

Using ``ValkeyConnection/subscribe(to:isolation:process:)-(String...,_,_)`` we can subscribe to a single or multiple channels and receive every message published to the channel via an AsyncSequence. When we exit the closure provided the relevant `UNSUBSCRIBE` calls will be made.

```swift
try await valkeyClient.withConnection { connection in
    try await connection.subscribe(to: ["channel1", "channel2"]) { subscription in
        for try await item in subscription {
            // a subscription item will include the channel the message was published on
            // as well as the message
            print(item.channel)
            print(item.message)
        }
    }
}
```

Valkey-swift uses the RESP3 protocol, which allows for commands to be run on the same connection as subsciption, so the following where we call `SET` using the same connection as the subscription is possible. 

```swift
try await connection.subscribe(to: ["channel1"]) { subscription in
    for try await entry in subscription {
        try await connection.set("channel1/last", value: entry.message)
    }
}
```

### Patterns

Valkey allows you to use glob style patterns to subscribe to a range of channels. These are available via the function ``ValkeyConnection/psubscribe(to:isolation:process:)-([String],_,_)``. This is formatted in a similar manner to normal subscriptions.

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

Client side caching is a way to improve performance of a service using Valkey. Caching the values of specific keys locally avoids putting pressure on your Valkey server unnecessarily. For a client side cache to work though, we need to know when to invalidate our local data. Valkey provides two different ways to do this. Both of these work using pub/sub.

1) The server remembers the keys a connection has accessed and publishes events to the invalidation channel whenever those keys are modified.
2) Broadcasting, where the server doesn't keep a record of what keys have been accessed, instead the client provides a prefix of the keys they are interested in. The invalidation channel will then receive events whenever any key with that prefix is modified.

#### Enabling Tracking

Connections start without invalidation tracking enabled. To enable receiving invalidation events on a connection. You need to call

```swift
try await connection.clientTracking(status: .on)
```

This will enable method 1 where the server remembers the keys accessed by a connection. If you would like to track changes to all keys with a prefix, you can use

```swift
try await connection.clientTracking(
    status: .on,
    prefixes: ["object:"],
    bcast: true
)
```

#### Subscribing to Invalidation Events

Once tracking is enabled you can subscribe to invalidation events using ``ValkeyConnection/subscribeKeyInvalidations(process:)``. The AsyncSequence passed to the `process` closure is a list of keys that have been invalidated.

```swift
try await connection.subscribeKeyInvalidations { keys in
    for try await key in keys {
        myCache.invalidate(key)
    }
}
```

#### Redirecting Invalidation Events

With RESP3 it is possible to perform data operations and receive the invalidation events on the same connection, but Valkey client tracking also allows you to redirect invalidation events to another connection. Given valkey-swift uses a persistent connection pool it is probably preferable to use a single connection for invalidation message if you want to implement a system wide cache.

For this to work you need to know the id of the connection that is subscribed to the key invalidation events. You can get connection id using ``ValkeyClientProtocol/clientId()`` and when setting up tracking you include the client id. 

```swift
try await connection.clientTracking(status: .on, clientId: id)
```

More can be found out about Valkey client side caching in the [Valkey documentation](https://valkey.io/topics/client-side-caching/).
