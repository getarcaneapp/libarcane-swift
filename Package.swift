// swift-tools-version: 6.4

import PackageDescription

let concurrencySettings: [SwiftSetting] = [
  .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
  .treatAllWarnings(as: .error)
]

let package = Package(
  name: "arcane-swift",
  platforms: [
    .iOS(.v18),
    .macOS(.v26),
  ],
  products: [
    .library(name: "Arcane", targets: ["Arcane"]),
    .library(name: "ArcaneOIDC", targets: ["ArcaneOIDC"]),
    .library(name: "ArcanePasskeys", targets: ["ArcanePasskeys"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-http-types", from: "1.6.0")
  ],
  targets: [
    .target(
      name: "Arcane",
      dependencies: [
        .product(name: "HTTPTypes", package: "swift-http-types")
      ],
      swiftSettings: concurrencySettings,
      linkerSettings: [
        .linkedFramework("Security")
      ]
    ),
    .target(
      name: "ArcaneOIDC",
      dependencies: [
        "Arcane"
      ],
      swiftSettings: concurrencySettings,
      linkerSettings: [
        .linkedFramework("AuthenticationServices")
      ]
    ),
    .target(
      name: "ArcanePasskeys",
      dependencies: [
        "Arcane"
      ],
      swiftSettings: concurrencySettings,
      linkerSettings: [
        .linkedFramework("AuthenticationServices"),
        .linkedFramework("Security"),
      ]
    ),
    .testTarget(
      name: "ArcaneTests",
      dependencies: ["Arcane"],
      swiftSettings: concurrencySettings
    ),
    .testTarget(
      name: "ArcaneOIDCTests",
      dependencies: ["Arcane", "ArcaneOIDC"],
      swiftSettings: concurrencySettings
    ),
    .testTarget(
      name: "ArcanePasskeysTests",
      dependencies: ["Arcane", "ArcanePasskeys"],
      swiftSettings: concurrencySettings
    ),
    .testTarget(
      name: "ArcaneIntegrationTests",
      dependencies: ["Arcane"],
      swiftSettings: concurrencySettings
    ),
  ],
  swiftLanguageModes: [.v6]
)
