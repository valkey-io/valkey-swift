//
// This source file is part of the valkey-swift project
// Copyright (c) 2025-2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

// MARK: Backwards compatibility

extension FT.AGGREGATE.Load {
    @inlinable
    public static func fields(_ fields: [String]) -> Self {
        .fields(fields.map { FT.AGGREGATE.LoadFields(field: $0) })
    }
}
