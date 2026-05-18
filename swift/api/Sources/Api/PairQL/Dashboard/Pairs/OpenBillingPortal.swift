import Dependencies
import Foundation
import PairQL
import Vapor
import XStripe

struct OpenBillingPortal: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var returnPath: String
    var configuration: GetSubscriptionPanel.PortalConfig
  }

  struct Output: PairOutput {
    var url: String
  }
}

extension OpenBillingPortal: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    @Dependency(\.stripe) var stripe
    @Dependency(\.env) var env

    let account = try await context.currentBillingAccount()
    guard let customerId = account.stripeCustomerId?.rawValue else {
      throw context.error(
        "a4d12c75",
        .badRequest,
        user: "No Stripe customer to open billing portal for.",
      )
    }

    let stripeConfiguration: String? = switch input.configuration {
    case .lightTier: env.stripe.portalConfigIdLightTier
    case .default: nil
    }

    let returnUrl = "\(context.dashboardUrl)\(input.returnPath)"
    let portal = try await stripe.createBillingPortalSession(
      customerId,
      stripeConfiguration,
      returnUrl,
    )
    return .init(url: portal.url)
  }
}
