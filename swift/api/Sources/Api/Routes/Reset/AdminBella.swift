#if DEBUG
  import Dependencies
  import DuetSQL
  import Vapor
  import XCore

  enum AdminBella {
    enum Ids {
      static let bella = Parent.Id.from("BE200000-0000-0000-0000-000000000000")
    }

    enum Stripe {
      static let customer: BillingIdentity.StripeCustomerId = "cus_UVjr0bml6trccB"
      static let subscription: StripeSubscription.StripeId = "sub_1TWiO5GKRdhETuKAienkPyXZ"
    }

    static func create() async throws {
      @Dependency(\.db) var db
      let bella = try await db.create(Parent(
        id: Ids.bella,
        email: "bella-full-paid" |> Reset.testEmail,
        password: Bcrypt.hash("bella123"),
        emailVerifiedAt: Date(),
      ))

      try await db.create(BillingIdentity(
        parentId: bella.id,
        stripeCustomerId: Stripe.customer,
        lastStripeSubscriptionId: Stripe.subscription,
        lastPaidTier: .full,
      ))

      try await db.create(StripeSubscription(
        parentId: bella.id,
        tier: .full,
        stripeId: Stripe.subscription,
        stripeStatus: .active,
        currentPeriodEnd: Date() + .days(30),
      ))

      try await db.create(Parent.DashToken(
        value: .init(rawValue: bella.id.rawValue),
        parentId: bella.id,
      ))
    }
  }
#endif
