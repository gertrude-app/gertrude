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

  static let campaigns: [App: [CrossPromoCampaign]] = [
    .iosBlocker: [Self.gertrudeAmBlockerOnboarding],
  ]

  static func select(app: App, for device: Device) -> [CrossPromoCampaign] {
    // TODO: suppress promos for apps already used via device.deviceId
    self.campaigns[app] ?? []
  }

  static let gertrudeAmBlockerOnboarding = CrossPromoCampaign(
    campaignId: "ios-blocker-onboarding-gertrude-am-v1",
    placement: "iosBlockerOnboarding",
    style: .screen,
    headline: "Kid-safe podcasts too!",
    body: "Gertrude AM is a podcast player app where parents choose the shows and kids listen independently. Searching and subscribing to podcasts is locked behind a PIN code.",
    image: .init(
      url: "https://gertrude-web-assets.nyc3.digitaloceanspaces.com/xpromo/gertrude-am-icon-512.png",
      description: "Gertrude AM app icon",
    ),
    primaryCta: .init(label: "Get Gertrude AM", action: .openAppStoreProduct("6753187429")),
    secondaryCta: .init(
      label: "Send a link ↗",
      action: .share("https://gertrude.app/blog/safe-podcast-app-for-kids"),
    ),
    tertiaryCta: .init(label: "No thanks", action: .dismiss),
    dismissable: false,
  )
}
