import DuetSQL
import GertieApp
import IOSAppsRoute
import XCTest
import XExpect

@testable import Api

final class LogAppEventResolverTests: ApiTestCase, @unchecked Sendable {
  func testLogsBlockerEventAndEnsuresInstall() async throws {
    let input = LogEventRequest(
      app: .blocker,
      eventId: "491cb92a",
      level: .err,
      domain: "filter",
      detail: "controller proxy: failed to fetch rules",
      deviceId: UUID(14),
      modelIdentifier: "iPhone16,1",
      appVersion: "2.3.4",
      iosVersion: "18.5",
    )

    let output = try await LogAppEvent.resolve(with: input, in: .mock)

    expect(output).toEqual(.success)
    let event = try await IOSEvent.query()
      .where(.eventId == input.eventId)
      .first(in: self.db)
    expect(event.level).toEqual(.err)
    expect(event.domain).toEqual("filter")
    expect(event.detail).toEqual("controller proxy: failed to fetch rules")
    expect(event.deviceId?.rawValue).toEqual(input.deviceId)
    expect(event.modelIdentifier).toEqual("iPhone16,1")
    expect(event.appVersion).toEqual("2.3.4")
    expect(event.iosVersion).toEqual("18.5")

    let install = try await BlockerApp.Install.query()
      .where(.deviceId == IOSDevice.Id(input.deviceId!))
      .first(in: self.db)
    expect(install.appVersion).toEqual("2.3.4")
  }

  func testLogsMusicEventAndEnsuresInstall() async throws {
    let input = LogEventRequest(
      app: .music,
      eventId: "5fa833da",
      level: .warn,
      domain: "playback",
      detail: "detail",
      deviceId: UUID(12),
      modelIdentifier: "iPhone16,1",
      appVersion: "1.2.3",
      iosVersion: "18.5",
    )

    let output = try await LogAppEvent.resolve(with: input, in: .mock)

    expect(output).toEqual(.success)
    let event = try await MusicApp.Event.query()
      .where(.eventId == input.eventId)
      .first(in: self.db)
    expect(event.level).toEqual(.warn)
    expect(event.domain).toEqual("playback")
    expect(event.detail).toEqual("detail")
    expect(event.deviceId?.rawValue).toEqual(input.deviceId)
    expect(event.modelIdentifier).toEqual("iPhone16,1")
    expect(event.appVersion).toEqual("1.2.3")
    expect(event.iosVersion).toEqual("18.5")

    let install = try await MusicApp.Install.query()
      .where(.deviceId == IOSDevice.Id(input.deviceId!))
      .first(in: self.db)
    expect(install.appVersion).toEqual("1.2.3")
  }

  func testLogsPodcastEventAndEnsuresInstall() async throws {
    let input = LogEventRequest(
      app: .podcasts,
      eventId: "50e16bd1",
      level: .warn,
      domain: "playback",
      detail: "downloaded file missing",
      deviceId: UUID(13),
      modelIdentifier: "iPhone16,1",
      appVersion: "1.2.3",
      iosVersion: "18.5",
    )

    let output = try await LogAppEvent.resolve(with: input, in: .mock)

    expect(output).toEqual(.success)
    let event = try await PodcastEvent.query()
      .where(.eventId == input.eventId)
      .first(in: self.db)
    expect(event.level).toEqual(.warn)
    expect(event.domain).toEqual("playback")
    expect(event.detail).toEqual("downloaded file missing")
    expect(event.deviceId).toEqual(input.deviceId.map { IOSDevice.Id($0) })
    expect(event.modelIdentifier).toEqual("iPhone16,1")
    expect(event.appVersion).toEqual("1.2.3")
    expect(event.iosVersion).toEqual("18.5")

    let install = try await PodcastApp.Install.query()
      .where(.deviceId == IOSDevice.Id(input.deviceId!))
      .first(in: self.db)
    expect(install.appVersion).toEqual("1.2.3")
  }
}
