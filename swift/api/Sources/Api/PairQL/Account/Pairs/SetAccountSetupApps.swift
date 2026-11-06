import DuetSQL
import PairQL

struct SetAccountSetupApps: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var apps: [Parent.SetupApp]
  }
}

extension SetAccountSetupApps: Resolver {
  static func resolve(with input: Input, in context: AccountOwnerContext) async throws -> Output {
    let apps = Parent.SetupApp.allCases.filter(input.apps.contains)
    var parent = context.accountOwner
    guard parent.setupApps != apps else { return .success }
    parent.setupApps = apps
    try await context.db.update(parent)
    return .success
  }
}
