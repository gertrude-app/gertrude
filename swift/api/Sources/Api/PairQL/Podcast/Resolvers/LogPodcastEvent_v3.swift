import Dependencies
import DuetSQL
import Foundation
import PodcastRoute
import XSlack

extension LogPodcastEvent_v3: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
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

    if context.env.mode == .prod {
      let slack = get(dependency: \.slack)
      var msg = "`\(input.label)`"
      if let detail = input.detail {
        msg += " - \(detail)"
      }
      let search = githubSearch(input.eventId)
      let slackSuppressed = suppressedPodcastSlackEventIds.contains(input.eventId)
      let (send, suppressed) = await PodcastSlackLimiter.shared.shouldSend(input.eventId)
      if send, !slackSuppressed {
        var message = "Podcast app event: \(search) \(msg)"
        if suppressed > 0 {
          message += " _(+\(suppressed) suppressed)_"
        }
        let channel: XSlack.Slack.Client.InternalChannel =
          podcastsLogsEventIds.contains(input.eventId) ? .podcastsLogs : .podcasts
        await slack.internal(channel, message)
      }

      if isPaidEvent(input.eventId),
         let originalID = parseOriginalID(input.detail),
         isProductionOriginalID(originalID) {
        let priorPaidEventCount = try await context.db.count(
          PaidProductionEventCountForOriginalID.self,
          withBindings: [.string(originalID)],
        )
        if priorPaidEventCount == 1 {
          await slack.internal(.info, "*FIRST Podcast Subscription* `\(input.modelName)`")
          await slack.internal(.podcasts, "*FIRST Podcast Subscription* `\(input.modelName)`")
          get(dependency: \.postmark).toSuperAdmin(
            "FIRST Podcast Subscription",
            "device: \(input.modelName)",
          )
        }
      }
    }

    return .success
  }
}

let paidEventIds = ["af0a338f", "a72104d7"]

func isPaidEvent(_ eventId: String) -> Bool {
  paidEventIds.contains(eventId)
}

func isProductionOriginalID(_ originalID: String) -> Bool {
  originalID.count <= 15
}

private let originalIdRegex = try! NSRegularExpression(pattern: #"originalID:\s*(\d+)"#)

func parseOriginalID(_ detail: String?) -> String? {
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

var paidProductionPodcastEventPredicateSQL: String {
  "\(PodcastEvent.columnName(.eventId)) IN \(paidPodcastEventIdsSQL)"
    + " AND LENGTH(\(podcastOriginalIDExprSQL)) <= 15"
}

var paidSandboxPodcastEventPredicateSQL: String {
  "\(PodcastEvent.columnName(.eventId)) IN \(paidPodcastEventIdsSQL)"
    + " AND LENGTH(\(podcastOriginalIDExprSQL)) > 15"
}

struct PaidProductionEventCountForOriginalID: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    var stmt = SQL.Statement("""
    SELECT COUNT(*) AS count
    FROM \(table: PodcastEvent.self)
    WHERE \(paidProductionPodcastEventPredicateSQL)
      AND \(podcastOriginalIDExprSQL) =\(" ")
    """)
    if let originalID = bindings.first {
      stmt.components.append(.binding(originalID))
    }
    return stmt
  }

  var count: Int
}

private let suppressedPodcastSlackEventIds: Set<String> = [
  "eeaa7b30",
  "45692a47",
  "ba664a9f",
  "4fa186eb",
]

private let podcastsLogsEventIds: Set<String> = [
  "4ac9084e",
  "d299b47a",
  "2e2c9e97",
  "8c975d36",
]

private actor PodcastSlackLimiter {
  static let shared = PodcastSlackLimiter()

  private var recent: [String: (count: Int, lastSent: Date)] = [:]
  private let cooldown: TimeInterval = 60

  func shouldSend(_ eventId: String) -> (send: Bool, suppressed: Int) {
    let now = Date()

    guard let entry = recent[eventId] else {
      self.recent[eventId] = (count: 0, lastSent: now)
      return (send: true, suppressed: 0)
    }

    if now.timeIntervalSince(entry.lastSent) >= self.cooldown {
      let suppressed = entry.count
      self.recent[eventId] = (count: 0, lastSent: now)
      return (send: true, suppressed: suppressed)
    }

    self.recent[eventId] = (count: entry.count + 1, lastSent: entry.lastSent)
    return (send: false, suppressed: 0)
  }
}
