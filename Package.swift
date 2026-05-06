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
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.11.1"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.8.2"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: "ArcaneAPI",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
            ],
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator"),
            ]
        ),
        .target(
            name: "Arcane",
            dependencies: [
                "ArcaneAPI",
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
