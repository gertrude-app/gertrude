import Foundation
import PairQL

public enum AmSubscriptionState: PairNestable {
  case active(expiresAt: Date?)
  case unpaid(remediationUrl: URL?)
  /// for those that paid the incorrect $10 non-renewing price so we
  /// can recover them into an account after honoring initial payment
  case legacyGrandfathered(paidAt: Date, expiresAt: Date, remediationUrl: URL?)
  /// a legacy $10 IAP payer whose 365-day honored window has elapsed --
  /// peer of `legacyGrandfathered`, kept distinct from `unpaid` so the
  /// client can still speak to their history; not an active entitlement
  case legacyExpired(paidAt: Date, remediationUrl: URL?)
}
