import GertieApp

public extension CrossPromoCampaign {
  var hasGuaranteedExit: Bool {
    if self.style == .sheet, self.dismissable { return true }
    return self.hasDismissCta
  }

  var hasDismissCta: Bool {
    let ctas = [self.primaryCta] + [self.secondaryCta, self.tertiaryCta].compactMap(\.self)
    return ctas.contains { if case .dismiss = $0.action { true } else { false } }
  }

  func action(for slot: CrossPromoFeature.CtaSlot) -> CrossPromoAction? {
    switch slot {
    case .primary: self.primaryCta.action
    case .secondary: self.secondaryCta?.action
    case .tertiary: self.tertiaryCta?.action
    }
  }
}

public extension [CrossPromoCampaign] {
  func firstEligible(
    at placement: String,
    excluding dismissed: Set<String>,
  ) -> CrossPromoCampaign? {
    self.first { $0.placement == placement && !dismissed.contains($0.campaignId) }
  }
}
