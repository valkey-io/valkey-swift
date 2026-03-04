# Using pipelining

Pipelining lets you issue multiple commands at once without waiting for a response to each individual command.

## Overview

Valkey pipelining is a technique for improving performance by issuing multiple commands at once without waiting for the response to each individual command.
Pipelining not only reduces the latency cost of waiting for the result of each command, but also reduces I/O costs on the server.
The server reads multiple commands with a single syscall and delivers multiple results with a single syscall.

### Send pipelined commands

In Valkey, each command has its own type that conforms to ``ValkeyCommand``.
This type takes the command parameters and declares an associated type, ``ValkeyCommand/Response``, that represents the expected response type.
``ValkeyClient/execute(_:)->(_,_)`` takes a parameter pack of ``ValkeyCommand`` types and returns a parameter pack of results with the corresponding response for each command.

```swift
let (_,_, getResult) = await valkeyClient.execute(
    SET(key: "foo", value: "100"),
    INCR(key: "foo"),
    GET(key: "foo")
)
// get returns an optional RESPBulkString
if let result = try getResult.get() {
    print(String(result)) // should print 101
}
```

### Build dynamic pipelines

The parameter pack implementation of pipelining lets you create static pipelines at compile time.
It doesn't support generating more dynamic pipelines based on runtime conditions.
To build dynamic pipelines at runtime, Valkey provides an API that takes an array of `any ValkeyCommand` and returns an array of `Result<RESPToken, Error>`.
This method returns a `Result` holding a ``RESPToken`` that requires decoding.

```swift
// Create command array.
var commands: [any ValkeyCommand] = []
commands.append(SET("foo", value: "100"))
commands.append(INCR("foo"))
commands.append(GET("foo"))
// execute commands
let results = await valkeyClient.execute(commands)
// Get the result and decode it as an optional String
// to avoid an error being thrown if the response is a null token.
if let value = results[2].get().decode(as: String?.self) {
    print(value)
}
```

For more information about decoding `RESPToken`, see <doc:RESPToken-Decoding>.

### Use pipelining with concurrency

Having multiple requests in transit on a single connection lets you share that connection across multiple concurrent tasks.
Valkey adds each request to a queue; as each response arrives, it removes the first request from the queue and delivers the response.
By using a single connection across multiple tasks, you can reduce the number of connections to your database.

```swift
try await client.withConnection { connection in
    try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask {
            try await connection.lpush("fooList", elements: ["bar"])
        }
        group.addTask {
            try await connection.rpush("fooList2", elements: ["baz"])
        }
        try await group.waitForAll()
    }
}
```

You can also use `async let` to issue commands without waiting for their results.

```swift
async let asyncResult = connection.lpush("fooList", elements: ["bar"])
// do something else
let result = try await asyncResult
```

Use caution when sharing a single connection across multiple tasks.
The result of a command becomes available only when the results of all previously queued commands have arrived.
A command that either blocks the connection or takes a long time affects the response time of commands that follow it.
