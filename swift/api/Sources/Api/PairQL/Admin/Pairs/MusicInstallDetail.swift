import Dependencies
import DuetSQL
import PairQL
import Vapor

struct MusicInstallDetail: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Input: PairInput {
    var deviceId: UUID
  }

  struct Output: PairOutput {
    var deviceId: UUID
    var deviceType: String
    var iosVersion: String
    var appVersion: String
    var firstLaunch: Date
    var status: String
    var connectedAccount: IOSDevice.ConnectedAccount?
    var events: [Event]
    var approvedAlbums: [ApprovedAlbum]
  }

  struct Event: PairNestable {
    var id: String
    var eventId: String
    var level: String
    var domain: String?
    var label: String
    var detail: String?
    var createdAt: Date
    var elapsedSeconds: Int?
  }

  struct ApprovedAlbum: PairNestable {
    var title: String
    var artistName: String
    var artworkUrl: String?
    var trackCount: Int?
    var approvedAt: Date
  }
}

extension MusicInstallDetail: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    @Dependency(\.date.now) var now
    let deviceId = IOSDevice.Id(input.deviceId)
    guard let install = try await MusicApp.Install.query()
      .where(.deviceId == deviceId)
      .all(in: context.db)
      .first else {
      throw Abort(.notFound)
    }

    let device = try await install.device(in: context.db)
    let events = try await MusicApp.Event.query()
      .where(.deviceId == deviceId)
      .orderBy(.createdAt, .asc)
      .all(in: context.db)
    let connected = try await MusicApp.Token.query()
      .where(.installId == install.id)
      .exists(in: context.db)

    let approvedAlbums: [ApprovedAlbum] = if let child = try await device.child(in: context.db) {
      try await Music.ApprovedAlbum.query()
        .where(.childId == child.id)
        .orderBy(.createdAt, .desc)
        .all(in: context.db)
        .map {
          ApprovedAlbum(
            title: $0.title,
            artistName: $0.artistName,
            artworkUrl: $0.artworkUrl,
            trackCount: $0.trackCount,
            approvedAt: $0.createdAt,
          )
        }
    } else {
      []
    }

    return try await .init(
      deviceId: input.deviceId,
      deviceType: ModelIdentifier.deviceType(from: device.modelIdentifier),
      iosVersion: device.iosVersion,
      appVersion: install.appVersion,
      firstLaunch: install.createdAt,
      status: MusicInstallsList.status(
        deviceId: device.id,
        connected: connected,
        at: now,
        in: context,
      ),
      connectedAccount: device.connectedAccount(in: context.db),
      events: self.outputEvents(from: events),
      approvedAlbums: approvedAlbums,
    )
  }

  static func outputEvents(from events: [MusicApp.Event]) -> [Event] {
    var output: [Event] = []
    for (index, event) in events.enumerated() {
      let elapsedSeconds: Int?
      if index == 0 {
        elapsedSeconds = nil
      } else {
        let previousEvent = events[index - 1]
        elapsedSeconds = Int(event.createdAt.timeIntervalSince(previousEvent.createdAt))
      }
      output.append(Event(
        id: event.id.rawValue.uuidString,
        eventId: event.eventId,
        level: event.level.rawValue,
        domain: event.domain,
        label: EventLabel.music(event.eventId) ?? event.eventId,
        detail: event.detail,
        createdAt: event.createdAt,
        elapsedSeconds: elapsedSeconds,
      ))
    }
    return output
  }
}
