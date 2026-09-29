import Foundation
import Testing

@testable import Arcane

@Suite struct CorrectnessRegressionTests {
  @Test(arguments: [false, true])
  func destroyOptionsUseDELETEBody(removeFiles: Bool) async throws {
    let mock = MockURLProtocolSession()
    await mock.setHandler { request in
      #expect(request.httpMethod == "DELETE")
      #expect(request.url?.path == "/api/environments/0/projects/project/destroy")
      #expect(request.url?.query == nil)
      let options = try JSONDecoder().decode(DestroyProject.self, from: mockRequestBody(request))
      #expect(options.removeFiles == removeFiles)
      #expect(options.removeVolumes == false)
      return (
        httpResponse(request),
        Data(#"{"success":true,"data":{"message":"accepted","activityId":"a1"}}"#.utf8)
      )
    }
    let response = try await makeClient(mock).projects.destroy(
      projectID: "project", options: .init(removeFiles: removeFiles, removeVolumes: false))
    #expect(response.activityID == "a1")
  }

  @Test func integerConversionsAreCheckedAndPreserveTruncation() throws {
    #expect(JSONValue.number(9.75).intValue == 9)
    #expect(JSONValue.number(-9.75).int64Value == -9)
    #expect(JSONValue.number(Double(Int64.min)).int64Value == Int64.min)
    #expect(JSONValue.number(Double(Int.max).nextDown).intValue != nil)
    #expect(JSONValue.number(Double(Int64.max)).int64Value == nil)
    #expect(JSONValue.number(Double(Int.max)).intValue == nil)
    for value in [1e30, -1e30, Double.infinity, -.infinity, .nan] {
      #expect(JSONValue.number(value).intValue == nil)
      #expect(JSONValue.number(value).int64Value == nil)
    }
    let huge = try JSONDecoder().decode(JSONValue.self, from: Data("1e30".utf8))
    #expect(huge.intValue == nil)
    #expect(huge.int64Value == nil)
    #expect(JSONValue.string("42").intValue == nil)
  }

  @Test func independentSessionsKeepHandlersAndCounters() async throws {
    let first = MockURLProtocolSession()
    let second = MockURLProtocolSession()
    await first.setHandler { request in (httpResponse(request), Data("first".utf8)) }
    await second.setHandler { request in (httpResponse(request), Data("second".utf8)) }
    let request = URL(string: "https://arcane.example.com/same")!
    async let firstData = first.session().data(from: request).0
    async let secondData = second.session().data(from: request).0
    #expect(String(data: try await firstData, encoding: .utf8) == "first")
    #expect(String(data: try await secondData, encoding: .utf8) == "second")
    #expect(await first.requestCount() == 1)
    #expect(await second.requestCount() == 1)
    await first.reset()
    #expect(await first.requestCount() == 0)
    #expect(await second.requestCount() == 1)
  }

  @Test(arguments: AuthenticationMethod.allCases, Retirement.allCases)
  fileprivate func delayedAuthenticationCannotReplaceCurrentCredentials(
    method: AuthenticationMethod, retirement: Retirement
  ) async throws {
    let mock = MockURLProtocolSession()
    let gate = AuthenticationGate()
    let initial = tokens("initial")
    let store = InMemoryTokenStore(tokens: initial)
    let client = makeClient(mock, store: store)
    await mock.setHandler { request in
      await gate.block()
      let response = LoginResponse(
        token: "retired",
        refreshToken: "retired-refresh",
        expiresAt: Date(timeIntervalSinceNow: 3_600),
        user: User(id: "retired", username: "retired")
      )
      let encoded: Data
      if request.url!.path.hasSuffix("oidc/device/token") {
        encoded = try ArcaneJSON.makeEncoder().encode(
          OIDCDeviceTokenResponse(
            success: true,
            token: response.token,
            refreshToken: response.refreshToken,
            expiresAt: response.expiresAt,
            user: response.user))
      } else {
        encoded = try ArcaneJSON.makeEncoder().encode(response)
      }
      let payload: Data
      if request.url!.path.contains("oidc/") {
        payload = encoded
      } else {
        payload = Data("{\"success\":true,\"data\":".utf8) + encoded + Data("}".utf8)
      }
      return (httpResponse(request), payload)
    }
    let operation = Task { try await method.authenticate(client) }
    await gate.waitUntilBlocked()
    let expected: TokenPair?
    switch retirement {
    case .clear:
      try await client.authManager.clear()
      expected = nil
    case .replacement:
      expected = tokens("replacement")
      try await client.authManager.save(tokens: expected!)
    case .retire:
      await client.authManager.retirePendingAuthenticationOperations()
      expected = initial
    case .cancel:
      operation.cancel()
      expected = initial
    }
    await gate.release()
    do {
      try await operation.value
      Issue.record("Retired authentication completed")
    } catch is CancellationError {}
    #expect(try await store.loadTokens() == expected)
  }

  @Test(arguments: Retirement.allCases)
  fileprivate func retirementDuringTokenStoreWriteRestoresAcceptedCredential(retirement: Retirement) async throws {
    let mock = MockURLProtocolSession()
    let gate = AuthenticationGate()
    let initial = tokens("initial")
    let store = SuspendedAuthenticationTokenStore(tokens: initial, gate: gate)
    let client = makeClient(mock, store: store)
    await mock.setHandler { request in
      let response = LoginResponse(
        token: "retired",
        refreshToken: "retired-refresh",
        expiresAt: Date(timeIntervalSinceNow: 3_600),
        user: User(id: "old", username: "old"))
      return (
        httpResponse(request),
        Data("{\"success\":true,\"data\":".utf8)
          + (try ArcaneJSON.makeEncoder().encode(response)) + Data("}".utf8)
      )
    }
    let login = Task { try await client.auth.authenticate(username: "old", password: "p") }
    await gate.waitUntilBlocked()
    let generation = await client.authManager.currentCredentialGeneration()
    let expected: TokenPair?
    let retiring: Task<Void, Error>
    switch retirement {
    case .clear:
      expected = nil
      retiring = Task { try await client.authManager.clear() }
    case .replacement:
      let replacement = tokens("replacement")
      expected = replacement
      retiring = Task { try await client.authManager.save(tokens: replacement) }
    case .retire:
      expected = initial
      retiring = Task { await client.authManager.retirePendingAuthenticationOperations() }
    case .cancel:
      expected = initial
      login.cancel()
      retiring = Task {}
    }
    if retirement != .cancel {
      while await client.authManager.currentCredentialGeneration() == generation { await Task.yield() }
    }
    await gate.release()
    try await retiring.value
    do {
      _ = try await login.value
      Issue.record("Retired credential write completed")
    } catch is CancellationError {}
    #expect(try await store.loadTokens() == expected)
  }

  @Test(arguments: KeychainOperation.allCases)
  fileprivate func retiredKeychainScopeRejectsWorkAtEntry(operation: KeychainOperation) async throws {
    let scope = KeychainScope()
    let gate = AuthenticationGate()
    let store = KeychainTokenStore(service: "arcane-test-\(UUID().uuidString)", validating: { scope.isActive })
    let task = Task {
      await gate.block()
      switch operation {
      case .load: _ = try await store.loadTokens()
      case .save: try await store.saveTokens(tokens("retired"))
      case .clear: try await store.clearTokens()
      }
    }
    await gate.waitUntilBlocked()
    scope.retire()
    await gate.release()
    do {
      try await task.value
      Issue.record("Retired session reached the Keychain")
    } catch is CancellationError {}
  }

  @Test func latestAuthenticationStartWins() async throws {
    let mock = MockURLProtocolSession()
    let gate = AuthenticationGate()
    let store = InMemoryTokenStore()
    let client = makeClient(mock, store: store)
    await mock.setHandler { request in
      let body = try JSONDecoder().decode(LoginRequest.self, from: mockRequestBody(request))
      if body.username == "old" { await gate.block() }
      let response = LoginResponse(
        token: body.username,
        refreshToken: "refresh",
        expiresAt: Date(timeIntervalSinceNow: 3_600),
        user: User(id: body.username, username: body.username))
      let payload =
        Data("{\"success\":true,\"data\":".utf8)
        + (try ArcaneJSON.makeEncoder().encode(response)) + Data("}".utf8)
      return (httpResponse(request), payload)
    }
    let old = Task { try await client.auth.authenticate(username: "old", password: "p") }
    await gate.waitUntilBlocked()
    _ = try await client.auth.authenticate(username: "new", password: "p")
    await gate.release()
    do {
      _ = try await old.value
      Issue.record("Old login completed")
    } catch is CancellationError {}
    #expect(try await store.loadTokens()?.accessToken == "new")
  }

  @Test(arguments: [AuthenticationMethod.password, .oidcDevice])
  fileprivate func logoutCannotClearLoginAcceptedDuringRevocation(method: AuthenticationMethod) async throws {
    let mock = MockURLProtocolSession()
    let loginGate = AuthenticationGate()
    let logoutGate = AuthenticationGate()
    let store = InMemoryTokenStore(tokens: tokens("old"))
    let client = makeClient(mock, store: store)
    await mock.setHandler { request in
      if !request.url!.path.hasSuffix("auth/logout") {
        await loginGate.block()
        let response = LoginResponse(
          token: "new",
          refreshToken: "new-refresh",
          expiresAt: Date(timeIntervalSinceNow: 3_600),
          user: User(id: "new", username: "new"))
        if request.url!.path.contains("oidc/") {
          let payload = try ArcaneJSON.makeEncoder().encode(OIDCDeviceTokenResponse(
            success: true,
            token: response.token,
            refreshToken: response.refreshToken,
            expiresAt: response.expiresAt,
            user: response.user))
          return (httpResponse(request), payload)
        }
        return (httpResponse(request), Data("{\"success\":true,\"data\":".utf8)
          + (try ArcaneJSON.makeEncoder().encode(response)) + Data("}".utf8))
      }
      await logoutGate.block()
      return (httpResponse(request), Data(#"{"success":true,"data":{"message":"logged out"}}"#.utf8))
    }
    let login = Task { try await method.authenticate(client) }
    await loginGate.waitUntilBlocked()
    let logout = Task { try await client.auth.logout() }
    await logoutGate.waitUntilBlocked()
    await loginGate.release()
    try await login.value
    await logoutGate.release()
    try await logout.value
    #expect(try await store.loadTokens()?.accessToken == "new")
  }

  @Test func logoutCannotClearCredentialsAcceptedDuringRevocation() async throws {
    let mock = MockURLProtocolSession()
    let gate = AuthenticationGate()
    let store = InMemoryTokenStore(tokens: tokens("old"))
    let client = makeClient(mock, store: store)
    await mock.setHandler { request in
      await gate.block()
      return (
        httpResponse(request), Data(#"{"success":true,"data":{"message":"logged out"}}"#.utf8)
      )
    }
    let logout = Task { try await client.auth.logout() }
    await gate.waitUntilBlocked()
    let replacement = tokens("replacement")
    try await client.authManager.save(tokens: replacement)
    await gate.release()
    try await logout.value
    #expect(try await store.loadTokens() == replacement)
  }
}

private func makeClient(
  _ mock: MockURLProtocolSession, store: any TokenStore = InMemoryTokenStore()
) -> ArcaneClient {
  ArcaneClient(
    configuration: .init(
      baseURL: URL(string: "https://arcane.example.com")!,
      tokenStore: store,
      urlSession: mock.session(),
      retryPolicy: .init(
        maxAttempts: 1,
        baseBackoff: .milliseconds(1),
        maxBackoff: .milliseconds(1))))
}

private func tokens(_ name: String) -> TokenPair {
  TokenPair(
    accessToken: name, refreshToken: "\(name)-refresh", expiresAt: Date(timeIntervalSinceNow: 3_600)
  )
}

private func httpResponse(_ request: URLRequest) -> HTTPURLResponse {
  HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
}

private enum Retirement: CaseIterable, Sendable { case clear, replacement, retire, cancel }
private enum AuthenticationMethod: CaseIterable, Sendable {
  case password, oidc, oidcDevice, passkey, mobilePasskey, mfa, recovery

  func authenticate(_ client: ArcaneClient) async throws {
    switch self {
    case .password: _ = try await client.auth.authenticate(username: "u", password: "p")
    case .oidc:
      _ = try await client.auth.authenticateOIDCCallback(
        code: "c", state: "s", mobileRedirectURI: "arcane-mobile://oidc")
    case .oidcDevice: _ = try await client.auth.oidcDeviceToken(deviceCode: "c")
    case .passkey: _ = try await client.passkeys.finishLogin(ceremonyId: "c", credential: [:])
    case .mobilePasskey:
      _ = try await client.passkeys.exchangeMobileLogin(transactionId: "t", codeVerifier: "c")
    case .mfa: _ = try await client.passkeys.finishMFA(transactionId: "t", credential: [:])
    case .recovery: _ = try await client.passkeys.finishRecovery(transactionId: "t", code: "c")
    }
  }
}

private actor AuthenticationGate {
  private var blocked = false
  private var open = false
  private var blocker: CheckedContinuation<Void, Never>?
  private var observers: [CheckedContinuation<Void, Never>] = []

  func block() async {
    blocked = true
    observers.forEach { $0.resume() }
    observers.removeAll()
    if open { return }
    await withCheckedContinuation { blocker = $0 }
  }

  func waitUntilBlocked() async {
    if blocked { return }
    await withCheckedContinuation { observers.append($0) }
  }

  func release() {
    open = true
    blocker?.resume()
    blocker = nil
  }
}

private actor SuspendedAuthenticationTokenStore: TokenStore {
  private var tokens: TokenPair?
  private let gate: AuthenticationGate

  init(tokens: TokenPair, gate: AuthenticationGate) {
    self.tokens = tokens
    self.gate = gate
  }

  func loadTokens() -> TokenPair? { tokens }
  func clearTokens() { tokens = nil }
  func saveTokens(_ tokens: TokenPair) async {
    if tokens.accessToken == "retired" { await gate.block() }
    self.tokens = tokens
  }
}

private enum KeychainOperation: CaseIterable, Sendable { case load, save, clear }

private final class KeychainScope: @unchecked Sendable {
  private let lock = NSLock()
  private var active = true
  var isActive: Bool { lock.withLock { active } }
  func retire() { lock.withLock { active = false } }
}
