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

    if identity.lastPaidTier == .full {
      _ = try? await ctx.db.create(InterestingEvent(
        eventId: "trial_after_prior_full_paid",
        kind: "billing",
        context: "dash",
        parentId: ctx.parent.id,
        detail: "last_sub: \(identity.lastStripeSubscriptionId?.rawValue ?? "(nil)")",
      ))
    }

    return .success
  }
}
