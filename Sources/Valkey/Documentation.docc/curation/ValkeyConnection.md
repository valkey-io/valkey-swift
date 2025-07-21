# ``Valkey/ValkeyConnection``

## Topics

### Establishing a connection

- ``connect(address:connectionID:name:configuration:eventLoop:logger:)``

### Sending commands

- ``send(command:)``

### Pipelining commands

- ``pipeline(_:)``

### Subscribing

- ``subscribe(to:isolation:process:)-(String...,_,_)``
- ``subscribe(to:isolation:process:)-([String],_,_)``
- ``ssubscribe(to:isolation:process:)-(String...,_,_)``
- ``ssubscribe(to:isolation:process:)-([String],_,_)``
- ``subscribeKeyInvalidations(process:)``
- ``psubscribe(to:isolation:process:)-(String...,_,_)``
- ``psubscribe(to:isolation:process:)-([String],_,_)``

### Working with transactions

- ``multi()``
- ``transaction(_:)``
- ``transaction(_:_:)``
- ``transaction(_:_:_:)``
- ``transaction(_:_:_:_:)``
- ``transaction(_:_:_:_:)``
- ``transaction(_:_:_:_:_:)``
- ``transaction(_:_:_:_:_:_:)``
- ``transaction(_:_:_:_:_:_:_:)``
- ``transaction(_:_:_:_:_:_:_:_:)``
- ``transaction(_:_:_:_:_:_:_:_:_:)``
- ``transaction(_:_:_:_:_:_:_:_:_:_:)``
- ``exec()``
- ``discard()``

### Watching transactions

- ``watch(keys:)``
- ``unwatch()``

### Closing a connection

- ``close()``

### Inspecting a connection

- ``id``
- ``unownedExecutor``

