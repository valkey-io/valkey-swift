//
// This source file is part of the valkey-swift project
// Copyright (c) 2025-2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import Testing

@testable import Valkey

@Suite("ValkeyClientError Tests")
struct ValkeyClientErrorTests {

    @Test("ValkeyClientError has all expected properties and displays callsite")
    func testErrorProperties() {
        struct TestError: Error {}
        let underlyingError = TestError()
        let error = ValkeyClientError(.commandError, message: "WRONGPASS", error: underlyingError)

        // Verify all properties exist and are set
        #expect(error.errorCode == .commandError)
        #expect(error.message == "WRONGPASS")
        #expect(error.underlyingError != nil)
        #expect(!error.file.isEmpty)
        #expect(error.file.contains(".swift"))
        #expect(error.line > 0)

        // Verify description includes all information
        let description = error.description
        #expect(description.contains("Valkey command returned an error."))
        #expect(description.contains("WRONGPASS"))
        #expect(description.contains("Underlying error:"))
        #expect(description.contains("at"))
        #expect(description.contains(error.file))
        #expect(description.contains("\(error.line)"))
    }
}
