# valkey-swift

A Swift client library for Valkey.

## Usage

The valkey-swift project uses a connection pool, which requires a background process to manage it. You can either run it using a Task group

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

Or you can use ValkeyClient with [swift-service-lifecycle](https://github.com/swift-server/swift-service-lifecycle).

Once you have a valkey client setup and running you can call valkey commands directly from the `ValkeyClient`.

```swift
try await valkeyClient.set(key: "foo", value: "bar")
```
Or you can create a connection and run multiple commands from that connection using `ValkeyClient.withConnection()`.

```swift
try await valkeyClient.withConnection { connection in
    try await connection.set(key: "foo1", value: "bar")
    try await connection.set(key: "foo2", value: "baz")
}
```

All the Valkey commands are in the Commands folder of the Valkey target. These are generated from the model files Valkey supplies in [valkey](https://github.com/valkey-io/valkey/src/commands). In many cases where it was possible to ascertain the return type of a command these functions will return that expected type. In situations where this is not possible we have either added a custom return type or a `RESPToken` is returned and you'll need to convert it manually.

### Pipelining commands

In some cases it is desirable to send multiple commands at one time, without waiting for the response after each command. This is called pipelining. You can do this using the function `pipeline(_:)`. This takes a parameter pack of commands and returns a parameter pack with the responses once all the commands have executed.

```swift
let (setResponse, getResponse) = await connection.pipeline(
    SET(key: "MyKey", value: "TestString"),
    GET(key: "MyKey")
)
let value = try getResponse.get()
```

## Redis compatibility

As Valkey is a fork of Redis v7.2.4, valkey-swift is compatible with Redis databases up to v7.2.4. There is a chance that v7.2.4 features will still be compatible in later versions of Redis, but these are now considered two different projects and they will diverge. valkey-swift uses the RESP3 protocol.

## Documentation

User guides and reference documentation for valkey-swift can be found on the [Swift Package Index](https://swiftpackageindex.com/valkey-io/valkey-swift/main/documentation/valkey).
