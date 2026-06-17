import Foundation
import GertieApp

enum CrossPromoCatalog {
  enum App: Hashable, Sendable {
    case gertrudeAm
    case iosBlocker
  }

  struct Device: Sendable {
    var deviceId: UUID
    var appVersion: String
    var modelIdentifier: String
    var iosVersion: String
    var locale: String
  }

  static let campaigns: [App: [CrossPromoCampaign]] = [:]

  static func select(app: App, for device: Device) -> [CrossPromoCampaign] {
    // TODO: suppress promos for apps already used via device.deviceId
    self.campaigns[app] ?? []
  }
}
