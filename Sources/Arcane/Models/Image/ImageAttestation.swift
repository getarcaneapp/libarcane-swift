import Foundation

/// Subject an in-toto attestation statement applies to.
public struct ImageAttestationSubject: Codable, Hashable, Sendable {
  public var name: String
  public var digest: [String: String]

  public init(name: String, digest: [String: String]) {
    self.name = name
    self.digest = digest
  }
}

/// One in-toto attestation attached to an image (provenance, SBOM, ...).
public struct ImageAttestation: Codable, Hashable, Sendable, Identifiable {
  public var digest: String
  public var mediaType: String
  public var artifactType: String?
  public var predicateType: String
  public var statementType: String?
  public var subject: [ImageAttestationSubject]?
  public var platform: String?
  public var size: Int64
  /// Full statement payload; present only when requested with `statement=true`.
  public var statement: JSONValue?

  public var id: String { digest + predicateType + (platform ?? "") }

  public init(
    digest: String,
    mediaType: String,
    artifactType: String? = nil,
    predicateType: String,
    statementType: String? = nil,
    subject: [ImageAttestationSubject]? = nil,
    platform: String? = nil,
    size: Int64,
    statement: JSONValue? = nil
  ) {
    self.digest = digest
    self.mediaType = mediaType
    self.artifactType = artifactType
    self.predicateType = predicateType
    self.statementType = statementType
    self.subject = subject
    self.platform = platform
    self.size = size
    self.statement = statement
  }
}

/// Response of `GET /environments/{id}/images/{name}/attestations`.
public struct ImageAttestationList: Codable, Hashable, Sendable {
  public var imageRef: String
  public var subjectDigest: String
  public var platform: String?
  public var attestations: [ImageAttestation]

  public init(
    imageRef: String,
    subjectDigest: String,
    platform: String? = nil,
    attestations: [ImageAttestation]
  ) {
    self.imageRef = imageRef
    self.subjectDigest = subjectDigest
    self.platform = platform
    self.attestations = attestations
  }
}
