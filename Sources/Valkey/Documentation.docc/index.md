# ``Valkey``

Connect to and interact with a Valkey database from Swift.

## Overview

This package provides a Swift client for Valkey, the high-performance key-value data store.
It supports all the Valkey commands, pipelining, transactions, subscriptions, and Valkey clusters.

## Topics

### Articles

- <doc:getting-started>
- <doc:Pipelining>
- <doc:RESPToken-Decoding>
- <doc:Pubsub>
- <doc:Transactions>

### Client

- ``ValkeyClient``
- ``ValkeyClientConfiguration``
- ``ValkeyClientProtocol``
- ``ValkeyServerAddress``
- ``ValkeyConnection``
- ``ValkeyConnectionConfiguration``
- ``ValkeyTracingConfiguration``

### Commands

- ``ValkeyCommand``
- ``ValkeyCommandEncoder``
- ``ValkeyKey``

### RESP Protocol

- ``RESPToken``
- ``RESPBulkString``
- ``RESPRenderable``
- ``RESPStringRenderable``
- ``RESPTokenDecodable``
- ``RESPTypeIdentifier``

### Subscriptions

- ``ValkeySubscription``
- ``ValkeySubscriptionMessage``
- ``ValkeySubscribeCommand``
- ``ValkeySubscriptionFilter``

### Errors

- ``ValkeyClientError``
- ``ValkeyClusterError``
- ``ValkeyTransactionError``
- ``RESPDecodeError``
- ``RESPParsingError``

### Cluster

- ``ValkeyClusterClient``
- ``ValkeyClusterClientConfiguration``
- ``ValkeyNodeDiscovery``
- ``ValkeyNodeDescriptionProtocol``
- ``ValkeyStaticNodeDiscovery``
- ``ValkeyClusterDescription``
- ``HashSlot``
- ``HashSlots``

