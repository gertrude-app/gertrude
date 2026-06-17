import GertieApp

public extension CrossPromoCampaign {
  var hasGuaranteedExit: Bool {
    if self.style == .sheet, self.dismissable { return true }
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
