import Foundation
import IOSRoute
import PodcastRoute

protocol IOSModelIdentifiable {
  var modelIdentifier: String { get }
}

extension IOSModelIdentifiable {
  var modelName: String {
    ModelIdentifier.marketingName(for: self.modelIdentifier)
  }
}

extension PodcastEvent: IOSModelIdentifiable {}
extension IOSApp.PendingSupervision: IOSModelIdentifiable {}
extension IOSApp.Device: IOSModelIdentifiable {}
extension IOSEvent: IOSModelIdentifiable {}
extension LogPodcastEvent_v2.Input: IOSModelIdentifiable {}
extension LogIOSEvent_v2.Input: IOSModelIdentifiable {}

enum ModelIdentifier {
  static func fromLegacyDeviceType(_ value: String) -> String {
    switch value {
    case "iPad":
      "iPad,unknown"
    default:
      "iPhone,unknown"
    }
  }

  static func deviceType(from modelIdentifier: String) -> String {
    if modelIdentifier.hasPrefix("iPad") { return "iPad" }
    return "iPhone"
  }

  static func marketingName(for modelIdentifier: String) -> String {
    self.mapping[modelIdentifier] ?? self.fallbackMarketingName(modelIdentifier)
  }

  static func alertIfUnknown(_ modelIdentifier: String) {
    guard self.mapping[modelIdentifier] == nil else {
      return
    }
    Task {
      await get(dependency: \.slack).internal(
        .info,
        "Unknown iOS *model identifier:* `\(modelIdentifier)`, add name to `ModelIdentifier.swift`",
      )
    }
  }

  private static func fallbackMarketingName(_ identifier: String) -> String {
    if identifier.hasPrefix("iPad") { return "iPad" }
    return "iPhone"
  }

  private static let mapping: [String: String] = [
    // iPhone 17 series (2025)
    "iPhone18,1": "iPhone 17 Pro",
    "iPhone18,2": "iPhone 17 Pro Max",
    "iPhone18,3": "iPhone 17",

    // iPhone 16 series (2024)
    "iPhone17,1": "iPhone 16 Pro",
    "iPhone17,2": "iPhone 16 Pro Max",
    "iPhone17,3": "iPhone 16",
    "iPhone17,4": "iPhone 16 Plus",
    "iPhone17,5": "iPhone 16e",

    // iPhone 15 series (2023)
    "iPhone15,4": "iPhone 15",
    "iPhone15,5": "iPhone 15 Plus",
    "iPhone16,1": "iPhone 15 Pro",
    "iPhone16,2": "iPhone 15 Pro Max",

    // iPhone 14 series (2022)
    "iPhone14,7": "iPhone 14",
    "iPhone14,8": "iPhone 14 Plus",
    "iPhone15,2": "iPhone 14 Pro",
    "iPhone15,3": "iPhone 14 Pro Max",

    // iPhone 13 series (2021)
    "iPhone14,2": "iPhone 13 Pro",
    "iPhone14,3": "iPhone 13 Pro Max",
    "iPhone14,4": "iPhone 13 mini",
    "iPhone14,5": "iPhone 13",

    // iPhone 12 series (2020)
    "iPhone13,1": "iPhone 12 mini",
    "iPhone13,2": "iPhone 12",
    "iPhone13,3": "iPhone 12 Pro",
    "iPhone13,4": "iPhone 12 Pro Max",

    // iPhone 11 series (2019)
    "iPhone12,1": "iPhone 11",
    "iPhone12,3": "iPhone 11 Pro",
    "iPhone12,5": "iPhone 11 Pro Max",

    // iPhone XS/XR (2018)
    "iPhone11,2": "iPhone XS",
    "iPhone11,4": "iPhone XS Max",
    "iPhone11,6": "iPhone XS Max",
    "iPhone11,8": "iPhone XR",

    // iPhone X/8 (2017)
    "iPhone10,1": "iPhone 8",
    "iPhone10,2": "iPhone 8 Plus",
    "iPhone10,3": "iPhone X",
    "iPhone10,4": "iPhone 8",
    "iPhone10,5": "iPhone 8 Plus",
    "iPhone10,6": "iPhone X",

    // iPhone SE
    "iPhone14,6": "iPhone SE (3rd gen)",
    "iPhone12,8": "iPhone SE (2nd gen)",

    // iPad Pro M4 (2024)
    "iPad16,3": "iPad Pro 11-inch (M4)",
    "iPad16,4": "iPad Pro 11-inch (M4)",
    "iPad16,5": "iPad Pro 13-inch (M4)",
    "iPad16,6": "iPad Pro 13-inch (M4)",

    // iPad Air M3 (2025)
    "iPad15,3": "iPad Air 11-inch (M3)",
    "iPad15,4": "iPad Air 11-inch (M3)",
    "iPad15,5": "iPad Air 13-inch (M3)",
    "iPad15,6": "iPad Air 13-inch (M3)",

    // iPad Air M2 (2024)
    "iPad14,8": "iPad Air 11-inch (M2)",
    "iPad14,9": "iPad Air 11-inch (M2)",
    "iPad14,10": "iPad Air 13-inch (M2)",
    "iPad14,11": "iPad Air 13-inch (M2)",

    // iPad Pro M2 (2022)
    "iPad14,3": "iPad Pro 11-inch (M2)",
    "iPad14,4": "iPad Pro 11-inch (M2)",
    "iPad14,5": "iPad Pro 12.9-inch (M2)",
    "iPad14,6": "iPad Pro 12.9-inch (M2)",

    // iPad Pro M1 (2021)
    "iPad13,4": "iPad Pro 11-inch (M1)",
    "iPad13,5": "iPad Pro 11-inch (M1)",
    "iPad13,6": "iPad Pro 11-inch (M1)",
    "iPad13,7": "iPad Pro 11-inch (M1)",
    "iPad13,8": "iPad Pro 12.9-inch (M1)",
    "iPad13,9": "iPad Pro 12.9-inch (M1)",
    "iPad13,10": "iPad Pro 12.9-inch (M1)",
    "iPad13,11": "iPad Pro 12.9-inch (M1)",

    // iPad Air (5th gen, 2022)
    "iPad13,16": "iPad Air (5th gen)",
    "iPad13,17": "iPad Air (5th gen)",

    // iPad Air (4th gen, 2020)
    "iPad13,1": "iPad Air (4th gen)",
    "iPad13,2": "iPad Air (4th gen)",

    // iPad Air (3rd gen, 2019)
    "iPad11,3": "iPad Air (3rd gen)",
    "iPad11,4": "iPad Air (3rd gen)",

    // iPad mini (7th gen, 2024)
    "iPad16,1": "iPad mini (7th gen)",
    "iPad16,2": "iPad mini (7th gen)",

    // iPad mini (6th gen, 2021)
    "iPad14,1": "iPad mini (6th gen)",
    "iPad14,2": "iPad mini (6th gen)",

    // iPad mini (5th gen, 2019)
    "iPad11,1": "iPad mini (5th gen)",
    "iPad11,2": "iPad mini (5th gen)",

    // iPad (11th gen, 2024)
    "iPad15,7": "iPad (11th gen)",
    "iPad15,8": "iPad (11th gen)",

    // iPad (10th gen, 2022)
    "iPad13,18": "iPad (10th gen)",
    "iPad13,19": "iPad (10th gen)",

    // iPad (9th gen, 2021)
    "iPad12,1": "iPad (9th gen)",
    "iPad12,2": "iPad (9th gen)",

    // iPad (8th gen, 2020)
    "iPad11,6": "iPad (8th gen)",
    "iPad11,7": "iPad (8th gen)",

    // iPad (7th gen, 2019)
    "iPad7,11": "iPad (7th gen)",
    "iPad7,12": "iPad (7th gen)",

    // Legacy/unknown backfill values
    "iPhone,unknown": "iPhone",
    "iPad,unknown": "iPad",
  ]
}
