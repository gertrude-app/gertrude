#if DEBUG
  import Dependencies
  import DuetSQL
  import Vapor
  import XCore

  enum AdminBart {
    enum Ids {
      static let bart = Parent.Id.from("BE500000-0000-0000-0000-000000000000")
    }

    enum Stripe {
      static let customer: BillingIdentity.StripeCustomerId = "cus_UVjrs9vq14TWYo"
      static let subscription: StripeSubscription.StripeId = "sub_1TWiOVGKRdhETuKASwV2WG2y"
    }

    static func create() async throws {
      @Dependency(\.db) var db
      let bart = try await db.create(Parent(
        id: Ids.bart,
        email: "bart-lapsed-full" |> Reset.testEmail,
        password: Bcrypt.hash("bart123"),
        emailVerifiedAt: Date(),
      ))

      try await db.create(BillingIdentity(
        parentId: bart.id,
        stripeCustomerId: Stripe.customer,
        lastStripeSubscriptionId: Stripe.subscription,
        lastPaidTier: .full,
      ))

      try await db.create(Parent.DashToken(
        value: .init(rawValue: bart.id.rawValue),
        parentId: bart.id,
      ))
    }
  }
#endif
