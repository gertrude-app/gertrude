import PairQL
import Vapor

// deprecated: remove after 2026-03-02
struct StripeUrl: Pair {
  static let auth: ClientAuth = .parent
  typealias Input = Subscription.Tier?

  struct Output: PairOutput {
    var url: String
  }
}

extension StripeUrl: Resolver {
  static func resolve(with tier: Input, in context: ParentContext) async throws -> Output {
    let v2Output = try await StripeUrl_v2.resolve(
      with: .init(
        successPath: "/checkout-success",
        cancelPath: "/checkout-cancel",
        tier: tier,
      ),
      in: context,
    )
    return Output(url: v2Output.url)
  }
}

extension Subscription.Tier: PairInput {}
