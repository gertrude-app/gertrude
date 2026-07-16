import DuetSQL
import PairQL
import Vapor
import XCTest
import XExpect

@testable import Api

final class SaveExtendedSupervisionControlsResolverTests: ApiTestCase, @unchecked Sendable {
  func testWritePersistsListsAndNilClears() async throws {
    let parent = try await self.parent()
    try await self.db.create(BillingIdentity(parentId: parent.id, isComplimentary: true))
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    try await self.db.create(BlockerApp.Supervision(
      deviceId: device.id,
      supervisedAt: .reference, // <-- supervised, required for writes
    ))

    let output = try await SaveExtendedSupervisionControls.resolve(
      with: .init(deviceId: device.id, controls: .init(
        whitelistedAppBundleIds: ["com.apple.mobilesafari"],
        webAllowList: [.init(url: "https://gertrude.app", title: "Gertrude")],
      )),
      in: parent.context,
    )

    expect(output).toEqual(.success)
    var settings = try await BlockerApp.ProfileSettings.ensure(for: device.id, in: self.db)
    expect(settings.whitelistedAppBundleIds).toEqual(["com.apple.mobilesafari"])
    expect(settings.webAllowList)
      .toEqual([.init(url: "https://gertrude.app", title: "Gertrude")])

    _ = try await SaveExtendedSupervisionControls.resolve(
      with: .init(deviceId: device.id, controls: .init(
        whitelistedAppBundleIds: nil,
        webAllowList: nil,
      )),
      in: parent.context,
    )

    settings = try await BlockerApp.ProfileSettings.ensure(for: device.id, in: self.db)
    expect(settings.whitelistedAppBundleIds).toBeNil()
    expect(settings.webAllowList).toBeNil()
  }

  func testWritePersistsExtendedRestrictionsAndNilClears() async throws {
    let parent = try await self.parent()
    try await self.db.create(BillingIdentity(parentId: parent.id, isComplimentary: true))
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    try await self.db.create(BlockerApp.Supervision(
      deviceId: device.id,
      supervisedAt: .reference,
    ))

    // distinct, non-uniform values so a mis-mapped field surfaces as a round-trip mismatch
    _ = try await SaveExtendedSupervisionControls.resolve(
      with: .init(deviceId: device.id, controls: .init(
        allowItunes: false,
        allowMusicService: true,
        allowRadioService: false,
        allowNews: true,
        allowBookstore: false,
        allowExplicitContent: true,
        ratingMovies: 0,
        ratingTvShows: 0,
        allowSafari: false,
        allowSpotlightInternetResults: true,
        allowDefinitionLookup: false,
        allowAutomaticAppDownloads: true,
        allowAppClips: false,
        allowSystemAppRemoval: true,
        allowAssistant: false,
        allowGameCenter: true,
        forceDelayedSoftwareUpdates: true,
        enforcedSoftwareUpdateDelay: 45,
        forceAutomaticDateAndTime: true,
      )),
      in: parent.context,
    )

    var settings = try await BlockerApp.ProfileSettings.ensure(for: device.id, in: self.db)
    expect(settings.allowItunes).toEqual(false)
    expect(settings.allowMusicService).toEqual(true)
    expect(settings.allowRadioService).toEqual(false)
    expect(settings.allowNews).toEqual(true)
    expect(settings.allowBookstore).toEqual(false)
    expect(settings.allowExplicitContent).toEqual(true)
    expect(settings.ratingMovies).toEqual(0)
    expect(settings.ratingTvShows).toEqual(0)
    expect(settings.allowSafari).toEqual(false)
    expect(settings.allowSpotlightInternetResults).toEqual(true)
    expect(settings.allowDefinitionLookup).toEqual(false)
    expect(settings.allowAutomaticAppDownloads).toEqual(true)
    expect(settings.allowAppClips).toEqual(false)
    expect(settings.allowSystemAppRemoval).toEqual(true)
    expect(settings.allowAssistant).toEqual(false)
    expect(settings.allowGameCenter).toEqual(true)
    expect(settings.forceDelayedSoftwareUpdates).toEqual(true)
    expect(settings.enforcedSoftwareUpdateDelay).toEqual(45)
    expect(settings.forceAutomaticDateAndTime).toEqual(true)

    _ = try await SaveExtendedSupervisionControls.resolve(
      with: .init(deviceId: device.id, controls: .init()), // omitted keys clear to nil
      in: parent.context,
    )

    settings = try await BlockerApp.ProfileSettings.ensure(for: device.id, in: self.db)
    expect(settings.allowSafari).toBeNil()
    expect(settings.ratingTvShows).toBeNil()
    expect(settings.enforcedSoftwareUpdateDelay).toBeNil()
    expect(settings.forceAutomaticDateAndTime).toBeNil()
  }

  func testWriteRejectedWithoutCapability() async throws {
    let parent = try await self.parent() // no billing identity -> free plan
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    try await self.db.create(BlockerApp.Supervision(
      deviceId: device.id,
      supervisedAt: .reference,
    ))

    do {
      _ = try await SaveExtendedSupervisionControls.resolve(
        with: .init(deviceId: device.id, controls: .init(
          whitelistedAppBundleIds: ["com.apple.mobilesafari"],
          webAllowList: nil,
        )),
        in: parent.context,
      )
      XCTFail("expected payment required")
    } catch let error as PqlError {
      expect(error.type).toEqual(.paymentRequired)
    }

    let settings = try await BlockerApp.ProfileSettings.ensure(for: device.id, in: self.db)
    expect(settings.whitelistedAppBundleIds).toBeNil()
  }

  func testWriteRejectedForInvalidNumericControls() async throws {
    let parent = try await self.parent()
    try await self.db.create(BillingIdentity(parentId: parent.id, isComplimentary: true))
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    try await self.db.create(BlockerApp.Supervision(
      deviceId: device.id,
      supervisedAt: .reference,
    ))

    for controls in [
      SaveExtendedSupervisionControls.Controls(ratingMovies: 1),
      SaveExtendedSupervisionControls.Controls(ratingTvShows: 1001),
      SaveExtendedSupervisionControls.Controls(enforcedSoftwareUpdateDelay: 91),
    ] {
      do {
        _ = try await SaveExtendedSupervisionControls.resolve(
          with: .init(deviceId: device.id, controls: controls),
          in: parent.context,
        )
        XCTFail("expected bad request")
      } catch let error as PqlError {
        expect(error.type).toEqual(.badRequest)
      }
    }
  }

  func testWriteRejectedForOtherParentsDevice() async throws {
    let owner = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = owner.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    let other = try await self.parent()
    try await self.db.create(BillingIdentity(parentId: other.id, isComplimentary: true))

    do {
      _ = try await SaveExtendedSupervisionControls.resolve(
        with: .init(deviceId: device.id, controls: .init(
          whitelistedAppBundleIds: nil,
          webAllowList: nil,
        )),
        in: other.context,
      )
      XCTFail("expected unauthorized")
    } catch let error as Abort {
      expect(error.status).toEqual(.unauthorized)
    }
  }
}
