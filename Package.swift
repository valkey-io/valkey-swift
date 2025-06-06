// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "valkey-swift",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "Valkey", targets: ["Valkey"]),
        .library(name: "ValkeyBloom", targets: ["ValkeyBloom"]),
        .library(name: "ValkeyJSON", targets: ["ValkeyJSON"]),
    ],
    traits: [
        .trait(name: "ServiceLifecycleSupport"),
        .default(enabledTraits: ["ServiceLifecycleSupport"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.4"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.3"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.81.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.29.0"),
        .package(url: "https://github.com/apple/swift-nio-transport-services.git", from: "1.23.0"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.8.0"),

        .package(url: "https://github.com/ordo-one/package-benchmark", from: "1.29.2"),
    ],
    targets: [
        .target(
            name: "Valkey",
            dependencies: [
                .byName(name: "_ConnectionPoolModule"),
                .product(name: "DequeModule", package: "swift-collections"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle", condition: .when(traits: ["ServiceLifecycleSupport"])),
            ]
        ),
        .target(
            name: "ValkeyBloom",
            dependencies: ["Valkey"]
        ),
        .target(
            name: "ValkeyJSON",
            dependencies: ["Valkey"]
        ),
        .target(
            name: "_ConnectionPoolModule",
            dependencies: [
                .product(name: "Atomics", package: "swift-atomics"),
                .product(name: "DequeModule", package: "swift-collections"),
            ],
            path: "Sources/ConnectionPoolModule"
        ),
        .executableTarget(
            name: "ValkeyCommandsBuilder",
            path: "Sources/_ValkeyCommandsBuilder",
            resources: [.process("Resources")]
        ),
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
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
            ]
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                "Valkey"
            ]
        ),
        .testTarget(
            name: "ValkeyTests",
            dependencies: [
                "Valkey",
                .product(name: "NIOTestUtils", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "NIOEmbedded", package: "swift-nio"),
            ]
        ),
    ]
)
