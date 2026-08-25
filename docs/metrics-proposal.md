# Metrics proposal

This document is a proposal for the metrics that valkey-swift should record

The metrics labels and dimensions included in this document should be configurable.

## Command execution

`valkey.command.duration`
  - type: Timer
  - dimensions: (status: [ok, error, timeout, cancelled], command: Command name)
Record the time a command took to execute. Can be used to find out which commands are causing slowdown. Include status as a commands duration will be affected by these and could produce false positives. A command that returns an error immediately should not be grouped with a command that returns a result.

`valkey.pipeline.duration`
  - type: Timer
  - dimensions: ?
Record the time a pipeline took to execute. Unsure about dimensions as a pipeline of 2 commands will run a lot faster than a pipeline of 32 commands. But including the length as a dimension could be open to spamming the metrics backend.

`valkey.pipeline.length`
  - type: Recorder
Record the length of a pipeline. Check for exceptionally long pipelines.

`valkey.transaction.duration`
  - type: Timer
  - dimensions: ?
Record the time a transaction took to execute. Similar thoughts about dimensions

`valkey.transaction.length`
  - type: Recorder
Record the length of a transaction. Check for exceptionally long transaction.

## Connection Pool

`valkey.connection-pool.connections`
  - type: Meter
  - dimensions: network address
Number of open connections. Include network address as dimension to disambiguate between different nodes in a cluster.

`valkey.connection-pool.state`
  - type: Meter
  - dimensions: network address
Connection pool state. Using a meter here (0=runing, 1=connection failing etc).

`valkey.connection-pool.requests`
  - type: Meter
  - dimensions: network address
Number of requests waiting for a connection 

`valkey.connection-pool.idle`
  - type: Meter
  - dimensions: network address
Number of idle connections. Include network address as dimension to disambiguate between different nodes in a cluster.

`valkey.connection-pool.leased`
  - type: Meter
  - dimensions: network address
Number of leased connections. Include network address as dimension to disambiguate between different nodes in a cluster.
`valkey.connection-pool.connectionsCreated`
  - type: Counter
  - dimensions: network address
Number of connections created.

`valkey.connection-pool.connectionsFailed`
  - type: Counter
  - dimensions: network address
Number of failed connection attempts.

`valkey.connection-pool.connectionCreationTime`
  - type: Timer
  - dimensions: network address
Number of failed connection attempts.

`valkey.connection-pool.requestsFulfilled`
  - type: Counter
  - dimensions: network address
Number of requests that are successful.

`valkey.connection-pool.requestsFailed`
  - type: Counter
  - dimensions: network address
Number of requests that failed.

`valkey.connection-pool.requestTime`
  - type: Timer
  - dimensions: network address
Time it took for request to receive connection.

