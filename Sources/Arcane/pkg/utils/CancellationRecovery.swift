/// Runs required recovery to completion without inheriting caller cancellation.
func withCancellationRecovery(
  isolation: isolated (any Actor)? = #isolation,
  operation: @escaping @Sendable () async throws -> Void
) async throws {
  // Xcode 27.0 emits strong runtime references for withTaskCancellationShield,
  // even behind #available, preventing an iOS 18 process from loading this SDK.
  // An awaited unstructured task keeps recovery uncancelled on every supported OS.
  try await Task { try await operation() }.value
}
