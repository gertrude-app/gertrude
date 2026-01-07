import PairQL
import Vapor

enum AuthedAdminRoute: PairRoute {
  case macOverview
  case iOSOverview
  case iOSDetailedStats
  case iOSDevicesList(IOSDevicesList.Input)
  case iOSDeviceEvents(IOSDeviceEvents.Input)
  case podcastOverview
  case podcastInstallsList(PodcastInstallsList.Input)
  case podcastInstallDetail(PodcastInstallDetail.Input)
  case parentsList(ParentsList.Input)
  case parentDetail(ParentDetail.Input)
  case deleteParent(DeleteParent.Input)
  case searchParentByEmail(SearchParentByEmail.Input)

  nonisolated(unsafe) static let router = OneOf {
    Route(.case(Self.macOverview)) {
      Operation(MacOverview.self)
    }
    Route(.case(Self.iOSOverview)) {
      Operation(IOSOverview.self)
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
  }
}

extension AuthedAdminRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {
    case .macOverview:
      let output = try await MacOverview.resolve(in: context)
      return try await self.respond(with: output)
    case .iOSOverview:
      let output = try await IOSOverview.resolve(in: context)
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
    }
  }
}
