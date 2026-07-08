import DuetSQL
import Foundation
import GertieApp
import IOSAppsRoute
import PodcastRoute

extension LogPodcastEvent_v3: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    await context.db.logDeprecated("LogPodcastEvent(v3)")

    let (level, domain) = podcastEventLevelAndDomain(input.kind)

    return try await LogAppEvent.resolve(with: LogEventRequest(
      app: .podcasts,
      eventId: input.eventId,
      level: level,
      domain: domain,
      detail: input.detail,
      deviceId: input.deviceId,
      modelIdentifier: input.modelIdentifier,
      appVersion: input.appVersion,
      iosVersion: input.iosVersion,
    ), in: context)
  }
}

// helpers

func podcastEventLevelAndDomain(_ kind: String) -> (EventLevel, String?) {
  switch kind {
  case "info": (.info, nil)
  case "error": (.err, nil)
  case "subscription": (.info, "subscription")
  default: (.warn, nil)
  }
}

func isPodcastLegacyIAPPaymentEvent(_ eventId: String) -> Bool {
  ["af0a338f", "a72104d7"].contains(eventId)
}

let midClaimPinSetEventId = "c3e9a1f4"

/// We don't record StoreKit.AppStore.Environment or inAppOwnershipType, so we
/// use originalID length as a proxy (verified against Apple's App Store Server
/// API for every logged originalID as of 2026-05-12):
///   - length <= 15:            host PURCHASED — the real paying customer
///   - length 18 (typ. "505…"): FAMILY_SHARED echo of someone else's purchase
///   - length 16 ("200000…"):   Sandbox/Xcode test transaction
func iapIdIsRootPurchase(_ originalID: String) -> Bool {
  originalID.count <= 15
}

private let originalIdRegex = try! NSRegularExpression(pattern: #"originalID:\s*(\d+)"#)

func extractPodcastLegacyIAPTxnId(_ detail: String?) -> String? {
  guard let detail else { return nil }
  let range = NSRange(detail.startIndex ..< detail.endIndex, in: detail)
  guard let match = originalIdRegex.firstMatch(in: detail, options: [], range: range),
        match.numberOfRanges >= 2,
        let captureRange = Range(match.range(at: 1), in: detail) else {
    return nil
  }
  return String(detail[captureRange])
}

let paidPodcastEventIdsSQL = "('af0a338f', 'a72104d7')"

var podcastOriginalIDExprSQL: String {
  "(regexp_match(\(PodcastEvent.columnName(.detail)), 'originalID:\\s*(\\d+)'))[1]"
}

var hostPurchasePodcastEventPredicateSQL: String {
  "\(PodcastEvent.columnName(.eventId)) IN \(paidPodcastEventIdsSQL)"
    + " AND LENGTH(\(podcastOriginalIDExprSQL)) <= 15"
}

var familySharedOrSandboxPodcastEventPredicateSQL: String {
  "\(PodcastEvent.columnName(.eventId)) IN \(paidPodcastEventIdsSQL)"
    + " AND LENGTH(\(podcastOriginalIDExprSQL)) > 15"
}

struct HostPurchaseEventCountForOriginalID: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    var stmt = SQL.Statement("""
    SELECT COUNT(*) AS count
    FROM \(table: PodcastEvent.self)
    WHERE \(hostPurchasePodcastEventPredicateSQL)
      AND \(podcastOriginalIDExprSQL) =\(" ")
    """)
    if let originalID = bindings.first {
      stmt.components.append(.binding(originalID))
    }
    return stmt
  }

  var count: Int
}

struct FamilySharedOrSandboxEventCountForDevice: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    var stmt = SQL.Statement("""
    SELECT COUNT(*) AS count
    FROM \(table: PodcastEvent.self)
    WHERE \(familySharedOrSandboxPodcastEventPredicateSQL)
      AND \(PodcastEvent.columnName(.deviceId)) =\(" ")
    """)
    if let deviceId = bindings.first {
      stmt.components.append(.binding(deviceId))
    }
    return stmt
  }

  var count: Int
}

var grandfatherableLegacyIapPredicateSQL: String {
  "\(PodcastEvent.columnName(.eventId)) IN \(paidPodcastEventIdsSQL)"
    + " AND LENGTH(\(podcastOriginalIDExprSQL)) <> 16"
}

struct EarliestGrandfatherableLegacyIapForDevice: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    var stmt = SQL.Statement("""
    SELECT MIN(\(PodcastEvent.columnName(.createdAt))) AS created_at
    FROM \(table: PodcastEvent.self)
    WHERE \(grandfatherableLegacyIapPredicateSQL)
      AND \(PodcastEvent.columnName(.deviceId)) =\(" ")
    """)
    if let deviceId = bindings.first {
      stmt.components.append(.binding(deviceId))
    }
    return stmt
  }

  var createdAt: Date?
}
