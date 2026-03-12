public enum FlowType: String {
  case browser
  case socket

  // context: https://gist.github.com/jaredh159/af45d98eee7f8a33b6b5af945ec23cfc
  public enum Legacy: Codable, Equatable, Sendable, Hashable {
    case browser
    case socket

    public var current: FlowType {
      switch self {
      case .browser: .browser
      case .socket: .socket
      }
    }
  }

  public var legacy: Legacy {
    switch self {
    case .browser: .browser
    case .socket: .socket
    }
  }
}

// conformances

extension FlowType: Equatable, Sendable, Hashable {}

extension FlowType: Codable {
  public init(from decoder: Decoder) throws {
    if let raw = try? decoder.singleValueContainer().decode(String.self),
       let value = FlowType(rawValue: raw) {
      self = value
      return
    }
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if let key = container.allKeys.first, let value = FlowType(rawValue: key.stringValue) {
      self = value
      return
    }
    throw DecodingError.dataCorrupted(
      .init(
        codingPath: decoder.codingPath,
        debugDescription: "Expected FlowType string or keyed object",
      ),
    )
  }

  private enum CodingKeys: String, CodingKey {
    case browser
    case socket
  }
}
