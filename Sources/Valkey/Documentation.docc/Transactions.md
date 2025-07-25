# Transactions

Perform atomic operations.

Transactions allow you to group multiple commands into an atomic operation. A request sent by another client will not be processed in the middle of the execution of a transaction. Valkey uses the commands `MULTI` and `EXEC` to setup and execute a transaction. After having initiated a transaction with `MULTI`, commands just return a simple string `QUEUED` to indicate the command has been queued. When the `EXEC` command is sent all the queued commands are executed and an array is returned with their results. 

Because of this custom behaviour valkey-swift provides extra support for executing transactions. The API is very similar to the pipelining function which accepts a parameter pack of commands, detailed in <doc:Pipelining>.

```swift
let results = try await valkeyClient.transaction(
    SET("foo", value: "100"),
    LPUSH("queue", elements: ["foo"])
)
let lpushResponse = try results.1.get()
```

### Rollbacks

Valkey does not support rollbacks of transactions for simplicity and performance reasons. 

### Check and set

The transaction command `WATCH` is used to add a check-and-set behaviour to Valkey transactions. This sets up a list of keys to WATCH, and if any changes to them are detected before the next transaction is executed on the same connection, then that transaction will fail.

For instance imagine we wanted to atomically increment a counter (assuming we don't have the INCR command). A simple implementation might look like this.

```swift
// get value, otherwise default to 0
let value = try await connection.get("counter").map { Int(String(buffer: $0)) } ?? 0
try await connection.set("counter", String(value + 1))
```

Unfortunately this would not be a reliable solution as another client could attempt to increment the key "counter" inbetween the GET and SET commands and the increment would be applied to the wrong value. Using WATCH we can avoid this. If the key is edited between the WATCH and SET the transaction will fail and throw a `ValkeyClientError(.transactionAborted)` error. If this occurs we know the key was edited between these two commands and we need to update the "counter" value before trying to call SET again, so we run the operation again.

```swift
while true {
    try await connection.watch(keys: ["counter"])
    let value = try await connection.get("counter").map { Int(String(buffer: $0)) } ?? 0
    do {
        let result = try await connection.transaction(
            SET("counter", String(value + 1))
        )
        // set was succesful break out of the while loop
        break
    } catch let error as ValkeyClientError where error.errorCode == .transactionAborted {
        // Cancelled SET because "counter" was edited after WATCH, try again
    }
}
```

More can be found out about Valkey transactions in the [Valkey documentation](https://valkey.io/topics/transactions/).