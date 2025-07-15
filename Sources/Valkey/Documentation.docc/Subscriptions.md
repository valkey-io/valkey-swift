# Subscriptions

Implementing Pub/Sub using valkey-swift

## Overview

Valkey provides publish/subscribe messaging support via the PUBLISH, SUBSCRIBE and UNSUBSCRIBE commands. Using valkey-swift we can subscribe to a single or multiple channels and receive every message pusblished to the channel in an AsyncSequence.

```swift
try await 