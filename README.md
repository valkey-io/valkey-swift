# Redis

Redis client. 

This is currently in an unfinished state. It has no connection manager so there is no support for connection reuse.

## Usage

To create a connection to Redis database you use `RedisClient.withConnection()`.

```swift
try await RedisClient.withConnection(.hostname("localhost", port: 6379), logger: logger) { connection, logger in
    try await doRedisStuff()
}
```

Swift-redis has three ways to send commands.

### Raw

You can send raw commands using `RedisConnection.send()`. This takes a parameter pack of types that conform to `RESPRenderable`. These includes `Int`, `String`, `Double`, `RedisKey` and then `Optional` and `Array` where the internal type is also `RedisRenderable`. For example to set a value you can call

```swift
let key = RedisKey(rawValue: "MyKey")
try await connection.send("SET", key, "TestString")
```

A raw send will return a `RESPToken`. This can be converted to any value that conforms to `RESPTokenRepresentable`. As with `RESPRenderable` these covers many standard types. You can convert from a `RESPToken` to `RESPTokenRepresentable` type by either using the constructor `init(from: RESPToken)` or the function `converting(to:)`.

```swift
let response = try await connection.send("GET", key)
let value = try response.converting(to: String.self)
// you could also use `let value = String(from: response)`
```

### Using generated functions

Swift-redis includes a separate module `RedisCommands` that includes functions for all the redis commands. These are generated from the model files redis supplies in [redis-doc](https://github.com/redis/redis-doc). Instead of searching up in the documentation how a command is structured. You can just call a Swift function. In many cases where it is possible the return type from these functions is the set to the be the expected type. In situations where the type cannot be ascertained a `RESPToken` is returned and you'll need to convert the return type manually.

With the generated functions the code above becomes

```swift
let key = RedisKey(rawValue: "MyKey")
try await connection.set(key, "TestString")
let value = try await connection.get(key)
```

### Using generated RESPCommands and pipelining

In general you don't need to use this method as it has no advantages over using the generated functions. But `RESPCommands` has a function for each Redis command. Where the generated `RESPCommands` are useful is if you want to pipeline commands ie send multiple commands batched together and only wait for all of their responses in one place. You could pipeline the two commands above using

```swift
let key = RedisKey(rawValue: "MyKey")
let responses = try await connection.pipeline([
    .set(key, "TestString"),
    .get(key)
])
```

The `RedisConnection.pipeline` command returns an array of `RESPTokens`, one for each command. So we can get the result of the `get` in the above example by converting the second token into a `String`.

```swift
let value = responses[1].converting(to: String.self)
```