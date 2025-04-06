// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-valkey",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "Valkey", targets: ["Valkey"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.79.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.29.0"),
        .package(url: "https://github.com/apple/swift-nio-transport-services.git", from: "1.23.0"),
    ],
    targets: [
        .target(
            name: "Valkey",
            dependencies: [
                .product(name: "DequeModule", package: "swift-collections"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
            ]
        ),
        .executableTarget(
            name: "ValkeyCommandsBuilder",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                "Valkey",
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
