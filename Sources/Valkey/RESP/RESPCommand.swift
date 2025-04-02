//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-redis open source project
//
// Copyright (c) 2025 Apple Inc. and the swift-redis project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-redis project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore

/// A RESP command that can be executed on a connection.
public protocol RESPCommand {
    associatedtype Response: RESPTokenRepresentable = RESPToken

    func encode(into commandEncoder: inout RESPCommandEncoder)
}
