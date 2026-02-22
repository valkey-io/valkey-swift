//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import Testing

@testable import Valkey

/// Tests for ValkeyCommand key extraction with existential types.
///
/// Swift's associated types experience type erasure when accessed through existential types
/// (`any Protocol`). For ValkeyCommand, the `keysAffected` property uses an associated type
/// `Keys: Collection<ValkeyKey>`, which becomes inaccessible when commands are stored in
/// arrays like `[any ValkeyCommand]`.
///
/// This is problematic for cluster mode, where the client needs to extract keys from commands
/// to determine which cluster node should handle them. When key extraction fails, transactions
/// and pipelines are routed incorrectly, causing unnecessary redirects.
///
/// The `keysAffectedArray` property provides a type-erased alternative that returns `[ValkeyKey]`,
/// a concrete type that works correctly with existential types.
@Suite("ValkeyCommand Tests")
struct ValkeyCommandTests {

    /// Verifies that keysAffectedArray extracts keys correctly from type-erased command arrays.
    ///
    /// When commands are stored as `[any ValkeyCommand]`, accessing the `keysAffected` property
    /// returns empty due to Swift's associated type erasure. The `keysAffectedArray` property
    /// works around this limitation by using a concrete return type.
    @Test func testKeysAffectedArrayWithExistentialTypes() async throws {
        let key1 = ValkeyKey("test-key-1")
        let key2 = ValkeyKey("test-key-2")
        let command1 = SET(key1, value: "value1")
        let command2 = GET(key2)

        // Store commands in type-erased array (common pattern in cluster client)
        var commands: [any ValkeyCommand] = []
        commands.append(command1)
        commands.append(command2)

        // keysAffectedArray successfully extracts keys through existential types
        let keysFromArray = commands.flatMap { $0.keysAffectedArray }
        #expect(keysFromArray.count == 2, "keysAffectedArray should extract both keys")
        #expect(keysFromArray[0] == key1, "First key should match")
        #expect(keysFromArray[1] == key2, "Second key should match")

        // keysAffected experiences type erasure and returns empty
        let keysFromCollection = commands.flatMap { $0.keysAffected }
        #expect(
            keysFromCollection.count == 0,
            "keysAffected returns empty due to associated type erasure"
        )
    }

}
