extension BillingAccountSnapshot {
  func paymentActionForMissingCapability(
    _ capability: Capability,
  ) -> GetSubscriptionPanel_v2.Action? {
    guard !self.can(capability), capability != .connectMacApp else { return nil }

    let targetTier: StripeSubscription.Tier = capability == .useGertrudeMusic
      ? .medium
      : .light

    if let sub = self.stripeSubscription, sub.stripeStatus == .pastDue {
      let config: GetSubscriptionPanel_v2.PortalConfig = switch sub.tier {
      case .light: .lightTier
      case .medium: .mediumTier
      case .full: .default
      }
      return .openBillingPortal(config: config)
    }

    if let sub = self.liveSubscription, sub.tier < targetTier {
      return .changeSubscriptionTier(to: targetTier)
    }

    if self.billingIdentity?.lastStripeSubscriptionId != nil {
      return .reactivateViaCheckout(tier: targetTier)
    }

    return .startCheckout(tier: targetTier)
  }
}
