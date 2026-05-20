import Dependencies
import DuetSQL
import Foundation
import PodcastRoute
import XSlack

extension LogPodcastEvent_v3: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    try await PodcastApp.Install.ensureExists(
      deviceId: IOSDevice.Id(input.deviceId),
      modelIdentifier: input.modelIdentifier,
      iosVersion: input.iosVersion,
      appVersion: input.appVersion,
      in: context.db,
    )

    try await context.db.create(PodcastEvent(
      eventId: input.eventId,
      kind: .init(rawValue: input.kind) ?? .unexpected,
      label: input.label,
      detail: input.detail,
      deviceId: input.deviceId,
      modelIdentifier: input.modelIdentifier,
      appVersion: input.appVersion,
      iosVersion: input.iosVersion,
    ))

    ModelIdentifier.alertIfUnknown(input.modelIdentifier)

    if context.env.mode != .prod || suppressedEventIds.contains(input.eventId) {
      return .success
    }

    let iapTxnId = extractPodcastLegacyIAPTxnId(input.detail)
    let isFamilyShareIapEvent = iapTxnId.map { !iapIdIsRootPurchase($0) } ?? false

    Task {
      let slack = get(dependency: \.slack)

      if isFamilyShareIapEvent {
        if try await isPodcastFirstFamilyShareForDevice(input, in: context) {
          await slack.internal(
            .info,
            "*FIRST Podcast Family-Sharing Activation* `\(input.modelName)`",
          )
        }
        return // don't log duplicate family share txn events
      }

      let search = githubSearch(input.eventId)
      let msg = "`\(input.label)`\(input.detail.map { " - \($0)" } ?? "")"
      await slack.internal(.podcasts, "Podcast app event: \(search) \(msg)")

      if try await isPodcastFirstPayment(input, in: context) {
        await slack.internal(.info, "*FIRST Podcast Subscription* `\(input.modelName)`")
        await slack.internal(.podcasts, "*FIRST Podcast Subscription* `\(input.modelName)`")
        get(dependency: \.postmark).toSuperAdmin(
          "FIRST Podcast Subscription",
          "device: \(input.modelName)",
        )
      }
    }

    return .success
  }
}

// helpers

private func isPodcastFirstPayment(
  _ input: LogPodcastEvent_v3.Input,
  in ctx: Context,
) async throws -> Bool {
  guard isPodcastLegacyIAPPaymentEvent(input.eventId),
        let iapTxnId = extractPodcastLegacyIAPTxnId(input.detail),
        iapIdIsRootPurchase(iapTxnId) else {
    return false
  }
  let paidEventCount = try await ctx.db.count(
    HostPurchaseEventCountForOriginalID.self,
    withBindings: [.string(iapTxnId)],
  )
  return paidEventCount == 1
}

private func isPodcastFirstFamilyShareForDevice(
  _ input: LogPodcastEvent_v3.Input,
  in ctx: Context,
) async throws -> Bool {
  guard isPodcastLegacyIAPPaymentEvent(input.eventId) else {
    return false
  }
  let count = try await ctx.db.count(
    FamilySharedOrSandboxEventCountForDevice.self,
    withBindings: [.uuid(input.deviceId)],
  )
  return count == 1
}

func isPodcastLegacyIAPPaymentEvent(_ eventId: String) -> Bool {
  ["af0a338f", "a72104d7"].contains(eventId)
}

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

private let suppressedEventIds: Set<String> = [
  "4ac9084e", // skipped download invalidation while active
  "d299b47a", // episode play recovered after file check
  "2e2c9e97", // episode play recovery failed
  "8c975d36", // download success invalidated before commit
  "eeaa7b30", // legacy (v1.2): episode play, missing local file
  "45692a47", // legacy (v1.2-1.3): missing file for downloaded episode
  "ba664a9f", // legacy (v1.3): play missing file, recovered
  "4fa186eb", // legacy (v1.3): play missing file, dl failed
]
