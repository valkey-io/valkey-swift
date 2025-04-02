# Valkey

Valkey client. 

This is currently in an unfinished state. It has no connection manager so there is no support for connection reuse.

## Usage

To create a connection to Valkey database you use `ValkeyClient.withConnection()`.

```swift
try await ValkeyClient.withConnection(.hostname("localhost", port: 6379), logger: logger) { connection, logger in
    try await doValkeyStuff()
}
```

All the Valkey commands are in the Commands folder of the Valkey target. These are generated from the model files Valkey supplies in [valkey-doc](https://github.com/valkey-io/valkey-doc). In many cases where it was possible to ascertain the return type of a command these functions will return that expected type. In situations where this is not possible a `RESPToken` is returned and you'll need to convert the return type manually.

```swift
try await connection.set("MyKey", "TestString")
let value = try await connection.get(key)
```

### Pipelining commands

In some cases it desirable to send multiple commands at one time, without waiting for each response after each command. This is called pipelining. You can do this using the function `pipeline(_:)`. This takes a parameter pack of commands and returns a parameter pack with the responses once all the commands have executed.

```swift
let (setResponse, getResponse) = try await connection.pipeline(
    SET("MyKey", "TestString"),
    GET("MyKey")
)
```

## Redis compatibilty

As Valkey is a fork of Redis v7.2.4, swift-valkey is compatible with Redis databases up to v7.2.4. There is a chance the v7.2.4 features will still be compatible in later versions of Redis, but these are now considered two different projects and they will diverge. Swift-valkey uses the RESP3 protocol. It does not support RESP2.