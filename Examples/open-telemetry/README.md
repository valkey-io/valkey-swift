# OpenTelemetry example

An example HTTP server that uses a Valkey client, both of which emit Distributed Tracing spans
via [Swift OTel](https://github.com/swift-otel/swift-otel).

## Overview

This example bootstraps Swift OTel to export Distributed Tracing spans to Jaeger.

It then starts a Hummingbird HTTP server along with its associated middleware for instrumentation.

Finally, the server uses a Valkey client in its request handler to demonstrate the spans
created by executing various Valkey commands.

## Testing

The example uses [Docker Compose](https://docs.docker.com/compose) to run a Valkey server alongside Jaeger to collect
and visualize the spans from the HTTP server and Valkey client, which is running on your local machine.

### Running Valkey and Jaeger

In one terminal window, run the following command:

```console
% docker compose up
[+] Running 4/4
 ✔ Network open-telemetry_default       Created                                          0.0s
 ✔ Volume "open-telemetry_valkey_data"  Created                                          0.0s
 ✔ Container open-telemetry-jaeger-1    Created                                          0.0s
 ✔ Container open-telemetry-valkey-1    Created                                          0.0s
...
```

### Running the server

Now, in another terminal, run the server locally using the following command:

```console
% swift run
```

### Making some requests

Finally, in a third terminal, make a request to the server:

```console
% curl http://localhost:8080/compute/42
```

The example server fakes an expensive algorithm which is hard-coded to take a couple of seconds to complete.
That's why the first request will take a decent amount of time.

Now, make the same request again:

```console
% curl http://localhost:8080/compute/42
```

You should see that it returns instantaniously. We successfully cached the previously computed value in Valkey
and can now read it from the cache instead of re-computing it each time.

### Visualizing the traces using Jaeger UI

Visit Jaeger UI in your browser at [localhost:16686](http://localhost:16686).

Select `example` from the dropdown and click `Find Traces`.

You should see a handful of traces, including:

#### `/compute/{x}` with an execution time of ~ 3.2 seconds

This corresponds to the first request to `/42` where we had to compute the value. Click on this trace to reveal
its spans. The root span represents our entire Hummingbird request handling. Nested inside are three child spans:

1. `HGET`: Shows the `HGET` Valkey command used to look up the cached value for `42`.
2. `compute`: Represents our expensive algorithm. We can see that this takes up the majority of the entire trace.
3. `HSET`: Shows the `HSET` Valkey command sent to store the computed value for future retrieval.

#### `/compute/{x}` with an execution time of a few milliseconds

This span corresponds to a subsequent request to `/42` where we could utelize our cache to avoid the
expensive computation. Click on this trace to reveal its spans. Like before, the root span represents
the Hummingbird request handling. We can also see a single child span:

1. `HGET`: Shows the `HGET` Valkey command used to look up the cached value for `42`.

### Making some more requests

The example also comes with a few more API endpoints to demonstrate other Valkey commands:

#### Pipelined commands

Send the following request to kick off multiple pipelined commands:

```console
% curl http://localhost:8080/multi
```

This will run three pipelined `EVAL` commands and produces a trace made up of the following spans:

1. `/multi`: The Hummingbird request handling.
2. `MULTI`: The Valkey client span representing the execution of the pipelined commands.

Click on the `MULTI` span to reveal its attributes. New here are the following two attributes:

- `db.operation.batch.size`: This is set to `3` and represents the number of pipelined commands.
- `db.operation.name`: This is set to `MULTI EVAL`, showing that the pipeline consists only of `EVAL` commands.

#### Failing commands

Send the following request to send some gibberish to Valkey resulting in an error:

```console
% curl http://localhost:8080/error
```

This will send an `EVAL` command with invalid script contents (`EVAL not a script`) resulting in a trace
made up of the following spans:

1. `/error`: The Hummingbird request handling.
2. `EVAL`: The Valkey client span representing the failed `EVAL` command.

Click on the `EVAL` span to reveal its attributes. New here are the following two attributes:

- `db.response.status_code`: This is set to `ERR` and represents the prefix of the simple error returned
by Valkey.
- `error`: This is set to `true` indicating that the operation failed. In Jaeger, this is additionally displayed
via a red exclamation mark next to the span name.
