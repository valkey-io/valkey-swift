# Using transactions

Perform atomic operations.

## Overview

Transactions let you group multiple commands into an atomic operation. Requests from other clients aren't processed during a transaction. Valkey uses the commands `MULTI` and `EXEC` to set up and execute a transaction. After initiating a transaction with `MULTI`, commands return a simple string `QUEUED` to indicate the server queued the commands. When the client sends the `EXEC` command, the server executes all the queued commands and returns an array with their results.

Because of this behavior, the Valkey client provides a dedicated API for executing transactions. The transaction API accepts a parameter pack of commands, similar to pipelining; for more information, see <doc:Pipelining>.

```swift
try await valkeyClient.withConnection { connection in
    let results = try await connection.transaction(
        SET("foo", value: "100"),
        LPUSH("queue", elements: ["foo"])
    )
    let lpushResponse = try results.1.get()
}
```

### Understand rollbacks

Valkey doesn't support rollbacks of transactions for simplicity and performance.

### Use check-and-set

The `WATCH` command adds check-and-set behavior to Valkey transactions.
This sets up a list of keys to watch, and if Valkey detects any changes to them before the next transaction runs on the same connection, that transaction fails.

For example, suppose you want to atomically increment a counter (assuming you don't have the INCR command). A simple implementation looks like this:

```swift
// get value, otherwise default to 0
let value = try await connection.get("counter").map { Int(String(buffer: $0)) } ?? 0
try await connection.set("counter", String(value + 1))
```

This isn't a reliable solution because another client can increment the key `counter` between the `GET` and `SET` commands, applying the increment to the wrong value.
By using `WATCH` and executing the `SET` inside a transaction, you can avoid this race condition.
If another client edits the key between the `WATCH` and `SET` commands, the transaction fails and throws a `ValkeyClientError(.transactionAborted)` error.
When this error occurs, you know another client edited the key between these two commands, so you retry the operation.

```swift
while true {
    try await connection.watch(keys: ["counter"])
    let value = try await connection.get("counter").map { Int(String(buffer: $0)) } ?? 0
    do {
        let result = try await connection.transaction(
            SET("counter", String(value + 1))
        )
        // set was successful; break out of the while loop
        break
    } catch let error as ValkeyClientError where error.errorCode == .transactionAborted {
        // Canceled SET because "counter" was edited after WATCH, try again
    }
}
```

For more information about Valkey transactions, see the [Valkey documentation](https://valkey.io/topics/transactions/).