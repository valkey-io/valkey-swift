# ``Valkey/ValkeyClient``

## Topics

### Creating a client

- ``Valkey/ValkeyClient/init(_:configuration:eventLoopGroup:logger:)``

### Running operations within a connection

- ``Valkey/ValkeyClient/withConnection(isolation:operation:)``
- ``Valkey/ValkeyClient/send(command:)``

### Pipelining commands

- ``Valkey/ValkeyClient/pipeline(_:)``
