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

The `Arcane` product exports top-level Swift aliases for the generated DTOs that correspond to the `github.com/getarcaneapp/arcane/types` go package and the Arcane API.

```swift
let user: User
let container: ContainerSummary
let image: ImageSummary
let env: Environment
let volume: Volume
let webhook: WebhookSummary
```

These are aliases to the generated OpenAPI schemas, not hand-written approximations, so fields stay aligned with the backend spec.

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
