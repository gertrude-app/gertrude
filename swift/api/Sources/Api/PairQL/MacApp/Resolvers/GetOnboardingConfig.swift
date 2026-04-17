import DuetSQL
import MacAppRoute

private typealias AlwaysBlockedGroupModel = Api.AlwaysBlockedGroup

extension GetOnboardingConfig: NoInputResolver {
  static func resolve(in context: MacApp.ChildContext) async throws -> Output {
    let keychains = try await Keychain.query()
      .where(.isPublic == true)
      .all(in: context.db)

    let groups = try await AlwaysBlockedGroupModel.query()
      .all(in: context.db)

    let preselectedIds = groups
      .filter(\.recommended)
      .map(\.id.rawValue)

    return Output(
      publicKeychains: keychains.map { keychain in
        PublicKeychain(
          id: keychain.id.rawValue,
          name: keychain.name,
          description: keychain.description,
          warning: keychain.warning,
          brandColor: keychain.brandColor,
        )
      },
      alwaysBlocked: AlwaysBlocked(
        groups: groups.map { group in
          AlwaysBlockedGroup(
            id: group.id.rawValue,
            name: group.name,
            description: group.description,
            longDescription: group.longDescription,
          )
        },
        preselected: preselectedIds,
      ),
    )
  }
}
