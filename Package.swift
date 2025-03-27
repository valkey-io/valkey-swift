// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-redis",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "Redis", targets: ["Redis"]),
        .library(name: "RedisCommands", targets: ["RedisCommands"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.79.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.29.0"),
        .package(url: "https://github.com/apple/swift-nio-transport-services.git", from: "1.23.0"),
    ],
    targets: [
        .target(
            name: "Redis",
            dependencies: [
                "RESP",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
            ]
        ),
        .target(
            name: "RedisCommands",
            dependencies: [
                "RESP",
                "Redis",
                .product(name: "NIOCore", package: "swift-nio"),
            ]
        ),
        .target(
            name: "RESP",
            dependencies: [
                .product(name: "NIOCore", package: "swift-nio")
            ]
        ),
        .executableTarget(
            name: "RedisCommandsBuilder",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "RedisTests",
            dependencies: ["Redis", "RedisCommands"]
        ),
        .testTarget(
            name: "RESPTests",
            dependencies: [
                "RESP",
                .product(name: "NIOTestUtils", package: "swift-nio"),
            ]
        ),
    ]
)
