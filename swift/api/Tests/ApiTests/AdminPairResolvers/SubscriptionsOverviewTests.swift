import XCTest
import XExpect

@testable import Api

final class SubscriptionsOverviewTests: ApiTestCase, @unchecked Sendable {
  func testProtectedChildrenCountsKnownChildrenAndAnonymousIOSDevicesOnce() async throws {
    let baseline = try await SubscriptionsOverview.protectedChildren(in: .mock)
    let parent = try await self.parent()
    let blockerAndMusicChild = try await self.db.create(Child.random {
      $0.parentId = parent.id
    })
    let musicOnlyChild = try await self.db.create(Child.random {
      $0.parentId = parent.id
    })

    let sharedDevice = try await self.db.create(IOSDevice.mock {
      $0.childId = blockerAndMusicChild.id
    })
    try await self.db.create(IOSEvent(
      eventId: "8d35f043",
      deviceId: sharedDevice.id,
      modelIdentifier: sharedDevice.modelIdentifier,
      iosVersion: sharedDevice.iosVersion,
    ))
    let blockerInstall = try await self.db.create(BlockerApp.Install(
      deviceId: sharedDevice.id,
      appVersion: "1.0.0",
    ))
    try await self.db.create(BlockerApp.Token(installId: blockerInstall.id))
    let sharedMusicInstall = try await self.db.create(MusicApp.Install(
      deviceId: sharedDevice.id,
      appVersion: "1.0.0",
    ))
    try await self.db.create(MusicApp.Token(installId: sharedMusicInstall.id))

    let musicOnlyDevice = try await self.db.create(IOSDevice.mock {
      $0.childId = musicOnlyChild.id
    })
    let musicOnlyInstall = try await self.db.create(MusicApp.Install(
      deviceId: musicOnlyDevice.id,
      appVersion: "1.0.0",
    ))
    try await self.db.create(MusicApp.Token(installId: musicOnlyInstall.id))

    let anonymousBlockerDevice = try await self.db.create(IOSDevice.mock)
    try await self.db.create(IOSEvent(
      eventId: "8d35f043",
      deviceId: anonymousBlockerDevice.id,
      modelIdentifier: anonymousBlockerDevice.modelIdentifier,
      iosVersion: anonymousBlockerDevice.iosVersion,
    ))
    let anonymousBlockerInstall = try await self.db.create(BlockerApp.Install(
      deviceId: anonymousBlockerDevice.id,
      appVersion: "1.0.0",
    ))
    try await self.db.create(BlockerApp.Token(installId: anonymousBlockerInstall.id))

    let anonymousPodcastDevice = try await self.db.create(IOSDevice.mock)
    try await self.db.create(PodcastEvent(
      eventId: "27c4f26a",
      deviceId: anonymousPodcastDevice.id,
      modelIdentifier: anonymousPodcastDevice.modelIdentifier,
      appVersion: "1.0.0",
      iosVersion: anonymousPodcastDevice.iosVersion,
    ))

    let protectedChildren = try await SubscriptionsOverview.protectedChildren(in: .mock)

    expect(protectedChildren - baseline).toEqual(4)
  }
}
