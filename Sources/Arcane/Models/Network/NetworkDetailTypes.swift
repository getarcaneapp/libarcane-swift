import Foundation

/// A manager or worker participating in an overlay network.
public struct NetworkPeer: Hashable, Sendable, Identifiable {
  public var name: String
  public var address: String

  public var id: String { "\(name):\(address)" }

  public init(name: String, address: String) {
    self.name = name
    self.address = address
  }
}

/// A Swarm service attached to a network.
public struct NetworkServiceAttachment: Hashable, Sendable, Identifiable {
  public var id: String { name }
  public var name: String
  public var vip: String?
  public var ports: [String]

  public init(name: String, vip: String? = nil, ports: [String] = []) {
    self.name = name
    self.vip = vip
    self.ports = ports
  }
}
