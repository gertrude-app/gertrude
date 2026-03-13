import Dependencies
import DuetSQL
import Foundation
import PodcastRoute

extension LogPodcastEvent_v2: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    try await context.db.create(PodcastEvent(
      eventId: input.eventId,
      kind: .init(rawValue: input.kind) ?? .unexpected,
      label: input.label,
      detail: input.detail,
      installId: input.installId,
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
        await slack.internal(.podcasts, message)
      }

      if input.eventId == "a72104d7", let installId = input.installId {
        let subscriptionCount = try await PodcastEvent.query()
          .where(.installId == installId)
          .where(.eventId == "a72104d7")
          .count(in: context.db)
        if subscriptionCount == 1 {
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

// suppress pre 1.3.1 missing file events, to test new mitigations
private let suppressedPodcastSlackEventIds: Set<String> = [
  "eeaa7b30",
  "45692a47",
  "ba664a9f",
  "4fa186eb",
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
