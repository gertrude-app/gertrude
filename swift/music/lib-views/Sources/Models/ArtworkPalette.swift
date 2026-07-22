public struct ArtworkPalette: Equatable, Hashable, Sendable {
  public let bgColor: String?
  public let textColor1: String?
  public let textColor2: String?
  public let textColor3: String?
  public let textColor4: String?

  public init(
    bgColor: String? = nil,
    textColor1: String? = nil,
    textColor2: String? = nil,
    textColor3: String? = nil,
    textColor4: String? = nil,
  ) {
    self.bgColor = bgColor
    self.textColor1 = textColor1
    self.textColor2 = textColor2
    self.textColor3 = textColor3
    self.textColor4 = textColor4
  }
}
