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
        .library(
            name: "DocentModels",
            targets: ["DocentModels"],
        ),

    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift-lm/", branch: "main"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.7.0"),
        .package(url: "https://github.com/sfomuseum/swift-accession-numbers", from: "0.0.5"),
        .package(url: "https://github.com/apple/swift-log", from: "1.9.1"),
        .package(url: "https://github.com/grpc/grpc-swift-2.git", from: "2.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift-protobuf.git", from: "2.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift-nio-transport.git", from: "2.1.0"),
    ],
    targets: [

        .target(
            name: "WallLabel",
            dependencies: [
                    "DocentModels",
                    .product(name: "MLXLLM", package: "mlx-swift-lm"),
                    .product(name: "Logging", package: "swift-log"),
                    .product(name: "AccessionNumbers", package: "swift-accession-numbers")
                ]
        ),
        .target(
            name: "Summarizer",
            dependencies: [
                    "DocentModels",
                    .product(name: "MLXLLM", package: "mlx-swift-lm"),
                    .product(name: "Logging", package: "swift-log")
                ]
        ),
        .target(
            name: "DocentModels",
            dependencies: [
                .product(name: "MLXLLM", package: "mlx-swift-lm"),
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .executableTarget(
            name: "docent",
            dependencies: [
                "DocentModels",
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
