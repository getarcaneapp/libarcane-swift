# Arcane Swift

Hand-written Swift SDK for the [Arcane](https://github.com/getarcaneapp/arcane) API, for iOS and macOS apps that talk to an Arcane manager or agent.

## Overview

`libarcane-swift` is a single-layer, idiomatic Swift client built directly on `URLSession`. There is no code generation: every DTO and every endpoint method is hand-crafted to mirror the Arcane Go types and HTTP surface.

Two products:

- **`Arcane`** — the core client. Auth, token storage, environment scoping, REST helpers, WebSocket streams, and per-resource services.
- **`ArcaneOIDC`** — optional, for browser-based OIDC sign-in. Apps that only use API keys or username/password auth can skip linking `AuthenticationServices`.

The type and module layout closely mirrors the Go packages under `arcane/types/`, so engineers moving between the two repos pay no translation tax.

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

let containers = try await client.containers.list(envID: "0")
try await client.containers.start(envID: "0", id: containers[0].id)

for try await line in client.containers.logs(envID: "0", id: containers[0].id, follow: true) {
    print(line.text)
}
```

## Services

Each resource is exposed as a service on `ArcaneClient`:

| Service | Endpoints |
| --- | --- |
| `client.auth` | login, logout, refresh, me, password change, OIDC flow |
| `client.users` | user CRUD |
| `client.apiKeys` | API key CRUD |
| `client.environments` | environment CRUD, agent pairing, mTLS bundle |
| `client.containers` | list, inspect, lifecycle, logs, stats, exec |
| `client.images` | list, inspect, pull, build, prune, upload |
| `client.volumes` | volumes, browse, backups |
| `client.networks` | list, inspect, create, prune, topology |
| `client.projects` | compose projects: up/down/restart/redeploy/build/pull/destroy/archive |
| `client.swarm` | swarm: nodes, services, stacks, configs, secrets, tasks |
| `client.system` | docker info, prune, convert, upgrade, bulk actions |
| `client.dashboard` | env overview, action items |
| `client.events` | audit events |
| `client.webhooks` | webhook CRUD |
| `client.notifications` | settings, providers, apprise, dispatch |
| `client.templates` | templates, registries, default templates |
| `client.registries` | container registries CRUD + test + sync |
| `client.gitops` | repos, syncs, files |
| `client.builds` | build workspace browse |
| `client.jobs` | job executions and schedules |
| `client.settings` | settings search, categories |
| `client.updater` | updater status, run, history |
| `client.vulnerabilities` | image scans, summaries, ignored |
| `client.ports` | port mappings |
| `client.version` | version info |

Drop down to `client.transport` or `client.rest` for any endpoint that's not yet wrapped, or to build custom request flows.

## Authentication

Three parallel paths:

```swift
// 1. API key
let client = ArcaneClient(configuration: .init(
    baseURL: url,
    apiKey: "my-static-api-key"
))

// 2. Username/password (returns access + refresh token pair)
try await client.auth.login(username: "admin", password: "password")

// 3. OIDC (uses ArcaneOIDC product)
import ArcaneOIDC
let oidc = OIDCAuthenticator(client: client)
let result = try await oidc.signIn(
    callbackURLScheme: "arcane-mobile",
    redirectURI: "arcane-mobile://oidc-callback",
    presenting: anchor
)
```

The `AuthManager` actor caches and refreshes tokens automatically; it deduplicates concurrent refresh attempts and falls back through your configured `TokenStore`. Two stores ship with the package: `InMemoryTokenStore` and `KeychainTokenStore`.

## Streaming

WebSocket endpoints surface as `AsyncSequence`:

```swift
for try await line in client.containers.logs(envID: "0", id: containerID) {
    print(line.text)
}

for try await frame in client.containers.stats(envID: "0", id: containerID) {
    print(frame)
}

let terminal = try await client.containers.terminal(envID: "0", id: containerID)
try await terminal.send("ls -la\n")
for try await chunk in terminal.output { print(chunk) }
```

## Errors

`ArcaneError` is a flat enum that maps both Arcane envelopes and Huma's RFC-7807 422 responses to typed cases:

```swift
do {
    try await client.containers.start(id: id)
} catch ArcaneError.unauthorized {
    // ...
} catch ArcaneError.validation(let fields) {
    // fields: [String: [String]]
} catch ArcaneError.rateLimited(let retryAfter) {
    // ...
}
```

## Development

```sh
swift build
swift test
```

Integration tests skip themselves unless `ARCANE_TEST_URL` is set:

```sh
ARCANE_TEST_URL=https://my-arcane.example.com swift test
```

### Linting

```sh
brew install swiftlint
swiftlint lint
swiftlint --fix
```

### Keeping types in sync with Arcane

The Swift types in `Sources/Arcane/Models/<Domain>/` mirror the Go types in `arcane/types/<package>/`. When the backend changes shape, port the change by hand into the corresponding Swift file. There is no code generator to re-run.

The version of Arcane this SDK currently targets is recorded in `BACKEND_VERSION`.
