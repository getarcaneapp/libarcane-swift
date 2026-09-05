import Foundation
import Testing
@testable import Arcane

@Suite(.serialized)
struct BackupContractsTests {
  private func client() -> ArcaneClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [BackupContractProtocol.self]
    return ArcaneClient(configuration: .init(baseURL: URL(string: "https://arcane.example")!, urlSession: URLSession(configuration: configuration)))
  }

  @Test func globalPolicyAndAcceptedRunDecodeBareResponses() async throws {
    let client = client()
    let policies = try await SystemBackupsService(rest: client.rest).policies()
    #expect(policies.recoveryKeyStored)
    let run = try await SystemBackupsService(rest: client.rest).runVolumeBackups()
    #expect(run.status == "running")
    #expect(run.activityId == "activity-1")
  }

  @Test func recoveryKeyRemainsInBodyAndBrowsePreservesPagination() async throws {
    let page = try await SystemBackupsService(rest: client().rest).browseFiles(id: "backup-1", recoveryKey: "private-key", path: "projects/a b", start: 20, limit: 10)
    #expect(page.data.first?.path == "projects/a b/file.txt")
  }

  @Test func deleteUsesBodyAndVolumeRoutesStayEnvironmentScoped() async throws {
    _ = try await SystemBackupsService(rest: client().rest).delete(id: "backup-1", recoveryKey: "private-key")
    _ = try await client().volumes.deleteBackup(backupID: "backup-1")
    _ = try await client().volumes.uploadAndRestoreBackup(name: "my-volume", uploadID: "session-1")
  }

  @Test func selectedFilesAndPolicyUpdatesEncodeFields() throws {
    let request = RestoreSystemBackupFilesRequest(paths: [], selectAll: true, search: "config", recoveryKey: "key")
    let object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any])
    #expect(object["selectAll"] as? Bool == true)
    #expect(object["recoveryKey"] as? String == "key")
    #expect(object["search"] as? String == "config")
    let update = CreateS3Destination(name: "store", bucket: "bucket", region: "us-east-1", accessKeyId: "id", secretAccessKey: "", useSsl: true, forcePathStyle: true)
    let encoded = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(update)) as? [String: Any])
    #expect(encoded["secretAccessKey"] as? String == "")
  }

  @Test func s3BareResponseDecodesDatesAndSecretState() async throws {
    let options = try await S3DestinationsService(rest: client().rest).options()
    #expect(options.first?.secretConfigured == true)
    #expect(options.first?.updatedAt == nil)
    #expect(options.first?.createdAt.timeIntervalSince1970 == 1_767_225_600)
  }

  @Test func oldVolumeBackupAndNewFieldsDecode() throws {
    let decoder = JSONDecoder()
    let old = try decoder.decode(BackupEntry.self, from: Data(#"{"id":"old","volumeName":"vol","size":1,"createdAt":"2026-01-01"}"#.utf8))
    #expect(old.status == nil)
    let new = try decoder.decode(BackupEntry.self, from: Data(#"{"id":"new","volumeName":"vol","size":1,"createdAt":"2026-01-01","status":"running","destination":"local_s3","activityId":"activity"}"#.utf8))
    #expect(new.status == "running")
    #expect(new.activityID == "activity")
  }
}

private final class BackupContractProtocol: URLProtocol, @unchecked Sendable {
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func stopLoading() {}
  override func startLoading() {
    let path = request.url!.path
    let method = request.httpMethod
    var response = #"{"success":true,"data":{"message":"accepted"}}"#
    if path == "/api/backups/s3/options" {
      #expect(method == "GET")
      response = #"[{"id":"s3-1","name":"Store","bucket":"bucket","region":"us-east-1","accessKeyId":"id","useSsl":true,"forcePathStyle":false,"secretConfigured":true,"createdAt":"2026-01-01T00:00:00Z"}]"#
    } else if path == "/api/backups/policies" {
      #expect(method == "GET")
      response = #"{"policies":[],"recoveryKeyStored":true}"#
    } else if path == "/api/backups/volumes/run" {
      #expect(method == "POST")
      response = #"{"activityId":"activity-1","status":"running"}"#
    } else if path == "/api/backups/backup-1/files/browse" {
      #expect(method == "POST")
      #expect(request.url!.query?.contains("private-key") == false)
      #expect(body().contains("private-key"))
      let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems
      #expect(query?.first(where: { $0.name == "start" })?.value == "20")
      response = #"{"success":true,"data":[{"path":"projects/a b/file.txt","name":"file.txt","isDirectory":false}],"pagination":{"totalItems":21,"totalPages":3,"currentPage":3,"itemsPerPage":10}}"#
    } else if path == "/api/backups/backup-1" {
      #expect(method == "DELETE")
      #expect(body().contains("private-key"))
    } else if path == "/api/environments/0/volumes/backups/backup-1" {
      #expect(method == "DELETE")
    } else if path == "/api/environments/0/volumes/my-volume/backups/upload" {
      #expect(method == "POST")
      #expect(body().contains("session-1"))
    } else { Issue.record("Unexpected request: \(path)") }
    let http = HTTPURLResponse(url: request.url!, statusCode: path.hasSuffix("/run") ? 202 : 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
    client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: Data(response.utf8))
    client?.urlProtocolDidFinishLoading(self)
  }

  private func body() -> String {
    if let data = request.httpBody { return String(decoding: data, as: UTF8.self) }
    guard let stream = request.httpBodyStream else { return "" }
    stream.open()
    defer { stream.close() }
    var data = Data()
    var buffer = [UInt8](repeating: 0, count: 1024)
    while stream.hasBytesAvailable {
      let count = stream.read(&buffer, maxLength: buffer.count)
      if count <= 0 { break }
      data.append(buffer, count: count)
    }
    return String(decoding: data, as: UTF8.self)
  }
}
