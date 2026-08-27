import Dependencies
import DuetSQL
import Foundation
import GertieApp
import IOSAppsRoute
import XCore

extension LogAppEvent {
  static func resolveMusicEvent(_ input: Input, in context: Context) async throws -> Output {
    let deviceId = input.deviceId.map { IOSDevice.Id($0) }

    if let deviceId {
      try await MusicApp.Install.ensureExists(
        deviceId: deviceId,
        modelIdentifier: input.modelIdentifier,
        iosVersion: input.iosVersion,
        appVersion: input.appVersion,
        in: context.db,
      )
    }

    try await context.db.create(MusicApp.Event(
      eventId: input.eventId,
      level: input.level,
      domain: input.domain,
      detail: input.detail,
      deviceId: deviceId,
      modelIdentifier: input.modelIdentifier,
      iosVersion: input.iosVersion,
      appVersion: input.appVersion,
    ))

    ModelIdentifier.alertIfUnknown(input.modelIdentifier)

    if context.env.mode == .prod,
       input.level > .debug,
       await musicEventShouldSlack(input, deviceId: deviceId, in: context) {
      await get(dependency: \.slack).internal(
        input.app.slackChannel,
        musicEventSlackMessage(input, deviceId: deviceId, in: context),
      )
    }

    return .success
  }
}

private func musicEventShouldSlack(
  _ input: LogEventRequest,
  deviceId: IOSDevice.Id?,
  in context: Context,
) async -> Bool {
  switch input.eventId {
  case musicOnboardingCompleteEventId:
    await isFirstMusicEvent(input.eventId, deviceId: deviceId, since: nil, in: context)
  case musicPlaybackFailedEventId, musicTrackUnavailableEventId:
    await isFirstMusicEvent(
      input.eventId,
      deviceId: deviceId,
      since: Date(subtractingHours: 1),
      in: context,
    )
  default:
    true
  }
}

private func isFirstMusicEvent(
  _ eventId: String,
  deviceId: IOSDevice.Id?,
  since: Date?,
  in context: Context,
) async -> Bool {
  guard let deviceId else { return false }
  var query = MusicApp.Event.query()
    .where(.deviceId == deviceId)
    .where(.eventId == eventId)
  if let since {
    query = query.where(.createdAt > since)
  }
  return await (try? query.count(in: context.db)) == 1
}

private func musicEventSlackMessage(
  _ input: LogEventRequest,
  deviceId: IOSDevice.Id?,
  in context: Context,
) async -> String {
  let search = githubSearch(input.eventId)
  let detail = input.detail.map { " - \($0)" } ?? ""
  let name = EventLabel.name(input.app, input.eventId) ?? input.eventId
  let base = "\(input.app.marketingName) event: \(search) `\(name)`\(detail)"

  guard let deviceId else { return base }

  guard let device = try? await context.db.find(deviceId) as IOSDevice,
        let child = try? await device.child(in: context.db),
        let parent = try? await child.parent(in: context.db) else {
    return base
  }

  let install = AdminLink().slack(
    to: .musicInstall(deviceId: deviceId.rawValue),
    text: "see install",
  )
  return base
    + ", parent: \(parent.adminSiteLink(.slack)), child: `\(child.name)`,"
    + " device: `\(input.modelName)`, \(install)"
}

private let musicOnboardingCompleteEventId = "8af8b414"
private let musicPlaybackFailedEventId = "f357b375"
private let musicTrackUnavailableEventId = "e1423c41"
