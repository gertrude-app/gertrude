import Dependencies
import DuetSQL
import Vapor
import XCore

enum AdminBlanca {
  enum Ids {
    static let blanca = Parent.Id.from("BE400000-0000-0000-0000-000000000000")
  }

  enum Stripe {
    static let customer: BillingIdentity.StripeCustomerId = "cus_UVjruvEKpmru8L"
    static let subscription: StripeSubscription.StripeId = "sub_1TWiORGKRdhETuKANNYFWr7M"
  }

  static func create() async throws {
    @Dependency(\.db) var db
    let blanca = try await db.create(Parent(
      id: Ids.blanca,
      email: "blanca-lapsed-light" |> Reset.testEmail,
      password: Bcrypt.hash("blanca123"),
      emailVerifiedAt: Date(),
    ))

    try await db.create(BillingIdentity(
      parentId: blanca.id,
      stripeCustomerId: Stripe.customer,
      lastStripeSubscriptionId: Stripe.subscription,
      lastPaidTier: .light,
    ))

    try await db.create(Parent.DashToken(
      value: .init(rawValue: blanca.id.rawValue),
      parentId: blanca.id,
    ))
  }
}
