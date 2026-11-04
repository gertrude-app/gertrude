import DuetSQL
import PairQL

struct GetAccountSetup: Pair {
  static let auth: ClientAuth = .parent

  struct Output: PairOutput {
    var selectedApps: [Parent.SetupApp]?
    var hasPeople: Bool
    var completedApps: [Parent.SetupApp]
  }
}

extension GetAccountSetup: NoInputResolver {
  static func resolve(in context: AccountOwnerContext) async throws -> Output {
    let people = try await context.people()
    guard !people.isEmpty else {
      return .init(
        selectedApps: context.accountOwner.setupApps,
        hasPeople: false,
        completedApps: [],
      )
    }

    async let computerCountAsync = Computer.query()
      .where(.parentId == context.accountOwner.id)
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
      .mac: computerCountAsync > 0,
      .blocker: !blockerAsync.isEmpty,
      .music: !musicAsync.isEmpty,
      .podcasts: !podcastsAsync.isEmpty,
    ]

    return .init(
      selectedApps: context.accountOwner.setupApps,
      hasPeople: true,
      completedApps: Parent.SetupApp.allCases.filter { completed[$0] == true },
    )
  }
}
