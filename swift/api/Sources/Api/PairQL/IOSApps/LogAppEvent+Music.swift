import Dependencies
import DuetSQL
import Foundation
import GertieApp
import IOSAppsRoute

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

    if context.env.mode == .prod, input.level > .debug {
      let search = githubSearch(input.eventId)
      let detail = input.detail.map { " - \($0)" } ?? ""
      let name = EventLabel.name(input.app, input.eventId) ?? input.eventId
      await get(dependency: \.slack).internal(
        input.app.slackChannel,
        "\(input.app.marketingName) event: \(search) `\(name)`\(detail)",
      )
    }

    return .success
  }
}
