// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "arcane-swift",
    platforms: [
        .iOS(.v18),
        .macOS(.v26),
    ],
    products: [
        .library(name: "Arcane", targets: ["Arcane"]),
        .library(name: "ArcaneAPI", targets: ["ArcaneAPI"]),
        .library(name: "ArcaneOIDC", targets: ["ArcaneOIDC"]),
        .library(name: "ArcaneGRPC", targets: ["ArcaneGRPC"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.8.2"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-http-types", from: "1.5.1"),
        .package(url: "https://github.com/grpc/grpc-swift-2.git", from: "2.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift-protobuf.git", from: "2.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift-nio-transport.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.32.0"),
    ],
    targets: [
        .target(
            name: "ArcaneAPI",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
            ]
        ),
        .target(
            name: "Arcane",
            dependencies: [
                "ArcaneAPI",
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ],
            linkerSettings: [
                .linkedFramework("Security"),
            ]
        ),
        .target(
            name: "ArcaneOIDC",
            dependencies: [
                "Arcane",
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ],
            linkerSettings: [
                .linkedFramework("AuthenticationServices"),
            ]
        ),
        .target(
            name: "ArcaneGRPC",
            dependencies: [
                "Arcane",
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "GRPCProtobuf", package: "grpc-swift-protobuf"),
                .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift-nio-transport"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "ArcaneTests",
            dependencies: ["Arcane"]
        ),
        .testTarget(
            name: "ArcaneIntegrationTests",
            dependencies: ["Arcane"]
        ),
    ]
)
