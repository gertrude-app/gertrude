import Dependencies
import PairQL
import Vapor

struct StartFullTrial: Pair {
  static let auth: ClientAuth = .parent
  typealias Output = Infallible
}

extension StartFullTrial: NoInputResolver {
  static func resolve(in ctx: ParentContext) async throws -> Output {
    @Dependency(\.date.now) var now

    var identity = try await ctx.parent.ensureBillingIdentity(in: ctx.db)
    if identity.fullTrialStartedAt != nil {
      unexpected("14032c8b", ctx.parent.id)
      throw ctx.error(
        "acc9328a",
        .badRequest,
        user: "Trial already used, upgrade instead",
      )
    }
    identity.fullTrialStartedAt = now
    try await ctx.db.update(identity)

    if var subscription = try await ctx.parent.subscription(in: ctx.db) {
      switch (subscription.tier, subscription.trialStartedAt) {
      case (.full, _):
        unexpected("3484f942", ctx.parent.id)
        return .success
      case (.light, .none):
        subscription.trialStartedAt = now
        try await ctx.db.update(subscription)
      case (.light, .some):
        unexpected("14032c8b", ctx.parent.id)
        throw ctx.error(
          "acc9328a",
          .badRequest,
          user: "Trial already used, upgrade instead",
        )
      }
    } else {
      try await ctx.db.create(Subscription(
        parentId: ctx.parent.id,
        tier: .full,
        billingStatus: .trialing,
        trialStartedAt: now,
        statusExpiresAt: now + Plan.Full.trialLengthDays - Plan.Full.trialWarningDays,
      ))
    }
    return .success
  }
}
