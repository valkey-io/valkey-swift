//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey project
//
// Copyright (c) 2025 the swift-valkey authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See swift-valkey/CONTRIBUTORS.txt for the list of swift-valkey authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

extension LPOP {
    /// - Returns: One of the following:
    ///     * [Null](https:/valkey.io/topics/protocol/#nulls): if the key does not exist.
    ///     * [Bulk string](https:/valkey.io/topics/protocol/#bulk-strings): when called without the _count_ argument, the value of the first element.
    ///     * [Array](https:/valkey.io/topics/protocol/#arrays): when called with the _count_ argument, a list of popped elements.
    public typealias Response = [String]?
}

extension LPOS {
    /// - Returns: Any of the following:
    ///     * [Null](https:/valkey.io/topics/protocol/#nulls): if there is no matching element.
    ///     * [Integer](https:/valkey.io/topics/protocol/#integers): an integer representing the matching element.
    ///     * [Array](https:/valkey.io/topics/protocol/#arrays): If the COUNT option is given, an array of integers representing the matching elements (or an empty array if there are no matches).
    public typealias Response = [Int]?
}

extension RPOP {
    /// - Returns: One of the following:
    ///     * [Null](https:/valkey.io/topics/protocol/#nulls): if the key does not exist.
    ///     * [Bulk string](https:/valkey.io/topics/protocol/#bulk-strings): when called without the _count_ argument, the value of the last element.
    ///     * [Array](https:/valkey.io/topics/protocol/#arrays): when called with the _count_ argument, a list of popped elements.
    public typealias Response = [String]?
}
