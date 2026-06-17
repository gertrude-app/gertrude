import PairQL

func requireGertrudeMusicAccess(
  in context: some ResolverContext,
  billing: BillingAccountSnapshot,
) throws {
  guard billing.can(.useGertrudeMusic) else {
    throw context.error(
      "ad0437fe",
      .paymentRequired,
      user: "Gertrude Music requires a Gertrude Light or Full subscription.",
    )
  }
}
