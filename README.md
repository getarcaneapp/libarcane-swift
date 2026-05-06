# Arcane Swift

Swift SDK for the Arcane API, designed for iOS and macOS apps that need to talk to an Arcane manager or agent.

This package has two layers:

- `ArcaneAPI`: generated at build time from `Spec/openapi.json` with Apple's `swift-openapi-generator`.
- `Arcane`: a hand-written SDK facade with auth, token storage, environment scoping, generic REST helpers, and WebSocket streams.

`ArcaneOIDC` is a separate product for browser-based OIDC sign-in so apps that only use API keys or username/password auth do not link `AuthenticationServices`.

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

## Spec Sync

The checked-in spec is generated from the sibling Arcane repo:

```sh
Scripts/update-spec.sh
```

The backend JSON path currently emits OpenAPI 3.1 even when `--downgrade` is passed, so the script intentionally asks the backend for downgraded YAML and converts it to JSON. CI validates that `Spec/openapi.json` is OpenAPI 3.0.3.

## Development

```sh
swift build
swift test
```

Integration tests are skipped unless `ARCANE_TEST_URL` is set.
