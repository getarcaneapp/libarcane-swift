import Foundation
import Testing

@testable import Arcane

@Suite struct ActivityStreamContractsTests {
  @Test func modernStreamDecodesSnapshotsHeartbeatsAndStatusTransitions() async throws {
    let mock = MockURLProtocolSession()
    let client = makeActivityStreamClient(mock)
    let date = Date(timeIntervalSince1970: 1_780_000_000)
    let queued = streamActivity(status: .queued, date: date)
    let running = streamActivity(status: .running, date: date)
    let completed = streamActivity(status: .success, date: date)
    let payload =
      try multiplexedLine(
        .init(type: .snapshot, environmentID: "edge", activities: [queued], timestamp: date))
      + ArcaneJSON.makeEncoder().encode(ActivityStreamEvent(type: .heartbeat, timestamp: date))
      + Data("\n".utf8)
      + multiplexedLine(
        .init(type: .activity, environmentID: "edge", activity: running, timestamp: date))
      + multiplexedLine(
        .init(type: .activity, environmentID: "edge", activity: completed, timestamp: date))
    await mock.setStreamingHandler { request in
      #expect(request.httpMethod == "GET")
      #expect(request.url?.path == "/base/api/stream")
      let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems
      #expect(query?.first(where: { $0.name == "channels" })?.value == "activities")
      #expect(query?.first(where: { $0.name == "limit" })?.value == "17")
      let midpoint = payload.count / 2
      return .init(
        response: activityStreamResponse(request, status: 200),
        chunks: [Data(payload.prefix(midpoint)), Data(payload.dropFirst(midpoint))],
        holdOpen: false
      )
    }
    var events: [ActivityStreamEvent] = []
    for try await event in client.activities.stream(limit: 17) { events.append(event) }
    #expect(events.map(\.type) == [.snapshot, .heartbeat, .activity, .activity])
    #expect(events.first?.activities.first?.status == .queued)
    #expect(events[2].activity?.status == .running)
    #expect(events[3].activity?.status == .success)
    #expect(events[3].activity?.id == "activity-1")
    #expect(events[3].environmentID == "edge")
    #expect(await mock.requestCount() == 1)
  }

  @Test func modern404FallsBackToLegacyAndClosesRejectedRequest() async throws {
    let mock = MockURLProtocolSession()
    let client = makeActivityStreamClient(mock)
    await mock.setStreamingHandler { request in
      if request.url?.path == "/base/api/stream" {
        return .init(
          response: activityStreamResponse(request, status: 404), chunks: [], holdOpen: true)
      }
      #expect(request.url?.path == "/base/api/activities/stream")
      #expect(request.url?.query == "limit=19")
      return .init(
        response: activityStreamResponse(request, status: 200),
        chunks: [
          Data(#"{"type":"heartbeat","timestamp":"2026-06-01T15:01:00Z"}"#.utf8) + Data("\n".utf8)
        ], holdOpen: false)
    }
    var events: [ActivityStreamEvent] = []
    for try await event in client.activities.stream(limit: 19) { events.append(event) }
    #expect(events.map(\.type) == [.heartbeat])
    #expect(await mock.requestCount() == 2)
    try await requireStoppedRequests(mock, count: 1)
  }

  @Test(arguments: [401, 403, 500])
  func errorsDoNotFallBack(status: Int) async throws {
    let mock = MockURLProtocolSession()
    let client = makeActivityStreamClient(mock)
    await mock.setHandler { request in
      #expect(request.url?.path == "/base/api/stream")
      return (activityStreamResponse(request, status: status), Data())
    }
    do {
      for try await _ in client.activities.stream() {}
      Issue.record("Expected stream HTTP failure")
    } catch let error as ArcaneError {
      if status == 401 {
        #expect(error == .unauthorized)
      } else if status == 403 {
        #expect(error == .forbidden)
      } else {
        #expect(error == .server(code: "HTTP_500", message: ""))
      }
    }
    #expect(await mock.requestCount() == 1)
  }

  @Test func malformedModernPayloadDoesNotFallBack() async throws {
    let mock = MockURLProtocolSession()
    let client = makeActivityStreamClient(mock)
    await mock.setHandler { request in
      (
        activityStreamResponse(request, status: 200),
        Data(#"{"channel":"activities","activity":{"type":"activity","timestamp":"bad"}}"#.utf8)
          + Data("\n".utf8)
      )
    }
    do {
      for try await _ in client.activities.stream() {}
      Issue.record("Expected schema failure")
    } catch ArcaneError.decoding {}
    #expect(await mock.requestCount() == 1)
  }

  @Test func bothEndpointsMissingReturnsNotFound() async throws {
    let mock = MockURLProtocolSession()
    let client = makeActivityStreamClient(mock)
    await mock.setHandler { request in (activityStreamResponse(request, status: 404), Data()) }
    do {
      for try await _ in client.activities.stream() {}
      Issue.record("Expected missing endpoint")
    } catch ArcaneError.notFound {}
    #expect(await mock.requestCount() == 2)
  }

  @Test(arguments: [false, true])
  func cancellationClosesModernAndLegacyStreams(legacy: Bool) async throws {
    let mock = MockURLProtocolSession()
    let client = makeActivityStreamClient(mock)
    let signal = ActivityStreamSignal()
    await mock.setStreamingHandler { request in
      if legacy, request.url?.path == "/base/api/stream" {
        return .init(
          response: activityStreamResponse(request, status: 404), chunks: [], holdOpen: true)
      }
      return .init(
        response: activityStreamResponse(request, status: 200),
        chunks: [
          Data(#"{"type":"heartbeat","timestamp":"2026-06-01T15:01:00Z"}"#.utf8) + Data("\n".utf8)
        ], holdOpen: true)
    }
    let consumption = Task {
      do {
        for try await event in client.activities.stream() {
          #expect(event.type == .heartbeat)
          await signal.arrive()
        }
      } catch is CancellationError {}
    }
    await signal.wait()
    consumption.cancel()
    try await consumption.value
    try await requireStoppedRequests(mock, count: legacy ? 2 : 1)
    #expect(await mock.requestCount() == (legacy ? 2 : 1))
  }
}

private func makeActivityStreamClient(_ mock: MockURLProtocolSession) -> ArcaneClient {
  ArcaneClient(
    configuration: .init(
      baseURL: URL(string: "https://arcane.example.com/base")!,
      urlSession: mock.session(),
      retryPolicy: .init(
        maxAttempts: 1,
        baseBackoff: .milliseconds(1),
        maxBackoff: .milliseconds(1))))
}

private func activityStreamResponse(_ request: URLRequest, status: Int) -> HTTPURLResponse {
  HTTPURLResponse(
    url: request.url!,
    statusCode: status,
    httpVersion: nil,
    headerFields: ["Content-Type": "application/x-ndjson"])!
}

private func streamActivity(status: ActivityStatus, date: Date) -> Activity {
  Activity(
    id: "activity-1",
    environmentID: "edge",
    type: .projectDeploy,
    status: status,
    startedAt: date,
    createdAt: date)
}

private func multiplexedLine(_ event: ActivityStreamEvent) throws -> Data {
  Data(#"{"channel":"activities","activity":"#.utf8)
    + (try ArcaneJSON.makeEncoder().encode(event))
    + Data(#","timestamp":"2026-06-01T15:01:00Z"}"#.utf8) + Data("\n".utf8)
}

private func requireStoppedRequests(_ mock: MockURLProtocolSession, count: Int) async throws {
  let deadline = Date().addingTimeInterval(2)
  while await mock.stopLoadingCount() < count, Date() < deadline { await Task.yield() }
  #expect(await mock.stopLoadingCount() >= count)
}

private actor ActivityStreamSignal {
  private var arrived = false
  private var waiter: CheckedContinuation<Void, Never>?
  func arrive() {
    arrived = true
    waiter?.resume()
    waiter = nil
  }
  func wait() async {
    if arrived { return }
    await withCheckedContinuation { waiter = $0 }
  }
}
