# Arcane Swift

Swift SDK for the Arcane API, designed for iOS and macOS apps that need to talk to an Arcane manager or agent.

This package has two layers:

- `ArcaneAPI`: generated from `Spec/openapi.json` with Apple's `swift-openapi-generator` and checked in as static Swift source.
- `Arcane`: a hand-written SDK facade with auth, token storage, environment scoping, generic REST helpers, and WebSocket streams.

`ArcaneOIDC` is a separate product for browser-based OIDC sign-in so apps that only use API keys or username/password auth do not link `AuthenticationServices`.

The generated OpenAPI Swift files are checked in under `Sources/ArcaneAPI`. App consumers do not need the OpenAPI generator installed and do not run code generation during their builds.

## Quickstart

```swift
import Arcane

let client = ArcaneClient(
    configuration: .init(
        baseURL: URL(string: "https://arcane.example.com")!,
        tokenStore: KeychainTokenStore(service: "com.example.app.arcane"),
        defaultEnvironmentID: "0"
    )
)

try await client.auth.login(username: "admin", password: "password")

let containers: [ContainerSummary] = try await client.containers.list(envID: "0")
try await client.containers.start(envID: "0", id: containers[0].id)

for try await line in client.containers.logs(envID: "0", id: containers[0].id, follow: true) {
    print(line.text)
}
```

## Generated API

The complete OpenAPI client is generated from `Spec/openapi.json` and checked in under `Sources/ArcaneAPI`. Consumers do not need `swift-openapi-generator`; only maintainers need it when refreshing the spec.

Use the hand-written facade for common SDK workflows:

```swift
let containers = try await client.containers.list()
```

Drop to the generated client when you need an endpoint that does not have a facade wrapper yet:

```swift
let generated = client.generated
let response = try await generated.listContainers(
    .init(path: .init(id: "0"))
)
```

You can also add the `ArcaneAPI` product directly in Xcode if you want to work against only the generated OpenAPI module.

## Spec Sync

The checked-in spec is generated from the sibling Arcane repo:

```sh
Scripts/update-spec.sh
```

The backend JSON path currently emits OpenAPI 3.1 even when `--downgrade` is passed, so the script intentionally asks the backend for downgraded YAML and converts it to JSON. It then regenerates the static Swift sources in `Sources/ArcaneAPI`.

Maintainers need `swift-openapi-generator` on `PATH` to run the script:

```sh
mint install apple/swift-openapi-generator
```

## Development

```sh
swift build
swift test
```

Integration tests are skipped unless `ARCANE_TEST_URL` is set.

## Linting

Install SwiftLint:

```sh
brew install swiftlint
```

Run it from the repository root:

```sh
swiftlint lint
```

Auto-correct safe style fixes:

```sh
swiftlint --fix
```

The config intentionally excludes `Sources/ArcaneAPI` because those files are generated from OpenAPI.

## Publishing to Nexus

The package is published to the Sonatype Nexus Swift hosted registry at:

```sh
https://pkgs.getarcane.app/repository/swift/
```

SwiftPM publishes registry packages by package identifier and semantic version:

```sh
swift package-registry publish getarcaneapp.libarcane-swift 1.0.0 \
  --url https://pkgs.getarcane.app/repository/swift/
```

Use the helper script from a clean git checkout:

```sh
Scripts/publish-nexus.sh 1.0.0
```

GitHub Actions publishes automatically when a `v*.*.*` tag is pushed, or manually through the `Publish Nexus Swift Package` workflow. Configure these repository secrets first:

```text
NEXUS_SWIFT_USERNAME
NEXUS_SWIFT_PASSWORD
```

Before publishing, configure auth for the Nexus registry:

```sh
swift package-registry set --scope getarcaneapp \
  https://pkgs.getarcane.app/repository/swift/

swift package-registry login \
  https://pkgs.getarcane.app/repository/swift/login \
  --username "$NEXUS_SWIFT_USERNAME" \
  --password "$NEXUS_SWIFT_PASSWORD" \
  --no-confirm
```

Consumers can then use the package identifier instead of a Git URL:

```swift
.package(id: "getarcaneapp.libarcane-swift", from: "1.0.0")
```
