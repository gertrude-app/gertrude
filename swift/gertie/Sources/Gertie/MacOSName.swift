public enum MacOSName: String, Codable, Sendable, CaseIterable {
  case catalina
  case bigSur
  case monterey
  case ventura
  case sonoma
  case sequoia
  case tahoe

  public init(major: Int, minor: Int) {
    switch (major, minor) {
    case (10, _): self = .catalina
    case (11, _): self = .bigSur
    case (12, _): self = .monterey
    case (13, _): self = .ventura
    case (14, _): self = .sonoma
    case (15, _): self = .sequoia
    case (26, _): self = .tahoe
    default: self = .tahoe
    }
  }
}
