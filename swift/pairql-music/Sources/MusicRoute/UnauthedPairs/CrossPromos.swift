import Foundation
import GertieApp
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
      self.promos = try container.decode([LossyCrossPromoCampaign].self, forKey: .promos)
        .compactMap(\.campaign)
    }

    enum CodingKeys: String, CodingKey {
      case promos
    }
  }
}
