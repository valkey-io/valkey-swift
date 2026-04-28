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

@Snippet(path: "valkey-swift/Snippets/Docc/Pipelining", slice: "pipelining")

### Build dynamic pipelines

The parameter pack implementation of pipelining lets you create static pipelines at compile time.
It doesn't support generating more dynamic pipelines based on runtime conditions.
To build dynamic pipelines at runtime, Valkey provides an API that takes an array of `any ValkeyCommand` and returns an array of `Result<RESPToken, Error>`.
This method returns a `Result` holding a ``RESPToken`` that requires decoding.

@Snippet(path: "valkey-swift/Snippets/Docc/Pipelining", slice: "dynamic")

For more information about decoding `RESPToken`, see <doc:RESPToken-Decoding>.

### Use pipelining with concurrency

Having multiple requests in transit on a single connection lets you share that connection across multiple concurrent tasks.
Valkey adds each request to a queue; as each response arrives, it removes the first request from the queue and delivers the response.
By using a single connection across multiple tasks, you can reduce the number of connections to your database.

@Snippet(path: "valkey-swift/Snippets/Docc/Pipelining", slice: "concurrency")

You can also use `async let` to issue commands without waiting for their results.

@Snippet(path: "valkey-swift/Snippets/Docc/Pipelining", slice: "async-let")

Use caution when sharing a single connection across multiple tasks.
The result of a command becomes available only when the results of all previously queued commands have arrived.
A command that either blocks the connection or takes a long time affects the response time of all the commands that follow it.
