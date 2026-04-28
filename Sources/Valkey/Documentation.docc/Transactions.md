# Using transactions

Perform atomic operations.

## Overview

Transactions let you group multiple commands into an atomic operation. Requests from other clients aren't processed during a transaction. Valkey uses the commands `MULTI` and `EXEC` to set up and execute a transaction. After initiating a transaction with `MULTI`, commands return a simple string `QUEUED` to indicate the server queued the commands. When the client sends the `EXEC` command, the server executes all the queued commands and returns an array with their results.

Because of this behavior, the Valkey client provides a dedicated API for executing transactions. The transaction API accepts a parameter pack of commands, similar to pipelining; for more information, see <doc:Pipelining>.

@Snippet(path: "valkey-swift/Snippets/Docc/Transactions", slice: "transaction")

### Understand rollbacks

Valkey doesn't support rollbacks of transactions for simplicity and performance.

### Use check-and-set

The `WATCH` command adds check-and-set behavior to Valkey transactions.
This sets up a list of keys to watch, and if Valkey detects any changes to them before the next transaction runs on the same connection, that transaction fails.

For example, suppose you want to atomically increment a counter (assuming you don't have the INCR command). A simple implementation looks like this:

@Snippet(path: "valkey-swift/Snippets/Docc/Transactions", slice: "incr-simple")

This isn't a reliable solution because another client can increment the key `counter` between the `GET` and `SET` commands, applying the increment to the wrong value.
By using `WATCH` and executing the `SET` inside a transaction, you can avoid this race condition.
If another client edits the key between the `WATCH` and `SET` commands, the transaction fails and throws a `ValkeyClientError(.transactionAborted)` error.
When this error occurs, you know another client edited the key between these two commands, so you retry the operation.

@Snippet(path: "valkey-swift/Snippets/Docc/Transactions", slice: "incr-transaction")

For more information about Valkey transactions, see the [Valkey documentation](https://valkey.io/topics/transactions/).