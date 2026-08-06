import Foundation
import XCTest

@testable import Arcane

final class Post26ContractsTests: XCTestCase {
  func testAuthenticationResultDecodesLegacyAndMFAResponses() throws {
    let legacy = try ArcaneJSON.makeDecoder().decode(
      AuthenticationResult.self,
      from: Data(
        #"{"token":"access","refreshToken":"refresh","expiresAt":"2026-08-07T00:00:00Z","user":{"id":"user-1","username":"admin"}}"#
          .utf8
      )
    )
    guard case .authenticated(let response) = legacy else {
      return XCTFail("Expected a legacy authenticated response")
    }
    XCTAssertEqual(response.token, "access")
    XCTAssertEqual(response.user.username, "admin")

    let mfa = try ArcaneJSON.makeDecoder().decode(
      AuthenticationResult.self,
      from: Data(
        #"{"status":"mfa_required","mfa":{"transactionId":"transaction-1","method":"passkey","options":{"challenge":"abc"},"expiresAt":"2026-08-07T00:00:00Z"}}"#
          .utf8
      )
    )
    guard case .mfaRequired(let challenge) = mfa else {
      return XCTFail("Expected an MFA challenge")
    }
    XCTAssertEqual(challenge.transactionId, "transaction-1")
    XCTAssertEqual(challenge.options["challenge"]?.stringValue, "abc")

    let minimalMFA = try ArcaneJSON.makeDecoder().decode(
      AuthenticationResult.self,
      from: Data(
        #"{"status":"mfa_required","challenge":{"transactionId":"transaction-2","expiresAt":"2026-08-07T00:00:00Z"}}"#
          .utf8
      )
    )
    guard case .mfaRequired(let minimalChallenge) = minimalMFA else {
      return XCTFail("Expected a minimal MFA challenge")
    }
    XCTAssertEqual(minimalChallenge.transactionId, "transaction-2")
    XCTAssertEqual(minimalChallenge.method, "passkey")
    XCTAssertEqual(minimalChallenge.options, [:])
  }

  func testPasswordMFAResponseDoesNotReplaceStoredTokensAndConvenienceThrows() async throws {
    await MockURLProtocol.reset()
    let original = TokenPair(
      accessToken: "existing-access",
      refreshToken: "existing-refresh",
      expiresAt: Date(timeIntervalSinceNow: 3_600)
    )
    let store = InMemoryTokenStore(tokens: original)
    let client = makeClient(store: store)
    await MockURLProtocol.setHandler { request in
      XCTAssertEqual(request.url?.path, "/api/auth/login")
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )
      return (
        response!,
        Data(
          #"{"success":true,"data":{"status":"mfa_required","mfa":{"transactionId":"transaction-1","method":"passkey","options":{},"expiresAt":"2026-08-07T00:00:00Z"}}}"#
            .utf8
        )
      )
    }

    let result = try await client.auth.authenticate(username: "admin", password: "password")
    guard case .mfaRequired = result else {
      return XCTFail("Expected MFA to remain pending")
    }
    let tokensAfterAuthentication = try await store.loadTokens()
    XCTAssertEqual(tokensAfterAuthentication, original)

    do {
      _ = try await client.auth.login(username: "admin", password: "password")
      XCTFail("Expected the source-compatible login convenience to throw")
    } catch let error as MFARequiredError {
      XCTAssertEqual(error.challenge.transactionId, "transaction-1")
    }
    let tokensAfterConvenience = try await store.loadTokens()
    XCTAssertEqual(tokensAfterConvenience, original)
  }

  func testOIDCMFAResponseDoesNotReplaceStoredTokensAndConvenienceThrows() async throws {
    await MockURLProtocol.reset()
    let original = TokenPair(
      accessToken: "existing-access",
      refreshToken: "existing-refresh",
      expiresAt: Date(timeIntervalSinceNow: 3_600)
    )
    let store = InMemoryTokenStore(tokens: original)
    let client = makeClient(store: store)
    await MockURLProtocol.setHandler { request in
      XCTAssertEqual(request.url?.path, "/api/oidc/callback")
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )
      return (
        response!,
        Data(
          #"{"status":"mfa_required","mfa":{"transactionId":"oidc-transaction","method":"passkey","options":{},"expiresAt":"2026-08-07T00:00:00Z"}}"#
            .utf8
        )
      )
    }

    let result = try await client.auth.authenticateOIDCCallback(
      code: "code", state: "state", mobileRedirectURI: "arcane-mobile://oidc-callback")
    guard case .mfaRequired = result else {
      return XCTFail("Expected OIDC MFA to remain pending")
    }
    let tokensAfterAuthentication = try await store.loadTokens()
    XCTAssertEqual(tokensAfterAuthentication, original)

    do {
      _ = try await client.auth.oidcCallback(
        code: "code", state: "state", mobileRedirectURI: "arcane-mobile://oidc-callback")
      XCTFail("Expected the source-compatible OIDC convenience to throw")
    } catch let error as MFARequiredError {
      XCTAssertEqual(error.challenge.transactionId, "oidc-transaction")
    }
    let tokensAfterConvenience = try await store.loadTokens()
    XCTAssertEqual(tokensAfterConvenience, original)
  }

  func testPasskeyPublicBeginAndStepUpHeaderUseExistingWireContract() async throws {
    await MockURLProtocol.reset()
    let store = InMemoryTokenStore(
      tokens: TokenPair(
        accessToken: "access",
        refreshToken: "refresh",
        expiresAt: Date(timeIntervalSinceNow: 3_600)
      )
    )
    let client = makeClient(store: store)
    await MockURLProtocol.setHandler { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )!
      switch request.url?.path {
      case "/api/auth/passkey/login/begin":
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
        return (
          response,
          Data(
            #"{"success":true,"data":{"ceremonyId":"ceremony-1","options":{"challenge":"abc"},"expiresAt":"2026-08-07T00:00:00Z"}}"#
              .utf8
          )
        )
      case "/api/auth/me/mfa/enable":
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Step-Up-Token"), "step-up-grant")
        return (response, Data(#"{"success":true,"data":{"codes":["one","two"]}}"#.utf8))
      default:
        XCTFail("Unexpected passkey request: \(request.url?.path ?? "nil")")
        return (response, Data())
      }
    }

    let challenge = try await client.passkeys.beginLogin()
    XCTAssertEqual(challenge.ceremonyId, "ceremony-1")
    let codes = try await client.passkeys.enableMFA(stepUpToken: "step-up-grant")
    XCTAssertEqual(codes.codes, ["one", "two"])
  }

  func testNotificationEventsUseNestedSnakeCaseAndPreserveLegacyDefaults() throws {
    let decoded = try JSONDecoder().decode(
      NotificationEvents.self,
      from: Data(#"{"image_update":false}"#.utf8)
    )
    XCTAssertFalse(decoded.imageUpdate)
    XCTAssertTrue(decoded.containerUpdate)
    XCTAssertTrue(decoded.vulnerabilityFound)
    XCTAssertFalse(decoded.pruneReport)
    XCTAssertFalse(decoded.autoHeal)

    let data = try JSONEncoder().encode(decoded)
    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    XCTAssertEqual(object["image_update"] as? Bool, false)
    XCTAssertEqual(object["container_update"] as? Bool, true)
    XCTAssertNil(object["imageUpdate"])
  }

  func testNotificationUpdatePreservesGenericShapeAndOmitsRedactedSecrets() throws {
    let generic = UpdateNotificationSettings(
      enabled: true,
      config: .generic(
        GenericNotificationConfiguration(
          webhookUrl: "https://hooks.example.test/notify",
          method: "POST",
          contentType: "application/json",
          titleKey: "title",
          messageKey: "message",
          customHeaders: ["X-Environment": "production"],
          events: NotificationEvents(autoHeal: false),
          successBodyContains: "accepted",
          payloadTemplate: #"{"subject":"{{ title }}"}"#
        )
      )
    )
    let genericData = try ArcaneJSON.makeEncoder().encode(generic)
    let roundTrip = try ArcaneJSON.makeDecoder().decode(
      UpdateNotificationSettings.self, from: genericData)
    XCTAssertEqual(roundTrip, generic)

    let email = UpdateNotificationSettings(
      enabled: true,
      config: .email(
        EmailNotificationConfiguration(
          smtpHost: "smtp.example.test",
          smtpPort: 587,
          smtpUsername: "mailer",
          smtpPassword: "••••••••",
          fromAddress: "arcane@example.test",
          toAddresses: ["ops@example.test"],
          tlsMode: .starttls
        )
      )
    )
    let emailData = try ArcaneJSON.makeEncoder().encode(email)
    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: emailData) as? [String: Any])
    let config = try XCTUnwrap(object["config"] as? [String: Any])
    XCTAssertNil(config["smtpPassword"])
  }

  func testNotificationWarningResponseDecodes() throws {
    let response = try JSONDecoder().decode(
      NotificationTestResponse.self,
      from: Data(#"{"message":"sent","warning":"unexpected response body"}"#.utf8)
    )
    XCTAssertEqual(response.message, "sent")
    XCTAssertEqual(response.warning, "unexpected response body")
  }

  func testDeployOptionsEncodeAllV27Fields() throws {
    let options = DeployOptions(
      pullPolicy: "always",
      forceRecreate: true,
      removeOrphans: false,
      recreateVolumes: true
    )
    let object = try XCTUnwrap(
      JSONSerialization.jsonObject(with: ArcaneJSON.makeEncoder().encode(options))
        as? [String: Any]
    )
    XCTAssertEqual(object["pullPolicy"] as? String, "always")
    XCTAssertEqual(object["forceRecreate"] as? Bool, true)
    XCTAssertEqual(object["removeOrphans"] as? Bool, false)
    XCTAssertEqual(object["recreateVolumes"] as? Bool, true)
  }

  func testRegistryRepositoryNamesRemainBackwardCompatible() throws {
    let decoder = ArcaneJSON.makeDecoder()
    let oldResponse = Data(
      #"{"id":"registry-1","url":"ghcr.io","username":"user","insecure":false,"enabled":true,"registryType":"custom","createdAt":"2026-08-06T00:00:00Z","updatedAt":"2026-08-06T00:00:00Z"}"#
        .utf8
    )
    XCTAssertEqual(
      try decoder.decode(ContainerRegistry.self, from: oldResponse).repositoryNames,
      []
    )

    let legacyCreate = CreateContainerRegistry(url: "ghcr.io")
    let legacyObject = try XCTUnwrap(
      JSONSerialization.jsonObject(with: ArcaneJSON.makeEncoder().encode(legacyCreate))
        as? [String: Any]
    )
    XCTAssertNil(legacyObject["repositoryNames"])

    let v27Create = CreateContainerRegistry(
      url: "ghcr.io", repositoryNames: ["getarcaneapp/arcane", "getarcaneapp/agent"])
    let v27Object = try XCTUnwrap(
      JSONSerialization.jsonObject(with: ArcaneJSON.makeEncoder().encode(v27Create))
        as? [String: Any]
    )
    XCTAssertEqual(
      v27Object["repositoryNames"] as? [String],
      ["getarcaneapp/arcane", "getarcaneapp/agent"]
    )
  }

  func testRegistrySyncDefaultsMissingNamesAndOnlyEncodesWhenRequested() throws {
    let decoder = ArcaneJSON.makeDecoder()
    let legacyData = Data(
      #"{"id":"registry-1","url":"ghcr.io","username":"user","token":"token","insecure":false,"enabled":true,"registryType":"custom","createdAt":"2026-08-06T00:00:00Z","updatedAt":"2026-08-06T00:00:00Z"}"#
        .utf8
    )
    let legacy = try decoder.decode(ContainerRegistrySync.self, from: legacyData)
    XCTAssertEqual(legacy.repositoryNames, [])
    let legacyObject = try XCTUnwrap(
      JSONSerialization.jsonObject(with: ArcaneJSON.makeEncoder().encode(legacy))
        as? [String: Any]
    )
    XCTAssertNil(legacyObject["repositoryNames"])

    let date = Date(timeIntervalSince1970: 0)
    let v27 = ContainerRegistrySync(
      id: "registry-1",
      url: "ghcr.io",
      username: "user",
      token: "token",
      insecure: false,
      enabled: true,
      registryType: "custom",
      repositoryNames: [],
      createdAt: date,
      updatedAt: date
    )
    let v27Object = try XCTUnwrap(
      JSONSerialization.jsonObject(with: ArcaneJSON.makeEncoder().encode(v27))
        as? [String: Any]
    )
    XCTAssertEqual(v27Object["repositoryNames"] as? [String], [])
  }

  func testPost26FeatureGateRequiresSemverAtLeast270() {
    XCTAssertFalse(version("2.6.9").supportsPost26MobileFeatures)
    XCTAssertTrue(version("2.7.0").supportsPost26MobileFeatures)
    XCTAssertTrue(version("v2.8.1+build.4").supportsPost26MobileFeatures)
    XCTAssertFalse(version("dev").supportsPost26MobileFeatures)
    XCTAssertFalse(version("2.7").supportsPost26MobileFeatures)
    XCTAssertFalse(version("2.7.0", isSemver: false).supportsPost26MobileFeatures)
  }

  private func makeClient(store: InMemoryTokenStore) -> ArcaneClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return ArcaneClient(
      configuration: .init(
        baseURL: URL(string: "https://arcane.example.test/api")!,
        tokenStore: store,
        urlSession: URLSession(configuration: configuration),
        retryPolicy: .init(
          maxAttempts: 1,
          baseBackoff: .milliseconds(1),
          maxBackoff: .milliseconds(1)
        )
      )
    )
  }

  private func version(_ currentVersion: String, isSemver: Bool = true) -> VersionInfo {
    VersionInfo(
      currentVersion: currentVersion,
      revision: "revision",
      shortRevision: "revision",
      goVersion: "go1.25",
      displayVersion: currentVersion,
      isSemverVersion: isSemver,
      updateAvailable: false
    )
  }
}
