import Dependencies
import DuetSQL
import PodcastRoute

extension LogPodcastEvent: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    try await context.db.create(PodcastEvent(
      eventId: input.eventId,
      kind: .init(rawValue: input.kind) ?? .unexpected,
      label: input.label,
      detail: input.detail,
      installId: input.installId,
      deviceType: input.deviceType,
      appVersion: input.appVersion,
      iosVersion: input.iosVersion,
    ))

    if context.env.mode == .prod {
      let slack = get(dependency: \.slack)
      var msg = "`\(input.label)`"
      if let detail = input.detail {
        msg += " - \(detail)"
      }
      let search = githubSearch(input.eventId, repo: "gertrude-am")
      let message = "Podcast app event: \(search) \(msg)"
      await slack.internal(.podcasts, message)

      if input.eventId == "a72104d7", let installId = input.installId {
        let subscriptionCount = try await PodcastEvent.query()
          .where(.installId == installId)
          .where(.eventId == "a72104d7")
          .count(in: context.db)
        if subscriptionCount == 1 {
          await slack.internal(.info, "*FIRST Podcast Subscription* `\(input.deviceType)`")
          await slack.internal(.podcasts, "*FIRST Podcast Subscription* `\(input.deviceType)`")
          get(dependency: \.postmark).toSuperAdmin(
            "FIRST Podcast Subscription",
            "device: \(input.deviceType)",
          )
        }
      }
    }

    return .success
  }
}
