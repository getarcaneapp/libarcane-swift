# Swift 6.4 migration

Build all three products, `Arcane`, `ArcaneOIDC`, and `ArcanePasskeys`, with Swift 6.4 or newer. The package uses Swift 6 language mode. Apple platform builds require Xcode 27.0 or newer and the iOS 27/macOS 27 SDKs. Minimum deployment targets are iOS/iPadOS 18 and macOS 26. The SDK supports iOS/iPadOS 18 through 27 and macOS 26 and 27.

## Concurrency

The package enables `NonisolatedNonsendingByDefault`. Core SDK declarations remain nonisolated by default, while OIDC and passkey browser authentication remain `@MainActor`. Transport and file-processing work explicitly marked `@concurrent` runs away from the caller's actor. Authentication state remains actor-isolated. Custom `TokenStore` implementations must satisfy the protocol's `Sendable` contract; actor-backed stores remain supported.

Stream iterators no longer claim unchecked `Sendable` conformance. Keep an iterator inside one consuming task, including calls to `next()`. If several tasks need subscriptions, create independent streams and iterators. Code that moves a shared iterator between tasks must change. Cancellation still closes WebSockets synchronously.

The injected `URLSession`, proxy credentials, authentication flows, and backend request and response contracts remain supported. No server migration is required.

## Cancellation and cleanup

Cleanup of an incomplete upload session is attempted and awaited before `uploadFile` returns an error. A successful upload retains its session for the consuming endpoint. Upload cleanup uses asynchronous `defer`.

Required upload cleanup and credential rollback use an awaited unstructured task while preserving actor isolation. Xcode 27.0 emits strong references to cancellation-shield runtime symbols even behind availability checks, which prevents the SDK from loading on iOS 18. The SDK therefore avoids `withTaskCancellationShield` until a toolchain can link it safely for older deployment targets. Only recovery work is protected from cancellation. The original failure is returned after cleanup, and credential generation checks prevent an older operation from replacing newer credentials.

## Validation

CI pins Xcode 27.0 on the `xcode-27` runner image. It reports toolchain and SDK versions, runs macOS debug tests and release builds, builds all products for unsigned iOS devices and simulators, and runs package tests on iOS 18.6 and iOS 27.0. Build jobs use a product/platform matrix. Simulator tests use `futureware-tech/simulator-action` for boot and shutdown. A missing or incompatible runtime fails that test job rather than silently skipping it.

SwiftLint covers all three source targets and the tests, with warnings treated as failures. Backend integration tests remain opt-in through `ARCANE_TEST_URL`. Local or CI unit tests do not replace live browser authentication checks against an Arcane server.
