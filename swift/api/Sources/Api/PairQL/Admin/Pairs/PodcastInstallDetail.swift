import DuetSQL
import PairQL
import Vapor

struct PodcastInstallDetail: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Input: PairInput {
    var installId: UUID
  }

  struct Output: PairOutput {
    var installId: UUID
    var deviceType: String
    var iosVersion: String
    var appVersion: String
    var firstLaunch: Date?
    var isPaid: Bool
    var events: [Event]
    var subscribedFeeds: [SubscribedFeed]
  }

  struct Event: PairNestable {
    var id: String
    var eventId: String
    var kind: String
    var label: String
    var detail: String?
    var createdAt: Date
    var elapsedSeconds: Int?
  }

  struct SubscribedFeed: PairNestable {
    var url: String
    var subscribedAt: Date
  }
}

extension PodcastInstallDetail: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let events = try await PodcastEvent.query()
      .where(.installId == input.installId)
      .orderBy(.createdAt, .asc)
      .all(in: context.db)

    guard !events.isEmpty else {
      throw Abort(.notFound)
    }

    let firstLaunch = events.first { $0.eventId == "27c4f26a" }
    let isPaid = events.contains { $0.eventId == "a72104d7" }
    let deviceType = firstLaunch?.deviceType ?? events.first?.deviceType ?? "Unknown"
    let iosVersion = firstLaunch?.iosVersion ?? events.first?.iosVersion ?? "Unknown"
    let appVersion = firstLaunch?.appVersion ?? events.first?.appVersion ?? "Unknown"

    var outputEvents: [Event] = []
    for (index, event) in events.enumerated() {
      let elapsedSeconds: Int?
      if index == 0 {
        elapsedSeconds = nil
      } else {
        let previousEvent = events[index - 1]
        elapsedSeconds = Int(event.createdAt.timeIntervalSince(previousEvent.createdAt))
      }
      outputEvents.append(Event(
        id: event.id.rawValue.uuidString,
        eventId: event.eventId,
        kind: event.kind.rawValue,
        label: event.label,
        detail: event.detail,
        createdAt: event.createdAt,
        elapsedSeconds: elapsedSeconds,
      ))
    }

    let subscribedFeeds = events
      .filter { $0.eventId == "7785c87b" }
      .compactMap { event -> SubscribedFeed? in
        guard let detail = event.detail else { return nil }
        let url: String = if let commaIndex = detail.firstIndex(of: ",") {
          String(detail[..<commaIndex])
        } else {
          detail
        }
        return SubscribedFeed(url: url, subscribedAt: event.createdAt)
      }

    return .init(
      installId: input.installId,
      deviceType: deviceType,
      iosVersion: iosVersion,
      appVersion: appVersion,
      firstLaunch: firstLaunch?.createdAt,
      isPaid: isPaid,
      events: outputEvents,
      subscribedFeeds: subscribedFeeds,
    )
  }
}
