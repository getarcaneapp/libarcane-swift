import Foundation

/// One frame from a finite project or image operation stream.
///
/// Current servers emit an activity frame first, followed by log or progress
/// frames, then an explicit success or failure frame. The legacy fields remain
/// optional so the same type can consume v1 Docker progress streams.
public struct OperationStreamEvent: Codable, Hashable, Sendable {
  public struct ProgressDetail: Codable, Hashable, Sendable {
    public var current: Int64?
    public var total: Int64?

    public init(current: Int64? = nil, total: Int64? = nil) {
      self.current = current
      self.total = total
    }
  }

  public var type: String?
  public var activityID: String?
  public var log: String?
  public var done: Bool?
  public var error: String?
  public var status: String?
  public var id: String?
  public var progress: String?
  public var progressDetail: ProgressDetail?
  public var stream: String?
  public var phase: String?
  public var service: String?

  public init(
    type: String? = nil,
    activityID: String? = nil,
    log: String? = nil,
    done: Bool? = nil,
    error: String? = nil,
    status: String? = nil,
    id: String? = nil,
    progress: String? = nil,
    progressDetail: ProgressDetail? = nil,
    stream: String? = nil,
    phase: String? = nil,
    service: String? = nil
  ) {
    self.type = type
    self.activityID = activityID
    self.log = log
    self.done = done
    self.error = error
    self.status = status
    self.id = id
    self.progress = progress
    self.progressDetail = progressDetail
    self.stream = stream
    self.phase = phase
    self.service = service
  }

  private enum CodingKeys: String, CodingKey {
    case type
    case activityID = "activityId"
    case log
    case done
    case error
    case status
    case id
    case progress
    case progressDetail
    case stream
    case phase
    case service
  }

  static func terminalAction(for event: Self) -> NDJSONStreamTerminalAction {
    if let error = event.error?.trimmingCharacters(in: .whitespacesAndNewlines),
      !error.isEmpty {
      return .fail(.server(code: "OPERATION_FAILED", message: error))
    }
    if event.done == true {
      return .finish
    }
    return .continueStreaming
  }
}
