# ``Valkey``

A Swift client library for Valkey.

## Overview

Valkey-swift is a swift based client for Valkey, the high-performance key/value datastore. It supports all the Valkey commands, pipelining, transactions, subscriptions and Valkey clusters.

## Topics

### Articles

- <doc:getting-started>
- <doc:Pipelining>
- <doc:Pubsub>
- <doc:Transactions>

### Client

- ``ValkeyClient``
- ``ValkeyClientConfiguration``
- ``ValkeyClientProtocol``
- ``ValkeyServerAddress``
- ``ValkeyConnection``
- ``ValkeyConnectionConfiguration``

### Commands

- ``ValkeyCommand``
- ``ValkeyCommandEncoder``
- ``ValkeyKey``

### RESP Protocol

- ``RESPToken``
- ``RESPRenderable``
- ``RESPStringRenderable``
- ``RESPTokenDecodable``
- ``RESPTypeIdentifier``

### Subscriptions

- ``ValkeySubscription``
- ``ValkeySubscriptionMessage``

### Errors

- ``ValkeyClientError``
- ``RESPParsingError``

### Cluster

- ``ValkeyClusterClient``
- ``ValkeyNodeDiscovery``
- ``ValkeyNodeDescriptionProtocol``
- ``ValkeyStaticNodeDiscovery``
- ``ValkeyClusterDescription``
- ``HashSlot``
- ``HashSlots``

