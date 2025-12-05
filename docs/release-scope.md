# Valkey-Swift 1.0 Release Scope

This page outlines the complete scope, feature requirements, and readiness checklist for the **Valkey-Swift 1.0** release.

---

## Contents
- [Commands](#commands)
- [Pipelines](#pipelines)
- [Transactions](#transactions)
- [Error Handling](#error-handling)
- [Security](#security)
- [Timeouts and Retries](#timeouts-and-retries)
- [Cluster Mode Support](#cluster-mode-support)
- [Debug-ability](#debug-ability)
- [Load Balancing](#load-balancing)
- [Circuit Breaking](#circuit-breaking)
- [Additional Items](#additional-items)
- [1.0 Release Readiness Checklist](#10-release-readiness-checklist)

---

# Commands

## Command Coverage
Valkey-Swift uses a code generator based on JSON definitions from the Valkey server repository.

- Full support for all standard commands  
- Support for JSON and Bloom module commands  

## Command Return Types
- Avoid returning raw `RESPToken` or `ByteBuffer` unless they map directly to primitives  
- Provide typed responses for complex structures  
- Reduce decoding burden for client applications  

---

# Pipelines

- Support for **node-level** and **cluster-level** pipelines  
- Pipelines return standardized Swift types  
- `ASK` and `MOVED` redirections handled transparently  

---

# Transactions

- Support for node-level and cluster-level transactions  
- Transactions return typed responses  
- Automatic handling of redirections (`ASK`, `MOVED`)  

---

# Error Handling

- All errors are typed using **`ValkeyClientError`**  
- Should include:
  - File name  
  - Line number  
  - Description  

### Notes
- File/line capture not implemented yet  
- Some NIO limits affect error propagation  
- Backward compatibility must be maintained  

---

# Security

## TLS / mTLS
- TLS supported  
- mTLS supported via SwiftNIO TLS  

## Authentication
- Username/password authentication supported  

---

# Timeouts and Retries

## Retries
- Retry logic is **not** part of 1.0

## Timeouts
- Command timeout  
- Blocking command timeout  

---

# Cluster Mode Support

## Redirections
Must handle:
- `ASK`  
- `MOVED`  

For:
- Commands  
- Pipelines  
- Transactions  

## Read From Replicas
- `READONLY` supported  
- Graceful shutdown pending upstream fix  

## Topology Changes
Client should:
- Handle failovers + resharding  
- Refresh topology after failures  
- Refresh immediately on `MOVED`  

---

# Debug-ability

## Logging
- Logging at crucial code paths  
- Defaults to debug/trace  
- Application handles top-level error logs  

## Observability
Out of scope for 1.0:
- Latency metrics  
- Throughput  
- Failure rate  
- Command profiling  

---

# Load Balancing

Supported:
- Round-robin (in progress)  
- Random strategy  

Not in 1.0:
- Weighted LB  
- Latency-aware LB  

---

# Circuit Breaking

Not part of 1.0. Future plans:
- Detect unhealthy nodes  
- Health-check integration  

---

# Additional Items

- Resolve remaining GitHub issues  
- Document API behaviors and design choices  

---

# 1.0 Release Readiness Checklist

| Area | Description | Status |
|------|-------------|--------|
| Command Coverage | [All standard commands implemented with typed return values](#command-coverage) | ☐ |
| Pipelines | [Node + cluster pipelines tested and validated](#pipelines) | ☑ |
| Transactions | [Cluster transaction support functional](#transactions) | ☑ |
| Error Handling | [Typed errors with file/line capture](#error-handling) | ☐ |
| Security | [TLS/mTLS validated](#security) | ☑ |
| Cluster Mode | [ASK/MOVED + READONLY + topology refresh](#cluster-mode-support) | ☑ |
| Logging | [Debug/trace logs added across critical paths](#debug-ability) | ☐ |
| Timeouts | [Command timeout support](#timeouts-and-retries) | ☑ |
| Pending Issues | [Resolve critical GitHub issues](#additional-items) | ☐ |
| Documentation | API docs + changelog finalized | ☐ |
| GitHub Release | 1.0 tag + changelog published | ☐ |

### Notes
- **☐** = Planned for 1.0  
- **☑** = Completed 