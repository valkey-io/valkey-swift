# Decoding RESP

Decode the contents of a RESP token to access Valkey command responses.

## Overview

Valkey uses the RESP3 wire protocol.
It's simple, human-readable, and fast to parse.
It can serialize many different types, including strings, integers, doubles, arrays, and maps.
For more information about RESP, see the [Valkey documentation](https://valkey.io/topics/protocol/).

The Valkey client represents a raw RESP token using ``RESPToken``.
``RESPToken/Value`` is an enum representing a parsed RESP value, with cases for each data type a RESP token can represent.

Most Valkey commands return the Swift equivalent of their expected response type.
For example, `STRLEN` returns the length of a key's value as an `Int`, and `GET` returns a ``RESPBulkString`` containing the key's value.
Some commands don't have a defined return type; in those cases, a command returns ``RESPToken`` or one of the sequence types ``RESPToken/Array`` or ``RESPToken/Map``.

### Decode a response token

A `RESPToken` contains the raw serialized bytes returned by the Valkey server.
Valkey defines a protocol ``RESPTokenDecodable`` for types that can be decoded from a `RESPToken`.
Many Swift standard library types conform to `RESPTokenDecodable`.
You can decode a `RESPToken` in two ways. Call ``RESPTokenDecodable/init(_:)``:

```swift
let string = String(respToken)
```

Alternatively, call the `RESPToken` method ``RESPToken/decode(as:)``.
This method chains onto the end of a command call.
For example, `RPOP` can return a single value or an array of values, so the function returns a `RESPToken` and you decode the result based on whether you requested one or more values to be popped.

```swift
let string = try await valkeyClient.rpop("myList")?.decode(as: String.self)
```

### Decode an array of response tokens

When a command returns an array, Valkey returns it as an ``RESPToken/Array``.
This avoids the additional memory allocation of creating a Swift `Array`; it can also indicate that the array represents a more complex type.
`RESPToken.Array` conforms to `Sequence` and its element type is a `RESPToken`.
You can iterate over its contents and decode each element as follows:

```swift
let values = try await valkeyClient.smembers("mySet")
for value in values {
    let string = try value.decode(as: String.self)
    print(string)
}
```

Alternatively, if you don't mind the additional allocation, you can decode as a Swift `Array`.

```swift
let values = try await valkeyClient.smembers("mySet").decode(as: [String].self)
```

Values in the same array can represent different types.
Use either the `RESPToken.Array` method ``RESPToken/Array/decodeElements(as:)`` or the `RESPToken` method ``RESPToken/decodeArrayElements(as:)`` to decode different types from an array.
The following code decodes the first element of an array as a `String` and the second as an `Int`.

```swift
let (member, score) = respToken.decodeArrayElements(as: (String, Int).self)
```

### Decode a map of response tokens

When a command returns a dictionary, Valkey returns it as a ``RESPToken/Map``.
This avoids the additional memory allocation of creating a Swift `Dictionary`; it can also indicate that the map represents a more complex type.
`RESPToken.Map` conforms to `Sequence` and its element type is a key-value pair of `RESPToken` values.
You can iterate over its contents and decode its elements as follows:

```swift
let values = try await client.hgetall("hashKey")
for (keyToken, valueToken) in values {
    let key = try keyToken.decode(as: String.self)
    let value = try valueToken.decode(as: String.self)
    ...
}
```

Alternatively, if you don't mind the additional allocation, you can decode as a Swift `Dictionary`.

```swift
let values = try await client.hgetall("hashKey")
    .decode(as: [String: String].self)
```

Values in the same map can represent different types.
Use either the `RESPToken.Map` method ``RESPToken/Map/decodeValues(_:as:)`` or the `RESPToken` method ``RESPToken/decodeMapValues(_:as:)`` to decode specific fields from a map.
The following code extracts two values with keys `"member"` and `"score"`:

```swift
let (member, score) = respToken.decodeMapValues("member", "score", as: (String, Int).self)
```

Accessing a value by key name is an O(n) operation, where *n* is the number of entries in the map.

### Decode bulk string values

When a command response is a RESP bulk string — for example, `GET` — the command returns a ``RESPBulkString``.
RESP bulk strings can be either UTF-8 strings or binary blobs.
Valkey provides initializers for both `String` and `ByteBuffer` to access the content as a UTF-8 string or binary data.

```swift
// Get value as a String
let value = try await client.get("key").map { String($0) }
// Get value as a ByteBuffer
let value = try await client.get("key").map { ByteBuffer($0) }
```

`RESPBulkString` conforms to protocol `RandomAccessCollection` where `Element == UInt8`, so you can access its raw bytes using any `RandomAccessCollection` method.

```swift
if let response = try await connection.get("key") {
    print("\(response[0]), \(response[1])")
}
```

`RESPBulkString` also provides high-performance, read-only access to its raw bytes using ``RESPBulkString/bytes`` and ``RESPBulkString/span``, which return a `RawSpan` and `Span<UInt8>` respectively.

```swift
if let response = try await connection.get("key") {
    let span = response.span
    print("\(span[0]), \(span[1])")
}
```
