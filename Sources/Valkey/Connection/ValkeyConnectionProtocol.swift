//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Protocol for a Valkey connection that can send a command and get a response
public protocol ValkeyConnectionProtocol {
    /// Send RESP command to Valkey connection
    /// - Parameter command: ValkeyCommand structure
    /// - Returns: The command response as defined in the ValkeyCommand
    func send<Command: ValkeyCommand>(command: Command) async throws -> Command.Response
}
