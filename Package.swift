// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WallLabel",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "WallLabel",
            targets: ["WallLabel"],
        ),
    ], dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift-examples", branch: "main"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.7.0"),
        .package(url: "https://github.com/apple/swift-log", from: "1.9.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "WallLabel",
            dependencies: [
                    .product(name: "MLXLLM", package: "mlx-swift-examples"),
                    .product(name: "Logging", package: "swift-log")
                ]
        ),
        .executableTarget(
            name: "wall-label",
            dependencies: [
                "WallLabel",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .testTarget(
            name: "WallLabelTests",
            dependencies: ["WallLabel"]
        ),
    ]
)
