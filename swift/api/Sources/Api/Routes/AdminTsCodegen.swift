import Foundation
import Gertie
import GertieApp
import PairQL
import TypeScriptInterop

enum AdminTsCodegenRoute: PairQLTsCodegenRoute {
  static var logName: String {
    "Admin".red
  }

  static var sharedAliases: [Config.Alias] {
    [
      .init(NoInput.self, as: "void"),
      .init(Date.self, as: "ISODateString"),
      .init(StripeSubscription.StripeId.self, as: "string"),
    ]
  }

  static var sharedTypes: [(String, Any.Type)] {
    [
      ("ServerPqlError", PqlError.self),
      ("ClientAuth", ClientAuth.self),
      ("DeviceModelFamily", DeviceModelFamily.self),
      ("PaidSubscription", PaidSubscription.self),
      ("PlanStatus", PlanStatus.self),
      ("BillingStatus", BillingStatus.self),
      ("SubscriptionTier", StripeSubscription.Tier.self),
      ("StripeSubscriptionStatus", StripeSubscription.StripeStatus.self),
      ("GertrudeApp", GertrudeIOSApp.self),
    ]
  }

  static var pairqlPairs: [any Pair.Type] {
    [
      RequestAdminMagicLink.self,
      VerifyAdminMagicLink.self,
      SubscriptionsOverview.self,
      CohortAnalysis.self,
      MacOverview.self,
      IOSOverview.self,
      PlatformVersionStats.self,
      IOSDetailedStats.self,
      IOSDevicesList.self,
      IOSDeviceEvents.self,
      PodcastOverview.self,
      PodcastInstallsList.self,
      PodcastInstallDetail.self,
      MusicOverview.self,
      MusicInstallsList.self,
      MusicInstallDetail.self,
      ParentsList.self,
      ParentDetail.self,
      DeleteParent.self,
      SearchParentByEmail.self,
      AppRatings.self,
      AppNamingStats.self,
      GetUnidentifiedApps.self,
      GetIdentifiedAppsForAdmin.self,
      PromoteApp.self,
      GetPairqlTelemetrySummary.self,
      GetRecentPairqlErrors.self,
      GetParentRecentTelemetry.self,
    ]
  }
}
