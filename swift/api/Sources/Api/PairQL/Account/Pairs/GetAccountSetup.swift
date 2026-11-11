import DuetSQL
import PairQL

struct GetAccountSetup: Pair {
  static let auth: ClientAuth = .parent

  struct Output: PairOutput {
    var selectedApps: [Parent.SetupApp]?
    var hasPeople: Bool
    var completedApps: [Parent.SetupApp]
    var hasNotifications: Bool
  }
}

extension GetAccountSetup: NoInputResolver {
  static func resolve(in context: AccountOwnerContext) async throws -> Output {
    let people = try await context.people()
    let hasNotifications = try await Parent.Notification.query()
      .where(.parentId == context.accountOwner.id)
      .count(in: context.db) > 0
    guard !people.isEmpty else {
      return .init(
        selectedApps: context.accountOwner.setupApps,
        hasPeople: false,
        completedApps: [],
        hasNotifications: hasNotifications,
      )
    }

    async let computerUserCountAsync = ComputerUser.query()
      .where(.childId |=| people.map(\.id))
      .count(in: context.db)
    let deviceIds = try await IOSDevice.query()
      .where(.childId |=| people.map(\.id))
      .all(in: context.db)
      .map(\.id)
    async let blockerAsync = BlockerApp.Token.connectedDeviceIds(among: deviceIds, in: context.db)
    async let musicAsync = MusicApp.Token.connectedDeviceIds(among: deviceIds, in: context.db)
    async let podcastsAsync = PodcastApp.Token.connectedDeviceIds(
      among: deviceIds,
      in: context.db,
    )

    let completed: [Parent.SetupApp: Bool] = try await [
      .mac: computerUserCountAsync > 0,
      .blocker: !blockerAsync.isEmpty,
      .music: !musicAsync.isEmpty,
      .podcasts: !podcastsAsync.isEmpty,
    ]

    return .init(
      selectedApps: context.accountOwner.setupApps,
      hasPeople: true,
      completedApps: Parent.SetupApp.allCases.filter { completed[$0] == true },
      hasNotifications: hasNotifications,
    )
  }
}
