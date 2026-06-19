import Foundation

// deprecated: use group UUIDs from GetBlockGroups API response.
// BlockRules_v2 still uses this type for wire compatibility with old app versions.
public enum BlockGroup: String, Sendable, Hashable, Codable, Equatable, CaseIterable, Identifiable {
  case gifs
  case appleMapsImages
  case aiFeatures
  case appStoreImages
  case spotlightSearches
  case ads
  case whatsAppFeatures
  case appleWebsite
  case spotifyImages

  public var id: String { "\(self)" }
}

public extension [BlockGroup] {
  static var all: [BlockGroup] {
    [
      .gifs,
      .appleMapsImages,
      .aiFeatures,
      .appStoreImages,
      .spotlightSearches,
      .ads,
      .whatsAppFeatures,
      .appleWebsite,
      .spotifyImages,
    ]
  }
}

public extension RangeReplaceableCollection where Element == BlockGroup {
  mutating func toggle(_ blockGroup: BlockGroup) {
    if self.contains(blockGroup) {
      self.removeAll { $0 == blockGroup }
    } else {
      self.append(blockGroup)
    }
  }
}

public extension BlockGroup {
  var legacyUUID: UUID {
    switch self {
    case .gifs: UUID(uuidString: "087628b2-742c-4164-a3cc-717c4ac72c1a")!
    case .appleMapsImages: UUID(uuidString: "baecbdda-49c0-43ec-a931-777810f34c13")!
    case .aiFeatures: UUID(uuidString: "c15351df-ff54-4b75-8f7e-2b522a3a0dae")!
    case .appStoreImages: UUID(uuidString: "283a29ec-13eb-4bd3-9211-eb920bd85158")!
    case .spotlightSearches: UUID(uuidString: "df7fb156-488a-497b-aa12-c585d3fa4e6c")!
    case .ads: UUID(uuidString: "1ea5f1b8-1b14-4894-9913-56cfee98bd48")!
    case .whatsAppFeatures: UUID(uuidString: "8e337c3c-2efb-404a-8eb3-781661231844")!
    case .appleWebsite: UUID(uuidString: "9cd776c0-f1a6-43c2-861b-f6c6ec8cf513")!
    case .spotifyImages: UUID(uuidString: "ee242fc6-07c7-4694-a3ce-0323b0ddc1fe")!
    }
  }
}
