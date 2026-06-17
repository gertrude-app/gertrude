extension BillingAccountSnapshot {
  func lightPlanPaymentAction(toEnable capability: Capability) -> GetSubscriptionPanel_v2.Action? {
    guard !self.can(capability), capability != .connectMacApp else { return nil }

    if let sub = self.stripeSubscription, sub.stripeStatus == .pastDue {
      return .openBillingPortal(config: sub.tier == .light ? .lightTier : .default)
    }

    if self.billingIdentity?.lastStripeSubscriptionId != nil {
      return .reactivateViaCheckout(tier: .light)
    }

    return .startCheckout(tier: .light)
  }
}
