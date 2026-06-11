import Foundation
import PairQL

public struct CrossPromos: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var deviceId: UUID
    public var appVersion: String
    public var modelIdentifier: String
    public var iosVersion: String
    public var locale: String

    public init(
      deviceId: UUID,
      appVersion: String,
      modelIdentifier: String,
      iosVersion: String,
      locale: String,
    ) {
      self.deviceId = deviceId
      self.appVersion = appVersion
      self.modelIdentifier = modelIdentifier
      self.iosVersion = iosVersion
      self.locale = locale
    }
  }

  public struct Output: PairOutput {
    public var promos: [CrossPromoCampaign]

    public init(promos: [CrossPromoCampaign]) {
      self.promos = promos
    }

    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.promos = try container.decode([LossyCampaign].self, forKey: .promos)
        .compactMap(\.campaign)
    }

    enum CodingKeys: String, CodingKey {
      case promos
    }

    private struct LossyCampaign: Decodable {
      let campaign: CrossPromoCampaign?
      init(from decoder: any Decoder) throws {
        self.campaign = try? CrossPromoCampaign(from: decoder)
      }
    }
  }
}

public struct CrossPromoCampaign: PairNestable {
  public var campaignId: String
  public var variant: String?
  public var placement: CrossPromoPlacement
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
    placement: CrossPromoPlacement,
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

public enum CrossPromoPlacement: String, PairNestable {
  case amOnboardingParent
  case amChildHome
}

public enum CrossPromoStyle: String, PairNestable {
  case screen
  case sheet
}

public struct CrossPromoImage: PairNestable {
  public var url: String
  public var description: String?

  public init(url: String, description: String? = nil) {
    self.url = url
    self.description = description
  }
}

public struct CrossPromoCta: PairNestable {
  public var label: String
  public var action: CrossPromoAction

  public init(label: String, action: CrossPromoAction) {
    self.label = label
    self.action = action
  }
}

public enum CrossPromoAction: PairNestable {
  case openUrl(String)
  case openAppStoreProduct(String)
  case share(String)
  case dismiss
}
