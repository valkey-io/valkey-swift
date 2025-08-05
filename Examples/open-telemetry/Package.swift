// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "open-telemetry",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "example", targets: ["Example"])
    ],
    dependencies: [
        // TODO: Change to remote once Distributed Tracing support was merged into main and/or tagged
        .package(path: "../../"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-distributed-tracing.git", from: "1.0.0"),
        .package(url: "https://github.com/swift-otel/swift-otel.git", exact: "1.0.0-alpha.1"),
    ],
    targets: [
        .executableTarget(
            name: "Example",
            dependencies: [
                .product(name: "Valkey", package: "valkey-swift"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "Tracing", package: "swift-distributed-tracing"),
                .product(name: "OTel", package: "swift-otel"),
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
