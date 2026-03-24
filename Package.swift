// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Docent",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "WallLabel",
            targets: ["WallLabel"],
        ),
        .library(
            name: "Summarizer",
            targets: ["Summarizer"],
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift-lm/", from: "2.30.6"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.7.1"),
        .package(url: "https://github.com/apple/swift-log", from: "1.10.1"),
        .package(url: "https://github.com/grpc/grpc-swift-2.git", from: "2.3.0"),
        .package(url: "https://github.com/grpc/grpc-swift-protobuf.git", from: "2.2.1"),
        .package(url: "https://github.com/grpc/grpc-swift-nio-transport.git", from: "2.5.0"),
    ],
    targets: [

        .target(
            name: "WallLabel",
            dependencies: [
                    .product(name: "MLXLLM", package: "mlx-swift-lm"),
                    .product(name: "Logging", package: "swift-log")
                ]
        ),
        .target(
            name: "Summarizer",
            dependencies: [
                    .product(name: "MLXLLM", package: "mlx-swift-lm"),
                    .product(name: "Logging", package: "swift-log")
                ]
        ),
        .executableTarget(
            name: "docent",
            dependencies: [
                "WallLabel",
                "Summarizer",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "MLXLLM", package: "mlx-swift-lm"),
                .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift-nio-transport"),
                .product(name: "GRPCProtobuf", package: "grpc-swift-protobuf"),
            ]
        ),
    ]
)
