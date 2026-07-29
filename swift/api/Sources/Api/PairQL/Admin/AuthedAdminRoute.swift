import PairQL
import Vapor

enum AuthedAdminRoute: PairRoute {
  case subscriptionsOverview
  case cohortAnalysis
  case macOverview
  case iOSOverview
  case platformVersionStats
  case iOSDetailedStats
  case iOSDevicesList(IOSDevicesList.Input)
  case iOSDeviceEvents(IOSDeviceEvents.Input)
  case podcastOverview
  case podcastInstallsList(PodcastInstallsList.Input)
  case podcastInstallDetail(PodcastInstallDetail.Input)
  case musicOverview
  case musicInstallsList(MusicInstallsList.Input)
  case musicInstallDetail(MusicInstallDetail.Input)
  case parentsList(ParentsList.Input)
  case parentDetail(ParentDetail.Input)
  case deleteParent(DeleteParent.Input)
  case searchParentByEmail(SearchParentByEmail.Input)
  case appRatings(AppRatings.Input)
  case appNamingStats
  case getUnidentifiedApps(GetUnidentifiedApps.Input)
  case getIdentifiedAppsForAdmin
  case promoteApp(PromoteApp.Input)
  case getPairqlTelemetrySummary(GetPairqlTelemetrySummary.Input)
  case getRecentPairqlErrors(GetRecentPairqlErrors.Input)
  case getParentRecentTelemetry(GetParentRecentTelemetry.Input)

  nonisolated(unsafe) static let router = OneOf {
    Route(.case(Self.subscriptionsOverview)) {
      Operation(SubscriptionsOverview.self)
    }
    Route(.case(Self.cohortAnalysis)) {
      Operation(CohortAnalysis.self)
    }
    Route(.case(Self.macOverview)) {
      Operation(MacOverview.self)
    }
    Route(.case(Self.iOSOverview)) {
      Operation(IOSOverview.self)
    }
    Route(.case(Self.platformVersionStats)) {
      Operation(PlatformVersionStats.self)
    }
    Route(.case(Self.iOSDetailedStats)) {
      Operation(IOSDetailedStats.self)
    }
    Route(.case(Self.iOSDevicesList)) {
      Operation(IOSDevicesList.self)
      Body(.input(IOSDevicesList.self))
    }
    Route(.case(Self.iOSDeviceEvents)) {
      Operation(IOSDeviceEvents.self)
      Body(.input(IOSDeviceEvents.self))
    }
    Route(.case(Self.podcastOverview)) {
      Operation(PodcastOverview.self)
    }
    Route(.case(Self.podcastInstallsList)) {
      Operation(PodcastInstallsList.self)
      Body(.input(PodcastInstallsList.self))
    }
    Route(.case(Self.podcastInstallDetail)) {
      Operation(PodcastInstallDetail.self)
      Body(.input(PodcastInstallDetail.self))
    }
    Route(.case(Self.musicOverview)) {
      Operation(MusicOverview.self)
    }
    Route(.case(Self.musicInstallsList)) {
      Operation(MusicInstallsList.self)
      Body(.input(MusicInstallsList.self))
    }
    Route(.case(Self.musicInstallDetail)) {
      Operation(MusicInstallDetail.self)
      Body(.input(MusicInstallDetail.self))
    }
    Route(.case(Self.parentsList)) {
      Operation(ParentsList.self)
      Body(.input(ParentsList.self))
    }
    Route(.case(Self.parentDetail)) {
      Operation(ParentDetail.self)
      Body(.input(ParentDetail.self))
    }
    Route(.case(Self.deleteParent)) {
      Operation(DeleteParent.self)
      Body(.input(DeleteParent.self))
    }
    Route(.case(Self.searchParentByEmail)) {
      Operation(SearchParentByEmail.self)
      Body(.input(SearchParentByEmail.self))
    }
    Route(.case(Self.appRatings)) {
      Operation(AppRatings.self)
      Body(.input(AppRatings.self))
    }
    Route(.case(Self.appNamingStats)) {
      Operation(AppNamingStats.self)
    }
    Route(.case(Self.getUnidentifiedApps)) {
      Operation(GetUnidentifiedApps.self)
      Body(.input(GetUnidentifiedApps.self))
    }
    Route(.case(Self.getIdentifiedAppsForAdmin)) {
      Operation(GetIdentifiedAppsForAdmin.self)
    }
    Route(.case(Self.promoteApp)) {
      Operation(PromoteApp.self)
      Body(.input(PromoteApp.self))
    }
    Route(.case(Self.getPairqlTelemetrySummary)) {
      Operation(GetPairqlTelemetrySummary.self)
      Body(.input(GetPairqlTelemetrySummary.self))
    }
    Route(.case(Self.getRecentPairqlErrors)) {
      Operation(GetRecentPairqlErrors.self)
      Body(.input(GetRecentPairqlErrors.self))
    }
    Route(.case(Self.getParentRecentTelemetry)) {
      Operation(GetParentRecentTelemetry.self)
      Body(.input(GetParentRecentTelemetry.self))
    }
  }
}

extension AuthedAdminRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {
    case .subscriptionsOverview:
      let output = try await SubscriptionsOverview.resolve(in: context)
      return try await self.respond(with: output)
    case .cohortAnalysis:
      let output = try await CohortAnalysis.resolve(in: context)
      return try await self.respond(with: output)
    case .macOverview:
      let output = try await MacOverview.resolve(in: context)
      return try await self.respond(with: output)
    case .iOSOverview:
      let output = try await IOSOverview.resolve(in: context)
      return try await self.respond(with: output)
    case .platformVersionStats:
      let output = try await PlatformVersionStats.resolve(in: context)
      return try await self.respond(with: output)
    case .iOSDetailedStats:
      let output = try await IOSDetailedStats.resolve(in: context)
      return try await self.respond(with: output)
    case .iOSDevicesList(let input):
      let output = try await IOSDevicesList.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .iOSDeviceEvents(let input):
      let output = try await IOSDeviceEvents.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .podcastOverview:
      let output = try await PodcastOverview.resolve(in: context)
      return try await self.respond(with: output)
    case .podcastInstallsList(let input):
      let output = try await PodcastInstallsList.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .podcastInstallDetail(let input):
      let output = try await PodcastInstallDetail.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .musicOverview:
      let output = try await MusicOverview.resolve(in: context)
      return try await self.respond(with: output)
    case .musicInstallsList(let input):
      let output = try await MusicInstallsList.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .musicInstallDetail(let input):
      let output = try await MusicInstallDetail.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .parentsList(let input):
      let output = try await ParentsList.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .parentDetail(let input):
      let output = try await ParentDetail.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .deleteParent(let input):
      let output = try await DeleteParent.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .searchParentByEmail(let input):
      let output = try await SearchParentByEmail.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .appRatings(let input):
      let output = try await AppRatings.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .appNamingStats:
      let output = try await AppNamingStats.resolve(in: context)
      return try await self.respond(with: output)
    case .getUnidentifiedApps(let input):
      let output = try await GetUnidentifiedApps.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getIdentifiedAppsForAdmin:
      let output = try await GetIdentifiedAppsForAdmin.resolve(in: context)
      return try await self.respond(with: output)
    case .promoteApp(let input):
      let output = try await PromoteApp.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getPairqlTelemetrySummary(let input):
      let output = try await GetPairqlTelemetrySummary.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getRecentPairqlErrors(let input):
      let output = try await GetRecentPairqlErrors.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getParentRecentTelemetry(let input):
      let output = try await GetParentRecentTelemetry.resolve(with: input, in: context)
      return try await self.respond(with: output)
    }
  }
}
