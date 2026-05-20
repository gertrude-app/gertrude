import DuetSQL
import Foundation
import PodcastRoute
import XCTest
import XExpect

@testable import Api

final class LogPodcastEventResolverTests: ApiTestCase, @unchecked Sendable {
  func testLogPodcastEventCreatesRecord() async throws {
    let eventId = "abc123de"
    let kind = "info"
    let label = "The Daily"
    let detail = "Started playing episode 1234"
    let modelIdentifier = "iPhone15,2"
    let appVersion = "1.0.0"
    let iosVersion = "18.0.1"
    let installId = UUID()

    _ = try await LogPodcastEvent_v2.resolve(
      with: .init(
        eventId: eventId,
        kind: kind,
        label: label,
        detail: detail,
        installId: installId,
        modelIdentifier: modelIdentifier,
        appVersion: appVersion,
        iosVersion: iosVersion,
      ),
      in: .mock,
    )

    let retrieved = try await PodcastEvent.query()
      .where(.eventId == eventId)
      .first(in: self.db)

    expect(retrieved.eventId).toEqual(eventId)
    expect(retrieved.kind).toEqual(.info)
    expect(retrieved.label).toEqual(label)
    expect(retrieved.modelIdentifier).toEqual(modelIdentifier)
    expect(retrieved.appVersion).toEqual(appVersion)
    expect(retrieved.iosVersion).toEqual(iosVersion)
    expect(retrieved.deviceId).toEqual(installId)
    expect(retrieved.detail).toEqual(detail)
    expect(retrieved.createdAt).not.toBeNil()
  }

  func v3Input(
    _ deviceId: UUID,
    eventId: String = "abc123de",
    detail: String? = "Started playing episode 1234",
  ) -> LogPodcastEvent_v3.Input {
    .init(
      eventId: eventId,
      kind: "info",
      label: "The Daily",
      detail: detail,
      deviceId: deviceId,
      modelIdentifier: "iPhone15,2",
      appVersion: "1.6.0",
      iosVersion: "18.2",
    )
  }

  func testLogPodcastEventV3EnsuresDeviceAndInstall() async throws {
    let deviceId = UUID()

    _ = try await LogPodcastEvent_v3.resolve(with: self.v3Input(deviceId), in: .mock)

    // backward-compatible: the event row is still created unchanged
    let event = try await PodcastEvent.query()
      .where(.deviceId == deviceId)
      .first(in: self.db)
    expect(event.eventId).toEqual("abc123de")

    // augmentation: device + install rows now exist for the event's deviceId
    let device = try await self.db.find(IOSDevice.Id(deviceId))
    expect(device.modelIdentifier).toEqual("iPhone15,2")
    let install = try await PodcastApp.Install.query()
      .where(.deviceId == device.id)
      .first(in: self.db)
    expect(install.appVersion).toEqual("1.6.0")
  }

  func testLogPodcastEventV3IsIdempotentPreservingInstallCreatedAt() async throws {
    let deviceId = UUID()

    _ = try await LogPodcastEvent_v3.resolve(with: self.v3Input(deviceId), in: .mock)
    let first = try await PodcastApp.Install.query()
      .where(.deviceId == IOSDevice.Id(deviceId))
      .first(in: self.db)

    _ = try await LogPodcastEvent_v3.resolve(with: self.v3Input(deviceId), in: .mock)
    let installs = try await PodcastApp.Install.query()
      .where(.deviceId == IOSDevice.Id(deviceId))
      .all(in: self.db)
    expect(installs.count).toEqual(1)
    expect(installs[0].createdAt).toEqual(first.createdAt)

    // both event rows still recorded (events are not deduped by the augmentation)
    let events = try await PodcastEvent.query()
      .where(.deviceId == deviceId)
      .all(in: self.db)
    expect(events.count).toEqual(2)
  }
}
