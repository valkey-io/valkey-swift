// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var defaultSwiftSettings: [SwiftSetting] =
    [
        .swiftLanguageMode(.v6),
        .enableExperimentalFeature("AvailabilityMacro=valkeySwift 1.0:macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0"),

        // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0444-member-import-visibility.md
        .enableUpcomingFeature("MemberImportVisibility"),

        // https://forums.swift.org/t/experimental-support-for-lifetime-dependencies-in-swift-6-2-and-beyond/78638
        .enableExperimentalFeature("Lifetimes"),
    ]

#if compiler(>=6.2)
defaultSwiftSettings.append(contentsOf: [
    // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0461-async-function-isolation.md
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),

    // https://forums.swift.org/t/accepted-se-0458-opt-in-strict-memory-safety-checking/78116
    .enableExperimentalFeature("StrictMemorySafety"),
])
#endif

let package = Package(
    name: "valkey-swift",
    products: [
        .library(name: "Valkey", targets: ["Valkey"]),
        .library(name: "ValkeyBloom", targets: ["ValkeyBloom"]),
        .library(name: "ValkeyJSON", targets: ["ValkeyJSON"]),
        .library(name: "ValkeySearch", targets: ["ValkeySearch"]),
    ],
    traits: [
        .trait(name: "ServiceLifecycleSupport"),
        .trait(name: "DistributedTracingSupport"),
        .default(enabledTraits: ["ServiceLifecycleSupport", "DistributedTracingSupport"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.4"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.3"),
        .package(url: "https://github.com/apple/swift-distributed-tracing.git", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.92.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.29.0"),
        .package(url: "https://github.com/apple/swift-nio-transport-services.git", from: "1.26.0"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.8.0"),
    ],
    targets: [
        .target(
            name: "Valkey",
            dependencies: [
                .byName(name: "_ValkeyConnectionPool"),
                .product(name: "DequeModule", package: "swift-collections"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Tracing", package: "swift-distributed-tracing", condition: .when(traits: ["DistributedTracingSupport"])),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle", condition: .when(traits: ["ServiceLifecycleSupport"])),
            ],
            swiftSettings: defaultSwiftSettings
        ),
        .target(
            name: "ValkeyBloom",
            dependencies: ["Valkey"],
            swiftSettings: defaultSwiftSettings
        ),
        .target(
            name: "ValkeyJSON",
            dependencies: ["Valkey"],
            swiftSettings: defaultSwiftSettings
        ),
        .target(
            name: "ValkeySearch",
            dependencies: ["Valkey"],
            swiftSettings: defaultSwiftSettings
        ),
        .target(
            name: "_ValkeyConnectionPool",
            dependencies: [
                .product(name: "Atomics", package: "swift-atomics"),
                .product(name: "DequeModule", package: "swift-collections"),
            ],
            path: "Sources/ValkeyConnectionPool",
            swiftSettings: defaultSwiftSettings
        ),
        .executableTarget(
            name: "ValkeyCommandsBuilder",
            path: "Sources/_ValkeyCommandsBuilder",
            resources: [.process("Resources")],
            swiftSettings: defaultSwiftSettings
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                "Valkey"
            ],
            swiftSettings: defaultSwiftSettings
        ),
        .testTarget(
            name: "ClusterIntegrationTests",
            dependencies: [
                "Valkey"
            ],
            swiftSettings: defaultSwiftSettings
        ),
        .testTarget(
            name: "ValkeyTests",
            dependencies: [
                "Valkey",
                "ValkeySearch",
                .product(name: "NIOTestUtils", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "NIOEmbedded", package: "swift-nio"),
                .product(name: "InMemoryTracing", package: "swift-distributed-tracing", condition: .when(traits: ["DistributedTracingSupport"])),
            ],
            swiftSettings: defaultSwiftSettings
        ),
    ]
)

if Context.environment["ENABLE_VALKEY_BENCHMARKS"] != nil {
    package.platforms = [.macOS(.v13)]
    package.dependencies.append(
        .package(url: "https://github.com/ordo-one/package-benchmark", from: "1.0.0")
    )
    package.targets.append(
        .executableTarget(
            name: "ValkeyBenchmarks",
            dependencies: [
                "Valkey",
                .product(name: "Benchmark", package: "package-benchmark"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
            ],
            path: "Benchmarks/ValkeyBenchmarks",
            swiftSettings: defaultSwiftSettings,
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
            ]
        )
    )
}
