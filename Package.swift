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
        .library(name: "ArcaneOIDC", targets: ["ArcaneOIDC"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-http-types", from: "1.5.1"),
    ],
    targets: [
        .target(
            name: "Arcane",
            dependencies: [
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
