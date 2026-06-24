import DuetSQL
import PairQL
import Vapor

struct PodcastInstallDetail: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Input: PairInput {
    var deviceId: UUID
  }

  struct Output: PairOutput {
    var deviceId: UUID
    var deviceType: String
    var iosVersion: String
    var appVersion: String
    var firstLaunch: Date?
    var isPaid: Bool
    var connectedAccount: IOSDevice.ConnectedAccount?
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
      .where(.deviceId == input.deviceId)
      .orderBy(.createdAt, .asc)
      .all(in: context.db)

    guard !events.isEmpty else {
      throw Abort(.notFound)
    }

    let firstLaunch = events.first { $0.eventId == "27c4f26a" }
    let isPaid = events.contains { event in
      guard isPodcastLegacyIAPPaymentEvent(event.eventId),
            let txnId = extractPodcastLegacyIAPTxnId(event.detail) else {
        return false
      }
      return iapIdIsRootPurchase(txnId)
    }
    let modelIdentifier = firstLaunch?.modelIdentifier ?? events.first?.modelIdentifier ?? "Unknown"
    let deviceType = ModelIdentifier.deviceType(from: modelIdentifier)
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

    let connectedAccount = try await Self.connectedAccount(
      deviceId: input.deviceId,
      in: context,
    )

    return .init(
      deviceId: input.deviceId,
      deviceType: deviceType,
      iosVersion: iosVersion,
      appVersion: appVersion,
      firstLaunch: firstLaunch?.createdAt,
      isPaid: isPaid,
      connectedAccount: connectedAccount,
      events: outputEvents,
      subscribedFeeds: subscribedFeeds,
    )
  }

  static func connectedAccount(
    deviceId: UUID,
    in context: Context,
  ) async throws -> IOSDevice.ConnectedAccount? {
    guard let device = try? await context.db.find(IOSDevice.Id(deviceId)) as IOSDevice else {
      return nil
    }
    return try await device.connectedAccount(in: context.db)
  }
}
