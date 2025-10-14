//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

/// Error throw by transaction functions
public enum ValkeyTransactionError: Error {
    /// Transaction was aborted because a watched value was modified
    case transactionAborted
    /// Transaction was discarded because of previous error queuing commands
    case transactionErrors(queuedResults: [Result<RESPToken, Error>])
}
