import PairQL
import Vapor

struct StartFullTrial: Pair {
  static let auth: ClientAuth = .parent
  typealias Output = Infallible
}

// resolver

extension StartFullTrial: NoInputResolver {
  static func resolve(in ctx: ParentContext) async throws -> Output {
    let now = get(dependency: \.date.now)
    guard var subscription = try await ctx.parent.subscription(in: ctx.db) else {
      try await ctx.db.create(Subscription(
        parentId: ctx.parent.id,
        tier: .full,
        billingStatus: .trialing,
        trialStartedAt: now,
        statusExpiresAt: now + Plan.Full.trialLengthDays - Plan.Full.trialWarningDays,
      ))
      return .success
    }

    switch (subscription.tier, subscription.trialStartedAt) {
    case (.full, _):
      unexpected("3484f942", ctx.parent.id)
      return .success // shouldn't get here, but app connection will catch bad subs states
    case (.light, .none):
      subscription.trialStartedAt = now
      try await ctx.db.update(subscription)
      return .success
    case (.light, .some):
      unexpected("14032c8b", ctx.parent.id)
      throw ctx.error("acc9328a", .badRequest, user: "Trial already used, upgrade instead")
    }
  }
}
