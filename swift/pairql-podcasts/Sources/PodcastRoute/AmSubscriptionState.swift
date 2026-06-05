import Foundation
import PairQL
import TSCodable

@TSCodable
public enum AmSubscriptionState: PairNestable {
  case complimentary
  case active(expiresAt: Date)
  case fullTrial(expiresAt: Date)
  /// device-level AM 30-day trial derived from `podcast_app.installs.created_at`;
  /// survives claim -- the "30 days free, no account" product promise is honored
  /// regardless of when the parent connects an account
  case amTrial(expiresAt: Date)
  case unpaid(remediationUrl: URL?)
  /// honored window for a legacy $10 IAP payer; `showMigrationNag` is server-decided
  /// (no client date math); `migrationUrl` is an optional "learn more / convert"
  /// destination the dashboard can host (nil until that screen exists)
  case legacyGrandfathered(accessEndsAt: Date, showMigrationNag: Bool, migrationUrl: URL?)
  /// a legacy $10 IAP payer whose honored window has elapsed -- peer of
  /// `legacyGrandfathered`, kept distinct from `unpaid` so the client can still
  /// speak to their history; not an active entitlement
  case legacyExpired(paidAt: Date, remediationUrl: URL?)
}
