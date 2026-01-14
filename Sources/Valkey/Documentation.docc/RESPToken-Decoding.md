# Decoding RESP

Decoding the contents of RESPToken

## Overview

The wire protocol valkey-swift uses is RESP3. It is simple, human readable and a fast protocol to parse. It can be used to serialize many different types including strings, integers, doubles, array and maps. More can be found out about RESP in the [Valkey Documentation](https://valkey.io/topics/protocol/).

We represent a raw RESP token using the type ``RESPToken``. A parsed RESP value is represented by the enum ``RESPToken/Value``. This includes cases for the different datatypes a RESP token can represent.

The majority of the Valkey commands return the Swift types equivalent to their expected response. eg `GET` returns a `ByteBuffer` containing the contents of the key, `STRLEN` returns the length of the contents as an `Int`. But there are a number of reasons for commands to not have a defined return type and in these cases a command may return the type ``RESPToken`` or one of the sequence types ``RESPToken/Array`` or ``RESPToken/Map``.

### Decoding RESPToken

A `RESPToken` contains the raw serialized bytes returned by the Valkey server. Valkey-swift introduces a protocol ``RESPTokenDecodable`` for types that can be decoded from a `RESPToken`. Many of Swift core types have been extended to conform to `RESPTokenDecodable`. There are two ways to decode a `RESPToken`. You can call ``RESPTokenDecodable/init(_:)``.

```swift
let string = String(respToken)
```

Or you can call the `RESPToken` method ``RESPToken/decode(as:)``. This can be chained onto the end of a command call eg `RPOP` can return a single value or an array of values so the function returns a `RESPToken` and the user should decode it based on whether they asked for multiple or a single value to be popped.

```swift
let string = try await valkeyClient.rpop("myList")?.decode(as: String.self)
```

### Decoding RESPToken.Array

When a command returns an array it is returned as an ``RESPToken/Array``. This can be to avoid the additional memory allocation of creating a Swift `Array` or because the array represents a more complex type. `RESPToken.Array` conforms to `Sequence` and its element type is a `RESPToken`. You can iterate over its contents and decode each element as follows.

```swift
let values = try await valkeyClient.smembers("mySet")
for value in values {
    let string = try value.decode(as: String.self)
    print(string)
}
```

Alternatively if you don't mind the additional allocation you can decode as a Swift `Array`

```swift
let values = try await valkeyClient.smembers("mySet").decode(as: [String].self)
```

The type of each element of a `RESPToken.Array` is not fixed. It is possible for values in the same array to represent different types. Decoding different types from an array is done using either `RESPToken.Array` method ``RESPToken/Array/decodeElements(as:)`` or `RESPToken` method ``RESPToken/decodeArrayElements(as:)``. The following code decodes the first element of an array as a `String` and the second as an `Int`.

```swift
let (member, score) = respToken.decodeArrayElements(as: (String, Int).self)
```

### Decoding RESPToken.Map

When a command returns a dictionary it is returned as a ``RESPToken/Map``. This can be to avoid the additional memory allocation of creating a Swift `Dictionary`, or a more complex type is being represented. `RESPToken.Map` conforms to `Sequence` and its element type is a key value pair of two `RESPToken`. You can iterate over its contents and decode its elements as follows.

```swift
let values = try await client.hgetall("hashKey")
for (keyToken, valueToken) in values {
    let key = try keyToken.decode(as: String.self)
    let value = try valueToken.decode(as: String.self)
    ...
}
```

Alternatively if you don't mind the additional allocation you can decode as a Swift `Dictionary`

```swift
let values = try await client.hgetall("hashKey")
    .decode(as: [String: String].self)
```

The type of each value in a `RESPToken.Map` is not fixed. It is possible for values in the same map to represent different types. You can decode specific fields from a map using either `RESPToken.Map` method ``RESPToken/Map/decodeValues(_:as:)`` or `RESPToken` method ``RESPToken/decodeMapValues(_:as:)``. The following code extracts two values with keys "member", "score"

```swift
let (member, score) = respToken.decodeMapValues("member", "score", as: (String, Int).self)
```

As a `RESPToken.Map` is just a sequence of key value pairs access by key name is a O(n) process where n is the number of entries in the map.

## RESPBulkString

Where a command response is a RESP bulk string eg `GET`, it returns a ``RESPBulkString`` type. RESP bulk strings can be either UTF-8 Strings or binary blobs. Valkey swift provides initializers for both `String` and `ByteBuffer` to access the bulk string as either UTF-8 or binary blob.

```swift
// Get value as a String
let value = try await client.get("key").map { String($0) }
// Get value as a ByteBuffer
let value = try await client.get("key").map { ByteBuffer($0) }
```

`RESPBulkString` conforms to protocol `RandomAccessCollection` where `Element == UInt8` so you can access it's raw bytes using any of the methods available to you via that protocol.

```swift
if let response = try await connection.get("key") {
    print("\(response[0]), \(response[1])")
}
```

`RESPBulkString` also provides high performance read only access to it's raw bytes using ``RESPBulkString/bytes`` and ``RESPBulkString/span`` which return a `RawSpan` and `Span<UInt8>` respectively.

```swift
if let response = try await connection.get("key") {
    let span = response.span
    print("\(span[0]), \(span[1])")
}
```