public struct CrossPromoCampaign: Codable, Equatable, Sendable {
  public var campaignId: String
  public var variant: String?
  public var placement: String
  public var style: CrossPromoStyle
  public var headline: String
  public var body: String
  public var image: CrossPromoImage?
  public var primaryCta: CrossPromoCta
  public var secondaryCta: CrossPromoCta?
  public var tertiaryCta: CrossPromoCta?
  public var dismissable: Bool

  public init(
    campaignId: String,
    variant: String? = nil,
    placement: String,
    style: CrossPromoStyle,
    headline: String,
    body: String,
    image: CrossPromoImage? = nil,
    primaryCta: CrossPromoCta,
    secondaryCta: CrossPromoCta? = nil,
    tertiaryCta: CrossPromoCta? = nil,
    dismissable: Bool,
  ) {
    self.campaignId = campaignId
    self.variant = variant
    self.placement = placement
    self.style = style
    self.headline = headline
    self.body = body
    self.image = image
    self.primaryCta = primaryCta
    self.secondaryCta = secondaryCta
    self.tertiaryCta = tertiaryCta
    self.dismissable = dismissable
  }
}

public enum CrossPromoStyle: String, Codable, Equatable, Sendable {
  case screen
  case sheet
}

public struct CrossPromoImage: Codable, Equatable, Sendable {
  public var url: String
  public var description: String?

  public init(url: String, description: String? = nil) {
    self.url = url
    self.description = description
  }
}

public struct CrossPromoCta: Codable, Equatable, Sendable {
  public var label: String
  public var action: CrossPromoAction

  public init(label: String, action: CrossPromoAction) {
    self.label = label
    self.action = action
  }
}

public enum CrossPromoAction: Codable, Equatable, Sendable {
  case openUrl(String)
  case openAppStoreProduct(String)
  case share(String)
  case dismiss
}

public struct LossyCrossPromoCampaign: Decodable {
  public let campaign: CrossPromoCampaign?

  public init(from decoder: any Decoder) throws {
    self.campaign = try? CrossPromoCampaign(from: decoder)
  }
}
