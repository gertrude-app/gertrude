import Dependencies
import DuetSQL
import MacAppRoute

extension SelectPublicKeychains: Resolver {
  static func resolve(
    with input: Input,
    in context: MacApp.ChildContext,
  ) async throws -> Output {
    try await context.verifyOnboardingToken("SelectPublicKeychains", "70146cf3")

    let keychainIds = input.map { Keychain.Id($0) }
    var keychainNames: [String] = []

    for keychainId in keychainIds {
      let keychain = try await context.db.find(keychainId)
      guard keychain.isPublic else {
        throw context.error(
          id: "e24436ee",
          type: .unauthorized,
          debugMessage: "keychain \(keychainId.lowercased) is not public",
        )
      }

      let existing = try? await ChildKeychain.query()
        .where(.keychainId == keychainId)
        .where(.childId == context.child.id)
        .first(in: context.db)

      if existing == nil {
        try await context.db.create(ChildKeychain(
          childId: context.child.id,
          keychainId: keychainId,
        ))
      }
      keychainNames.append(keychain.name)
    }

    let task = Task {
      let parent = try await context.child.parent(in: context.db)
      let computerUser = try await context.computerUser()
      let idList = keychainIds.map(\.lowercased).joined(separator: ", ")
      let nameList = keychainNames.joined(separator: ", ")
      await get(dependency: \.slack).internal(
        .info,
        "(\(parent.adminSiteLink(.slack))) selected public keychains during onboarding: \(nameList)",
      )
      try await context.db.create(InterestingEvent(
        eventId: "04f00574",
        kind: "event",
        context: "macapp",
        computerUserId: computerUser.id,
        parentId: parent.id,
        detail: "selected \(keychainNames.count) public keychain(s) during onboarding: \(idList)",
      ))
    }

    if context.env.mode == .test {
      _ = try await task.value
    }

    return .success
  }
}
