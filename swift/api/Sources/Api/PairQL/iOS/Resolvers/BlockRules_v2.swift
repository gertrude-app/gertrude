import Dependencies
import DuetSQL
import Gertie
import GertieIOS
import IOSRoute

extension BlockRules_v2: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    with(dependency: \.logger).info("BlockRules_v2: \(input)")

    var disabledGroups = input.disabledGroups
    if let version = Semver(input.version),
       version < Semver(major: 1, minor: 5, patch: 0) {
      disabledGroups.append(.spotifyImages)
    }

    let disabledGroupIds = disabledGroups.map { Postgres.Data.uuid($0.blockGroupId) }
    let deviceId: IOSApp.Device.Id? = input.vendorId == .init(.zero) ? nil : .init(input.vendorId)
    return try await IOSApp.BlockRule.query()
      .where(.or(
        .groupId != nil .&& .groupId |!=| disabledGroupIds,
        deviceId.map { .deviceId == $0 } ?? .never,
      ))
      .orderBy(.id, .asc)
      .all(in: ctx.db)
      .map(\.rule.legacy)
  }
}

// extensions

public extension GertieIOS.BlockGroup {
  var blockGroupId: UUID {
    let ids = CreateBlockGroups.GroupIds()
    return switch self {
    case .gifs: ids.gifs
    case .appleMapsImages: ids.appleMapsImages
    case .aiFeatures: ids.aiFeatures
    case .appStoreImages: ids.appStoreImages
    case .spotlightSearches: ids.spotlightSearches
    case .ads: ids.ads
    case .whatsAppFeatures: ids.whatsAppFeatures
    case .appleWebsite: ids.appleWebsite
    case .spotifyImages: ids.spotifyImages
    }
  }

  var blockGroupName: String {
    switch self {
    case .gifs: "GIFs"
    case .appleMapsImages: "Apple Maps images"
    case .aiFeatures: "AI features"
    case .appStoreImages: "App store images"
    case .spotlightSearches: "Spotlight"
    case .ads: "Ads"
    case .whatsAppFeatures: "WhatsApp"
    case .appleWebsite: "apple.com"
    case .spotifyImages: "Spotify images"
    }
  }
}
