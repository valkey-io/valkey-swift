//===----------------------------------------------------------------------===//
//
// This source file is part of the valkey-swift open source project
//
// Copyright (c) 2025 the valkey-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of valkey-swift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

@usableFromInline
enum ValkeySubscriptionFilter: Equatable, Hashable, Sendable {
    case channel(String)
    case pattern(String)
    case shardChannel(String)
}

extension ValkeySubscriptionFilter: CustomStringConvertible {
    @usableFromInline
    var description: String {
        switch self {
        case .channel(let string):
            "channel(\(string))"
        case .pattern(let string):
            "pattern(\(string))"
        case .shardChannel(let string):
            "shardChannel(\(string))"
        }
    }
}
