// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MiCoder",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MiCoder", targets: ["MiCoder"])
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.0")
    ],
    targets: [
        .executableTarget(
            name: "MiCoder",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            path: "MiCoder/Sources",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "MiCoderTests",
            dependencies: ["MiCoder"],
            path: "MiCoder/Tests"
        )
    ]
)
