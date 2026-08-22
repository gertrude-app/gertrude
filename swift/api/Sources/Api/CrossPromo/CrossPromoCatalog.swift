import Foundation
import GertieApp

enum CrossPromoCatalog {
  enum App: Hashable, Sendable {
    case gertrudeAm
    case gertrudeMusic
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
    .gertrudeAm: [
      Self.gertrudeMusicAmOnboardingParent,
      Self.gertrudeMusicAmChildHome,
    ],
    .gertrudeMusic: [],
    .iosBlocker: [
      Self.gertrudeMusicBlockerOnboarding,
      Self.gertrudeMusicBlockerHome,
    ],
  ]

  static func select(app: App, for device: Device) -> [CrossPromoCampaign] {
    // TODO: suppress promos for apps already used via device.deviceId
    self.campaigns[app] ?? []
  }

  static let gertrudeMusicBlockerOnboarding = CrossPromoCampaign(
    campaignId: "ios-blocker-onboarding-gertrude-music-v1",
    placement: "iosBlockerOnboarding",
    style: .screen,
    headline: "Introducing Gertrude Music",
    body: "You choose the music. They get a delightful listening app that shows only what you’ve approved—no search, feeds, chat, or recommendations.",
    image: .init(
      url: "https://gertrude-web-assets.nyc3.digitaloceanspaces.com/xpromo/gertrude-music-v1.webp",
      description: "Gertrude Music icon over a blurred album library",
    ),
    primaryCta: .init(
      label: "Get Gertrude Music",
      action: .openAppStoreProduct("6782194077"),
    ),
    secondaryCta: .init(
      label: "Send a link ↗",
      action: .share("https://gertrude.app/music"),
    ),
    tertiaryCta: .init(label: "No thanks", action: .dismiss),
    dismissable: false,
  )

  static let gertrudeMusicBlockerHome = CrossPromoCampaign(
    campaignId: "ios-blocker-home-gertrude-music-v1",
    placement: "iosBlockerHome",
    style: .sheet,
    headline: "Meet Gertrude Music",
    body: "Enjoy a delightful music app that shows only music chosen for you by a parent or accountability partner—no search, feeds, chat, or recommendations.",
    image: .init(
      url: "https://gertrude-web-assets.nyc3.digitaloceanspaces.com/xpromo/gertrude-music-v1.webp",
      description: "Gertrude Music icon over a blurred album library",
    ),
    primaryCta: .init(
      label: "Get Gertrude Music",
      action: .openAppStoreProduct("6782194077"),
    ),
    secondaryCta: .init(
      label: "Send a link ↗",
      action: .share("https://gertrude.app/music"),
    ),
    tertiaryCta: .init(label: "No thanks", action: .dismiss),
    dismissable: true,
  )

  static let gertrudeMusicAmOnboardingParent = CrossPromoCampaign(
    campaignId: "am-onboarding-parent-gertrude-music-v1",
    placement: "amOnboardingParent",
    style: .sheet,
    headline: "Introducing Gertrude Music",
    body: "You choose the music. They get a delightful listening app that shows only what you’ve approved—no search, feeds, chat, or recommendations.",
    image: .init(
      url: "https://gertrude-web-assets.nyc3.digitaloceanspaces.com/xpromo/gertrude-music-v1.webp",
      description: "Gertrude Music icon over a blurred album library",
    ),
    primaryCta: .init(
      label: "Get Gertrude Music",
      action: .openAppStoreProduct("6782194077"),
    ),
    secondaryCta: .init(
      label: "Send a link ↗",
      action: .share("https://gertrude.app/music"),
    ),
    tertiaryCta: .init(label: "No thanks", action: .dismiss),
    dismissable: false,
  )

  static let gertrudeMusicAmChildHome = CrossPromoCampaign(
    campaignId: "am-child-home-gertrude-music-v1",
    placement: "amChildHome",
    style: .sheet,
    headline: "Meet Gertrude Music",
    body: "Enjoy a delightful music app that shows only music chosen for you by a parent or accountability partner—no search, feeds, chat, or recommendations.",
    image: .init(
      url: "https://gertrude-web-assets.nyc3.digitaloceanspaces.com/xpromo/gertrude-music-v1.webp",
      description: "Gertrude Music icon over a blurred album library",
    ),
    primaryCta: .init(
      label: "Get Gertrude Music",
      action: .openAppStoreProduct("6782194077"),
    ),
    secondaryCta: .init(
      label: "Send a link ↗",
      action: .share("https://gertrude.app/music"),
    ),
    tertiaryCta: .init(label: "No thanks", action: .dismiss),
    dismissable: true,
  )
}
