import Foundation
import XCTest

@testable import Arcane

final class ContainerPaginationTests: XCTestCase {
  private let mock = MockURLProtocolSession()
  func testContainerListDecodesTopLevelPaginationAndSkipsMalformedRows() async throws {
    await mock.reset()
    let client = makeMockClient()

    await mock.setHandler { request in
      let components = try XCTUnwrap(
        URLComponents(url: XCTUnwrap(request.url), resolvingAgainstBaseURL: false)
      )
      let query = Dictionary(
        uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) }
      )
      XCTAssertEqual(query["start"], "50")
      XCTAssertEqual(query["limit"], "50")
      XCTAssertEqual(query["groupBy"], "project")
      XCTAssertEqual(query["includeInternal"], "true")

      let response = try XCTUnwrap(
        HTTPURLResponse(
          url: XCTUnwrap(request.url),
          statusCode: 200,
          httpVersion: nil,
          headerFields: ["Content-Type": "application/json"]
        )
      )
      return (response, Data(Self.containerListPayload.utf8))
    }

    let response = try await client.containers.list(
      query: .init(start: 50, limit: 50),
      groupBy: "project",
      includeInternal: true
    )

    XCTAssertTrue(response.success)
    XCTAssertEqual(response.data.map(\.id), ["valid"])
    XCTAssertEqual(response.groups?.first?.items.map(\.id), ["valid"])
    XCTAssertEqual(response.counts.totalContainers, 101)
    XCTAssertEqual(response.pagination.currentPage, 2)
    XCTAssertEqual(response.pagination.totalItems, 101)
  }

  func testResourceSortedListSendsSortAndDecodesSamples() async throws {
    await mock.reset()
    let client = makeMockClient()

    await mock.setHandler { request in
      let components = try XCTUnwrap(
        URLComponents(url: XCTUnwrap(request.url), resolvingAgainstBaseURL: false)
      )
      let query = Dictionary(
        uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) }
      )
      XCTAssertEqual(query["sort"], "cpuUsage")
      XCTAssertEqual(query["order"], "desc")

      let response = try XCTUnwrap(
        HTTPURLResponse(
          url: XCTUnwrap(request.url),
          statusCode: 200,
          httpVersion: nil,
          headerFields: ["Content-Type": "application/json"]
        )
      )
      return (response, Data(Self.resourceSortedPayload.utf8))
    }

    let response = try await client.containers.list(
      query: .init(sortBy: ContainerResourceSort.cpuUsage.rawValue, sortOrder: .descending)
    )

    XCTAssertTrue(response.resourceSortSupported)
    XCTAssertEqual(response.data.map(\.id), ["sampled", "stopped", "malformed"])
    let sample = try XCTUnwrap(response.data[0].resourceSample)
    XCTAssertEqual(sample.cpuPercent, 12.5)
    XCTAssertEqual(sample.memoryUsageBytes, 268_435_456)
    XCTAssertEqual(sample.memoryLimitBytes, 1_073_741_824)
    XCTAssertEqual(sample.memoryPercent, 25)
    XCTAssertNotNil(sample.sampleTime)
    XCTAssertNil(response.data[1].resourceSample)
    XCTAssertNil(response.data[2].resourceSample)
  }

  func testListResponseWithoutResourceSortFlagDefaultsToUnsupported() throws {
    let response = try JSONDecoder().decode(
      ContainerListResponse.self, from: Data(Self.containerListPayload.utf8))
    XCTAssertFalse(response.resourceSortSupported)
    XCTAssertNil(response.data.first?.resourceSample)
  }

  func testPaginatorAdvancesByServerPageSizeAfterShortDecodedPage() async throws {
    let starts = StartRecorder()
    let paginator = ArcanePaginator<Int>(limit: 50) { start, _ in
      await starts.record(start)
      switch start {
      case 0:
        return Self.page(data: Array(0..<49), currentPage: 1, totalItems: 101, pageSize: 50)
      case 50:
        return Self.page(data: Array(50..<100), currentPage: 2, totalItems: 101, pageSize: 50)
      case 100:
        return Self.page(data: [100], currentPage: 3, totalItems: 101, pageSize: 50)
      default:
        XCTFail("Unexpected page start: \(start)")
        return Self.page(data: [], currentPage: 4, totalItems: 101, pageSize: 50)
      }
    }

    var values: [Int] = []
    for try await value in paginator {
      values.append(value)
    }

    let recordedStarts = await starts.values()
    XCTAssertEqual(recordedStarts, [0, 50, 100])
    XCTAssertEqual(values.count, 100)
    XCTAssertEqual(values.last, 100)
  }

  func testPaginatorUsesShortPageForUnknownTotals() async throws {
    let starts = StartRecorder()
    let paginator = ArcanePaginator<Int>(limit: 2) { start, _ in
      await starts.record(start)
      if start == 0 {
        return Self.page(data: [1, 2], currentPage: 1, totalItems: -1, totalPages: -1, pageSize: 2)
      }
      return Self.page(data: [3], currentPage: 2, totalItems: -1, totalPages: -1, pageSize: 2)
    }

    var values: [Int] = []
    for try await value in paginator {
      values.append(value)
    }

    let recordedStarts = await starts.values()
    XCTAssertEqual(recordedStarts, [0, 2])
    XCTAssertEqual(values, [1, 2, 3])
  }

  private static func page(
    data: [Int],
    currentPage: Int,
    totalItems: Int64,
    totalPages: Int64 = 3,
    pageSize: Int
  ) -> PaginatedResponse<Int> {
    PaginatedResponse(
      success: true,
      data: data,
      pagination: .init(
        totalPages: totalPages,
        totalItems: totalItems,
        currentPage: currentPage,
        itemsPerPage: pageSize
      )
    )
  }

  private func makeMockClient() -> ArcaneClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return ArcaneClient(
      configuration: .init(
        baseURL: URL(string: "https://arcane.example.com")!,
        urlSession: mock.session(configuration: configuration)
      )
    )
  }

  private static let validContainer = #"""
    {
      "id":"valid","names":["/valid"],"image":"nginx:latest","imageId":"sha256:1",
      "command":"nginx","created":1,"ports":[],"labels":{},"state":"running",
      "status":"Up","hostConfig":{},"networkSettings":{},"mounts":[]
    }
    """#

  private static let resourceSortedPayload = #"""
    {
      "success":true,
      "resourceSortSupported":true,
      "data":[
        {"id":"sampled","names":["/sampled"],"image":"nginx","imageId":"sha256:1","command":"","created":1,
         "ports":[],"labels":{},"state":"running","status":"Up","hostConfig":{},"networkSettings":{},"mounts":[],
         "resourceSample":{"cpuPercent":12.5,"memoryUsageBytes":268435456,"memoryLimitBytes":1073741824,
           "sampleTime":"2026-10-14T12:00:00.123456789Z"}},
        {"id":"stopped","names":["/stopped"],"image":"nginx","imageId":"sha256:1","command":"","created":1,
         "ports":[],"labels":{},"state":"exited","status":"Exited","hostConfig":{},"networkSettings":{},"mounts":[]},
        {"id":"malformed","names":["/malformed"],"image":"nginx","imageId":"sha256:1","command":"","created":1,
         "ports":[],"labels":{},"state":"running","status":"Up","hostConfig":{},"networkSettings":{},"mounts":[],
         "resourceSample":{"cpuPercent":"high"}}
      ],
      "counts":{"runningContainers":2,"stoppedContainers":1,"totalContainers":3},
      "pagination":{"totalPages":1,"totalItems":3,"currentPage":1,"itemsPerPage":20}
    }
    """#

  private static let containerListPayload = #"""
    {
      "success":true,
      "data":[\#(validContainer),{"names":[]}],
      "groups":[{"groupName":"project","items":[\#(validContainer),{"names":[]}]}],
      "counts":{"runningContainers":80,"stoppedContainers":21,"totalContainers":101},
      "pagination":{"totalPages":3,"totalItems":101,"currentPage":2,"itemsPerPage":50}
    }
    """#
}

private actor StartRecorder {
  private var recorded: [Int] = []

  func record(_ value: Int) {
    recorded.append(value)
  }

  func values() -> [Int] {
    recorded
  }
}
