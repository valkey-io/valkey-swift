# valkey-swift

Valkey client 

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

Once you have a valkey client setup and running you can create connections to your Valkey database using `ValkeyClient.withConnection()`.

```swift
try await valkeyClient.withConnection { connection in
    try await doValkeyStuff()
}
```

All the Valkey commands are in the Commands folder of the Valkey target. These are generated from the model files Valkey supplies in [valkey](https://github.com/valkey-io/valkey/src/commands). In many cases where it was possible to ascertain the return type of a command these functions will return that expected type. In situations where this is not possible (or we are returning a String) a `RESPToken` is returned and you'll need to convert it manually.

```swift
try await connection.set(key: "MyKey", value: "TestString")
let value = try await connection.get(key: "MyKey").decode(as: String.self)
```

### Pipelining commands

In some cases it is desirable to send multiple commands at one time, without waiting for the response after each command. This is called pipelining. You can do this using the function `pipeline(_:)`. This takes a parameter pack of commands and returns a parameter pack with the responses once all the commands have executed.

```swift
let (setResponse, getResponse) = try await connection.pipeline(
    SET(key: "MyKey", value: "TestString"),
    GET(key: "MyKey")
)
```

## Redis compatibilty

As Valkey is a fork of Redis v7.2.4, valkey-swift is compatible with Redis databases up to v7.2.4. There is a chance the v7.2.4 features will still be compatible in later versions of Redis, but these are now considered two different projects and they will diverge. valkey-swift uses the RESP3 protocol.