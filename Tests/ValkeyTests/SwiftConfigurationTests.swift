//
// This source file is part of the valkey-swift project
// Copyright (c) 2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

#if compiler(>=6.2)
import Testing
import Configuration

@testable import Valkey

struct SwiftConfigurationTests {
    @Test
    @available(valkeySwift 1.0, *)
    func allPropertiesAreSetFromConfig() throws {
        let testProvider = InMemoryProvider(values: [
            "connectionPool.minimumConnectionCount": 2,
            "connectionPool.maximumConnectionSoftLimit": 50,
            "connectionPool.maximumConnectionHardLimit": 60,
            "connectionPool.idleTimeoutMs": 90000,
            "connectionPool.circuitBreakerTripAfterMs": 75000,
            "connectionPool.maximumConcurrentConnectionRequests": 40,

            "keepAlive.frequencyMs": 45000,

            "retry.exponentBase": 2.5,
            "retry.factorMs": 15,
            "retry.minWaitTimeMs": 1500,
            "retry.maxWaitTimeMs": 500000,

            "authentication.username": "testuser",
            "authentication.password": "testpass",

            "commandTimeoutMs": 45000,
            "blockingCommandTimeoutMs": 180000,

            "databaseNumber": 5,

            "readOnlyCommandNodeSelection": "cycleReplicas",
        ])

        let configReader = ConfigReader(provider: testProvider)
        let config = try ValkeyClientConfiguration(configReader: configReader)

        // Connection Pool
        #expect(config.connectionPool.minimumConnectionCount == 2)
        #expect(config.connectionPool.maximumConnectionSoftLimit == 50)
        #expect(config.connectionPool.maximumConnectionHardLimit == 60)
        #expect(config.connectionPool.idleTimeout == .milliseconds(90000))
        #expect(config.connectionPool.circuitBreakerTripAfter == .milliseconds(75000))
        #expect(config.connectionPool.maximumConcurrentConnectionRequests == 40)

        // Keep Alive
        #expect(config.keepAliveBehavior.frequency == .milliseconds(45000))

        // Retry Parameters
        #expect(config.retryParameters.exponentBase == 2.5)
        #expect(config.retryParameters.factor == 15)
        #expect(config.retryParameters.minWaitTime == 1500)
        #expect(config.retryParameters.maxWaitTime == 500000)

        // Authentication
        #expect(config.authentication?.username == "testuser")
        #expect(config.authentication?.password == "testpass")

        // Timeouts
        #expect(config.commandTimeout == .milliseconds(45000))
        #expect(config.blockingCommandTimeout == .milliseconds(180000))

        // Database
        #expect(config.databaseNumber == 5)

        // Read-Only Command Node Selection
        #expect(config.readOnlyCommandNodeSelection == .cycleReplicas)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func defaultsAreUsedWhenConfigIsEmpty() throws {
        let testProvider = InMemoryProvider(values: [:])
        let configReader = ConfigReader(provider: testProvider)
        let config = try ValkeyClientConfiguration(configReader: configReader)
        let defaultConfig = ValkeyClientConfiguration()

        // Connection Pool defaults
        #expect(config.connectionPool.minimumConnectionCount == defaultConfig.connectionPool.minimumConnectionCount)
        #expect(config.connectionPool.maximumConnectionHardLimit == defaultConfig.connectionPool.maximumConnectionHardLimit)
        #expect(config.connectionPool.maximumConnectionSoftLimit == defaultConfig.connectionPool.maximumConnectionSoftLimit)
        #expect(config.connectionPool.idleTimeout == defaultConfig.connectionPool.idleTimeout)
        #expect(config.connectionPool.circuitBreakerTripAfter == defaultConfig.connectionPool.circuitBreakerTripAfter)
        #expect(config.connectionPool.maximumConcurrentConnectionRequests == defaultConfig.connectionPool.maximumConcurrentConnectionRequests)

        // Keep Alive defaults
        #expect(config.keepAliveBehavior.frequency == defaultConfig.keepAliveBehavior.frequency)

        // Retry defaults
        #expect(config.retryParameters.exponentBase == defaultConfig.retryParameters.exponentBase)
        #expect(config.retryParameters.factor == defaultConfig.retryParameters.factor)
        #expect(config.retryParameters.minWaitTime == defaultConfig.retryParameters.minWaitTime)
        #expect(config.retryParameters.maxWaitTime == defaultConfig.retryParameters.maxWaitTime)
        #expect(config.retryParameters.maxAttempts == defaultConfig.retryParameters.maxAttempts)

        // Authentication defaults
        #expect(config.authentication == nil)

        // Timeout defaults
        #expect(config.commandTimeout == defaultConfig.commandTimeout)
        #expect(config.blockingCommandTimeout == defaultConfig.blockingCommandTimeout)

        // Database defaults
        #expect(config.databaseNumber == defaultConfig.databaseNumber)

        // Read-Only Command Node Selection defaults
        #expect(config.readOnlyCommandNodeSelection == defaultConfig.readOnlyCommandNodeSelection)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func connectionPoolPartialConfiguration() {
        let testProvider = InMemoryProvider(values: [
            "minimumConnectionCount": 5,
            "idleTimeoutMs": 120000,
            "circuitBreakerTripAfterMs": 90000,
        ])

        let configReader = ConfigReader(provider: testProvider)
        let config = ValkeyClientConfiguration.ConnectionPool(configReader: configReader)
        let defaultConfig = ValkeyClientConfiguration.ConnectionPool()

        #expect(config.minimumConnectionCount == 5)
        #expect(config.idleTimeout == .milliseconds(120000))
        #expect(config.circuitBreakerTripAfter == .milliseconds(90000))
        #expect(config.maximumConnectionHardLimit == defaultConfig.maximumConnectionHardLimit)
        #expect(config.maximumConnectionSoftLimit == defaultConfig.maximumConnectionSoftLimit)
        #expect(config.maximumConcurrentConnectionRequests == defaultConfig.maximumConcurrentConnectionRequests)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func keepAliveCustomFrequency() throws {
        let testProvider = InMemoryProvider(values: [
            "keepAlive.frequencyMs": 60000
        ])

        let configReader = ConfigReader(provider: testProvider)
        let config = try ValkeyClientConfiguration(configReader: configReader)

        #expect(config.keepAliveBehavior.frequency == .milliseconds(60000))
    }

    @Test
    @available(valkeySwift 1.0, *)
    func retryParametersConfiguration() throws {
        let testProvider = InMemoryProvider(values: [
            "exponentBase": 1.5,
            "factorMs": 25,
            "minWaitTimeMs": 2000,
            "maxWaitTimeMs": 600000,
        ])

        let configReader = ConfigReader(provider: testProvider)
        let config = ValkeyClientConfiguration.RetryParameters(configReader: configReader)

        #expect(config.exponentBase == 1.5)
        #expect(config.factor == 25)
        #expect(config.minWaitTime == 2000)
        #expect(config.maxWaitTime == 600000)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func authenticationWithBothCredentials() throws {
        let testProvider = InMemoryProvider(values: [
            "authentication.username": "admin",
            "authentication.password": "secret",
        ])

        let configReader = ConfigReader(provider: testProvider)
        let config = try ValkeyClientConfiguration(configReader: configReader)

        #expect(config.authentication?.username == "admin")
        #expect(config.authentication?.password == "secret")
    }

    @Test
    @available(valkeySwift 1.0, *)
    func authenticationReturnsNilWithoutBothCredentials() throws {
        let usernameOnlyProvider = InMemoryProvider(values: [
            "authentication.username": "admin"
        ])
        let passwordOnlyProvider = InMemoryProvider(values: [
            "authentication.password": "secret"
        ])

        let usernameConfig = try ValkeyClientConfiguration(configReader: ConfigReader(provider: usernameOnlyProvider))
        let passwordConfig = try ValkeyClientConfiguration(configReader: ConfigReader(provider: passwordOnlyProvider))

        #expect(usernameConfig.authentication == nil)
        #expect(passwordConfig.authentication == nil)
    }

    @Test(
        arguments: [
            ("primary", .primary),
            ("cycleReplicas", .cycleReplicas),
            ("cycleAllNodes", .cycleAllNodes),
        ] as [(ConfigValue, ValkeyClientConfiguration.ReadOnlyCommandNodeSelection)]
    )
    @available(valkeySwift 1.0, *)
    func readOnlyCommandNodeSelectionStrategies(
        strategyString: ConfigValue,
        expectedStrategy: ValkeyClientConfiguration.ReadOnlyCommandNodeSelection
    ) throws {
        let testProvider = InMemoryProvider(values: [
            "readOnlyCommandNodeSelection": strategyString
        ])

        let configReader = ConfigReader(provider: testProvider)
        let config = try ValkeyClientConfiguration(configReader: configReader)

        #expect(config.readOnlyCommandNodeSelection == expectedStrategy)
    }

    @Test
    @available(valkeySwift 1.0, *)
    func readOnlyCommandNodeSelectionInvalidStrategyThrows() throws {
        let testProvider = InMemoryProvider(values: [
            "readOnlyCommandNodeSelection": "invalid_strategy"
        ])

        let configReader = ConfigReader(provider: testProvider)

        let expectedError = "readOnlyCommandNodeSelection has invalid value. Valid values are primary, cycleReplicas, cycleAllNodes"
        #expect(throws: ConfigurationError(message: expectedError)) {
            try ValkeyClientConfiguration(configReader: configReader)
        }
    }

    @Test
    @available(valkeySwift 1.0, *)
    func commandTimeoutConfiguration() throws {
        let testProvider = InMemoryProvider(values: [
            "commandTimeoutMs": 60000,
            "blockingCommandTimeoutMs": 300000,
        ])

        let configReader = ConfigReader(provider: testProvider)
        let config = try ValkeyClientConfiguration(configReader: configReader)

        #expect(config.commandTimeout == .milliseconds(60000))
        #expect(config.blockingCommandTimeout == .milliseconds(300000))
    }
}

#endif
