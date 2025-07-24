# Pipelining Commands

Sending multiple commands at once without waiting for the response of each command

Valkey pipelining is a technique for improving performance by issuing multiple commands at once without waiting for the response to each individual command. Pipelining not only reduces the latency cost of waiting for the result of each command it also reduces the cost to the server as it reduces I/O costs. Multiple commands can be read with a single syscall, and multiple results are delivered with a single syscall. 

## Implementation

In valkey-swift each command has its own type conforming to the protocol ``ValkeyCommand``. This type is initialized with the parameters of the command and has an `associatedtype` ``ValkeyCommand/Response`` which is the expected response type of the command. The ``ValkeyClient/pipeline(_:)`` command takes a parameter pack of types conforming to ``ValkeyCommand`` and returns a parameter pack containing the results holding the corresponding responses of each command.

```swift
let (_,_, getResult) = await valkeyClient.pipeline(
    SET(key: "foo", value: "100"),
    INCR(key: "foo")
    GET(key: "foo")
)
// get returns an optional ByteBuffer
if let result = try getResult.get().map({ String(buffer: $0) }) {
    print(result) // should print 101
}
```

## Pipelining and Concurrency

Being able to have multiple requests in transit on a single connection means we can have multiple tasks use that connection concurrently. Each request is added to a queue and as each response comes back the first request on the queue is popped off and given the response. By using a single connection across multiple tasks you can reduce the number of connections to your database.

```swift
try await client.withConnection { connection in
    try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask {
            _ = try await connection.lpush(key: "fooList", element: ["bar"])
        }
        group.addTask {
            _ = try await connection.rpush(key: "fooList2", element: ["baz"])
        }
        try await group.waitForAll()
    }
}
```

You can also use `async let` to run commands without waiting for their results immediately.

```swift
async let asyncResult = connection.lpush(key: "fooList", element: ["bar"])
// do something else
let result = try await asyncResult
```

Be careful when using a single connection across multiple Tasks though. The result of a command will only become available when the result of any previous command queued has been made available. So a command that either blocks the connection or takes a long time could affect the response time of commands that follow it.